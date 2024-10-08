import { AccountBindingType } from '../common/enums/account'
import { AccountInterface } from '../common/interfaces/Account'
import { AppRelationalStoreManager } from '../common/stores/relationalStore'
import Logger from '../common/utils/Logger'
import { rdbExtractResultRecords } from '../common/utils/DBUtils'
import { CommonConstants } from '../common/constants/CommonConstants'
import { AccountBindingListModel } from './AccountBinding'
import { AccountBindingContactListModel } from './AccountBindingContact'
import { dateTimeToDefaultString, isValidateIntId, stringifyError } from '../common/utils/common'
import emitter from '@ohos.events.emitter'
import { EventId } from '../common/enums/Event'
import relationalStore from '@ohos.data.relationalStore'
import { AccountBindingWithContactId } from '../common/interfaces/AccountBinding'
import { cipherModel } from './Cipher'
import { mockAccountList } from '../common/utils/MockData'

const LOG_TAG = '[AccountModel]'

export class AccountModel {
  static emptyData(): AccountInterface {
    return {
      pwd: '',
      name: '',
      account: '',
      bindings: [],
      createTime: '',
      updateTime: '',
      id: -1,
      note: '',
    }
  }
}


const ACCOUNT_CRYPT_KEYS: Array<keyof AccountInterface> = ['account', 'name', 'pwd', 'note']

export class AccountListModelCls {
  list: AccountInterface[] = []

  constructor() {
    //   mocks
    this.list = mockAccountList()
    this.deletedList = mockAccountList()
  }

  private async decryptAccount(acc: AccountInterface): Promise<AccountInterface> {
    return await cipherModel.aesDecryptProperties(acc, ACCOUNT_CRYPT_KEYS)
  }

  private encryptAccount(acc: AccountInterface): Promise<AccountInterface> {
    return cipherModel.aesEncryptProperties(acc, ACCOUNT_CRYPT_KEYS).catch(() => {
      let errMsg = 'cipherModel.encryptAccount err'
      throw { msg: errMsg }
    })
  }

  queryAll() {
    return this._queryAll(0).then((items) => {
      this.list = items
      emitter.emit({ eventId: EventId.AccountListUpdate }, { data: { list: this.list } })
    })
  }

  private async _queryAll(isDel: 0 | 1) {
    let sub = `Account queryAll(isDel=${isDel}) `
    try {
      Logger.info(LOG_TAG, sub)
      let bindingPromise = AccountBindingListModel.queryAll()
      let bindingContactPromise = AccountBindingContactListModel.queryAll()
      let resSet = await AppRelationalStoreManager.querySql("SELECT * FROM " + CommonConstants.ACCOUNT_TABLE_NAME + ' WHERE isDel=' + isDel)
      let items = rdbExtractResultRecords(resSet, {
        'id': '- INT',
        'createTime': '- DATETIME',
        'updateTime': '- DATETIME',
        'pwd': '- VARCHAR',
        'note': '- VARCHAR',
        'account': '- VARCHAR',
        'name': '- VARCHAR',
      })
      Logger.info(LOG_TAG, sub + `ok, got ${items.length} items)`)

      let bindings = await bindingPromise
      let bindingContacts = await bindingContactPromise

      AccountBindingContactListModel.contact(items, bindings, bindingContacts)
      for (let item of items) {
        await this.decryptAccount(item)
      }

      return items

    } catch (e) {
      Logger.error(LOG_TAG, sub + ' failed, err:' + JSON.stringify(e))
    }

  }

  async add(ac: AccountInterface) {
    try {
      Logger.info(LOG_TAG, "add account ")
      let addValues = {
        ...ac,
        updateTime: Date.now(),
        createTime: Date.now()
      }
      delete addValues['id']
      delete addValues['bindings']

      let rowId = await AppRelationalStoreManager.insert(
        CommonConstants.ACCOUNT_TABLE_NAME,
        await this.encryptAccount({ ...addValues as any })
      )
      let bindings = ac.bindings.filter(b => isValidateIntId(b.id))

      Logger.debug(LOG_TAG, 'add account bindings: ' + JSON.stringify(bindings))
      if (bindings) {
        Logger.info(LOG_TAG, 'account bindings contact')
        await Promise.all(bindings.map(b => AccountBindingContactListModel.add({
          accountId: ac.id,
          bindingId: b.id,
        }).then(added => {
          b.contactId = added.id
          Logger.info(LOG_TAG, 'update binding, contact id=' + added.accountId)
        })))
      }

      let newAdd: AccountInterface = {
        bindings,
        ...addValues,
        id: rowId,
        createTime: dateTimeToDefaultString(addValues.createTime),
        updateTime: dateTimeToDefaultString(addValues.updateTime),
      }

      this.list.unshift(newAdd)
      Logger.info(LOG_TAG, "add account ok, row id: " + rowId + ' ' + JSON.stringify(newAdd))
      emitter.emit({ eventId: EventId.AccountListUpdate }, { data: { list: this.list, type: 'add', add: newAdd } })

      return newAdd
    } catch (e) {
      Logger.error(LOG_TAG, "add account failed, err:" + JSON.stringify(e))
      throw e
    }
  }

  async update(ac: AccountInterface, bindingsActions: BindingContactAction[]) {
    try {
      Logger.info(LOG_TAG, 'update id=' + ac.id)
      let originIdx = this.list.findIndex(it => it.id === ac.id)
      if (originIdx == -1) {
        Logger.error('cannot find target account by id=' + ac.id)
        throw new Error('cannot find target account by id=' + ac.id)
      }

      let values = {
        ...ac,
        updateTime: Date.now(),
      }
      delete values['createTime']
      delete values['bindings']

      let updated = {
        ...values,
        createTime: ac.createTime,
        updateTime: dateTimeToDefaultString(values.updateTime),
      }
      Logger.info(LOG_TAG, 'values ' + JSON.stringify(values))
      let predicate = new relationalStore.RdbPredicates(CommonConstants.ACCOUNT_TABLE_NAME)
      predicate.equalTo('id', ac.id)

      let rowId = await AppRelationalStoreManager.update(values as any, predicate)

      let newBindings: AccountBindingWithContactId[] = []

      let upsertPromises: Promise<any>[] = []
      bindingsActions.forEach(act => {
        if (act.action === 'add') {
          newBindings.push(act.data)
          upsertPromises.push(AccountBindingContactListModel.add(act.data as any).then(add => {
            act.data.contactId = add.id
            act.data.createTime = add.createTime
            act.data.updateTime = add.createTime
          }))
        } else if (act.action == 'delete') {
          upsertPromises.push(AccountBindingContactListModel.delete(act.data.id))
        } else if (act.action == 'update') {
          upsertPromises.push(AccountBindingContactListModel.update({
            id: act.data.contactId,
            bindingId: act.data.id,
            accountId: act.data.contactId,
          }))
          newBindings.push(act.data)
        }
      })

      if (upsertPromises.length) {
        Logger.info(LOG_TAG, 'upsert account bindings, account id=' + ac.id)
        await Promise.all(upsertPromises)
        Logger.info(LOG_TAG, 'upsert account bindings ok, account id=' + ac.id)
      }

      updated.bindings = newBindings

      this.list[originIdx] = updated
      Logger.info(LOG_TAG, 'update ok, rowId=' + rowId)

      emitter.emit({ eventId: EventId.AccountListUpdate }, { data: { list: this.list } })
    } catch (e) {
      Logger.error(LOG_TAG, 'account update failed, id=' + ac.id + ', err:' + JSON.stringify(e))
      throw e
    }
  }

  async delete(id: number) {
    try {
      let target = this.list.find(ac => ac.id === id)
      if (!target) {
        throw 'not found target account id=' + id

      }
      Logger.info(LOG_TAG, "logic delete id=" + id)
      await AppRelationalStoreManager.execute('UPDATE ' + CommonConstants.ACCOUNT_TABLE_NAME + ' SET isDel=1 WHERE id=' + id)
      Logger.info(LOG_TAG, "logic delete id=" + id + 'ok')

      this.list = this.list.filter(ac => ac.id != id)
      this.deletedList = this.deletedList.concat(target)

      emitter.emit({ eventId: EventId.AccountListUpdate }, { data: { list: this.list } })
      emitter.emit({ eventId: EventId.AccountDeletedListUpdate }, { data: { list: this.deletedList } })
    } catch (e) {
      Logger.error(LOG_TAG, "logic delete id=" + id + ' failed, err:' + JSON.stringify(e))
      throw e
    }
  }

  deletedList: AccountInterface[] = []

  queryAllDeleted() {
    return this._queryAll(1).then(items => {
      this.deletedList = items
      emitter.emit({ eventId: EventId.AccountDeletedListUpdate }, { data: { list: this.deletedList } })
    })
  }

  async restore(id: number) {
    try {
      let target = this.deletedList.find(ac => ac.id === id)
      if (!target) {
        throw 'not found target account id=' + id

      }
      Logger.info(LOG_TAG, "restore account id=" + id)
      await AppRelationalStoreManager.execute('UPDATE ' + CommonConstants.ACCOUNT_TABLE_NAME + ' SET isDel=0 WHERE id=' + id)
      Logger.info(LOG_TAG, "restore account id=" + id + 'ok')

      this.deletedList = this.deletedList.filter(a => a.id != id)
      this.list = this.list.concat(target)
      emitter.emit({ eventId: EventId.AccountListUpdate }, { data: { list: this.list } })
      emitter.emit({ eventId: EventId.AccountDeletedListUpdate }, { data: { list: this.deletedList } })
    } catch (e) {
      Logger.error(LOG_TAG, "restore account id=" + id + 'failed, err:' + JSON.stringify(e))
      throw e
    }
  }

  async hardDelete(id: number) {
    try {
      let target = this.deletedList.find(ac => ac.id === id)
      if (!target) {
        throw 'not found target account id=' + id

      }
      Logger.info(LOG_TAG, "hard delete account id=" + id)
      await AppRelationalStoreManager.execute('DELETE FROM ' + CommonConstants.ACCOUNT_TABLE_NAME
      + ' WHERE id=' + id + ' and isDel=1;')
      Logger.info(LOG_TAG, "hard delete account id=" + id + 'ok')

      this.deletedList = this.deletedList.filter(a => a.id != id)
      this.list = this.list.concat(target)
      emitter.emit({ eventId: EventId.AccountDeletedListUpdate }, { data: { list: this.deletedList } })
    } catch (e) {
      Logger.error(LOG_TAG, "hard delete account id=" + id + 'failed, err:' + stringifyError(e))
      throw e
    }
  }

  async hardDeleteAll() {
    let sub = 'Account hardDeleteAll() '

    try {
      Logger.info(LOG_TAG, sub)
      await AppRelationalStoreManager.execute('DELETE FROM ' + CommonConstants.ACCOUNT_TABLE_NAME + ' WHERE isDel=1')
      Logger.info(LOG_TAG, sub + 'ok')

      this.deletedList = []
      emitter.emit({ eventId: EventId.AccountBindingListUpdate }, { data: { list: this.deletedList } })
    } catch (e) {
      Logger.error(LOG_TAG, sub + 'failed,' + stringifyError(e))
      throw e
    }
  }
}

export interface BindingContactAction {
  data: AccountBindingWithContactId,
  action: 'add' | 'delete' | 'remain' | 'update'
}

export const AccountListModel = new AccountListModelCls()
