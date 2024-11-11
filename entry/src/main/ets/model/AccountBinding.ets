import { CommonConstants } from '../common/constants/CommonConstants'
import { AccountBindingType } from '../common/enums/account'
import { AccountBinding, AccountBindingWithContactId } from '../common/interfaces/AccountBinding'
import { AppRelationalStoreManager } from '../common/stores/relationalStore'
import Logger from '../common/utils/Logger'
import { rdbExtractResultRecords } from '../common/utils/DBUtils'
import { dateTimeToDefaultString, stringifyError } from '../common/utils/common'
import emitter from '@ohos.events.emitter'
import { EventId } from '../common/enums/Event'
import { AccountBindingContactListModel } from './AccountBindingContact'
import { cipherModel } from './Cipher'
import { mockBindingList, useMockData } from '../common/utils/MockData'
import relationalStore from '@ohos.data.relationalStore'

const LOG_TAG = '[AccountBindingModel]'

export class AccountBindingModel {
  static emptyData(): AccountBinding {
    return {
      type: AccountBindingType.Phone,
      bind: '',
      createTime: '',
      updateTime: '',
      id: 0
    }
  }
}

export const bindingOptions = Array.from(CommonConstants.LabelMapAccountBindingType.entries())
  .map(v => ({ value: v[0] }))

const ACCOUNT_BINDING_CRYPT_KEYS: Array<keyof AccountBinding> = ['bind']

export class AccountBindingListModelCls {
  list: AccountBinding[] = []
  private typeGroup: Map<AccountBindingType, AccountBinding[]> = new Map()

  constructor() {
    if (useMockData()) {
      this.list = mockBindingList()
    }
  }

  getTypeGroup() {
    return this.typeGroup
  }

  private updateTypeGroup() {
    this.typeGroup = new Map()
    this.list.forEach((ab => {
      let group = this.typeGroup.get(ab.type)
      if (!group) {
        group = []
        this.typeGroup.set(ab.type, group)
      }

      group.push(ab)
    }))
  }

  private async decrypt(binding: AccountBinding): Promise<AccountBinding> {
    return await cipherModel.aesDecryptProperties(binding, ACCOUNT_BINDING_CRYPT_KEYS)
  }

  private encrypt(binding: AccountBinding): Promise<AccountBinding> {
    return cipherModel.aesEncryptProperties(binding, ACCOUNT_BINDING_CRYPT_KEYS)
  }

  async queryAll() {
    try {
      let store = await AppRelationalStoreManager.getRdbStore()
      let queryRes = await store.querySql('SELECT * FROM ' + CommonConstants.ACCOUNT_BINDING_TABLE_NAME)

      let items = rdbExtractResultRecords(queryRes, {
        'id': '- INT',
        'bind': '- VARCHAR',
        'type': '- INT',
        'createTime': '- DATETIME',
        'updateTime': '- DATETIME',
      })
      for (let item of items) {
        await this.decrypt(item)
      }

      this.list = items
      this.updateTypeGroup()

      Logger.info(LOG_TAG, 'queryAll ok, got ' + items.length + ' items')
      emitter.emit({ eventId: EventId.AccountBindingListUpdate }, { data: { list: this.list } })
    } catch (e) {
      Logger.error(LOG_TAG, 'queryAll account binding count failed ', JSON.stringify(e))
    }

    return this.list
  }

  private emitUpdateList() {
    this.updateTypeGroup()
    emitter.emit({ eventId: EventId.AccountBindingListUpdate }, { data: { list: this.list } })

  }

  async add(ab: Omit<AccountBinding, 'id' | 'updateTime' | 'createTime'>) {
    try {
      let addProps = {
        type: ab.type,
        bind: ab.bind,
        updateTime: Date.now(),
        createTime: Date.now()
      }
      let rowId = await AppRelationalStoreManager.insert(CommonConstants.ACCOUNT_BINDING_TABLE_NAME, await this.encrypt({
        ...addProps as any
      }))
      Logger.infoF('%{public}s add account binding ok id=%{public}s,type=%{public}s,bind=%{public}s', LOG_TAG, rowId, ab.type + '', ab.bind)
      let newAdd: AccountBinding = {
        ...addProps,
        id: rowId,
        updateTime: dateTimeToDefaultString(addProps.updateTime),
        createTime: dateTimeToDefaultString(addProps.createTime),
      }

      this.list.unshift(newAdd)
      this.updateTypeGroup()
      emitter.emit({ eventId: EventId.AccountBindingListUpdate }, { data: { list: this.list } })

      Logger.info(LOG_TAG, "push new add binding " + JSON.stringify(newAdd))

      return newAdd
    } catch (e) {
      Logger.info(LOG_TAG, "add binding failed," + stringifyError(e))
      throw e
    }

  }

  async delete(id: number) {
    try {
      Logger.info(LOG_TAG, "delete binding, id=" + id)
      await AppRelationalStoreManager.execute('DELETE FROM ' + CommonConstants.ACCOUNT_BINDING_TABLE_NAME + ' WHERE id=' + id)

      Logger.info(LOG_TAG, "delete binding ok, id=" + id)
      this.list = this.list.filter(ac => ac.id != id)

      this.emitUpdateList()
      return true
    } catch (e) {
      Logger.info(LOG_TAG, "delete binding failed, id=" + id + ' err:' + JSON.stringify(e))
      return false
    }
  }

  async update(binding: AccountBinding) {
    let sub = `binding update(id=${binding.id}) `
    try {
      Logger.info(LOG_TAG, sub)
      let originIdx = this.list.findIndex(it => it.id === binding.id)
      if (originIdx == -1) {
        Logger.error('cannot find target binding by id=' + binding.id)
        throw new Error('cannot find target binding by id=' + binding.id)
      }

      let values = {
        bind: binding.bind,
        updateTime: Date.now(),
      }
      delete values['createTime']

      let updated = {
        ...values,
        ...binding,
        createTime: binding.createTime,
        updateTime: dateTimeToDefaultString(values.updateTime),
      }
      let predicate = new relationalStore.RdbPredicates(CommonConstants.ACCOUNT_BINDING_TABLE_NAME)
      predicate.equalTo('id', binding.id)
      let rowId = await AppRelationalStoreManager.update(values as any, predicate)

      this.list[originIdx] = updated
      this.emitUpdateList()
      Logger.info(LOG_TAG, sub + 'ok, rowId=' + rowId)
    } catch (e) {
      Logger.error(LOG_TAG, sub + 'failed,' + stringifyError(e))

      throw e
    }

  }

  hasBindingAccount(bindingId: number) {
    return AccountBindingContactListModel.hasBinding(bindingId)
  }

  async resetDataBaseData() {
    let sub = 'Account binding resetDataBaseData() '

    try {
      await AppRelationalStoreManager.execute('DELETE FROM ' + CommonConstants.ACCOUNT_BINDING_TABLE_NAME)
      this.list = []
      emitter.emit({ eventId: EventId.AccountBindingListUpdate }, { data: { list: this.list } })
    } catch (e) {
      Logger.error(LOG_TAG, sub + 'failed,' + stringifyError(e))

    }
  }
}

export const AccountBindingListModel = new AccountBindingListModelCls()