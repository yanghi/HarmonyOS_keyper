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
import { mockAccountList, useMockData } from '../common/utils/MockData'
import { AccountGroupListModel } from './AccountGroup'

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
      groupId: 0,
      nickName: '',
      userName: ''
    }
  }

  static shim(acc: AccountInterface) {
    if (!acc.bindings) {
      acc.bindings = []
    }
  }
}


const ACCOUNT_CRYPT_KEYS: Array<keyof AccountInterface> = ['account', 'name', 'pwd', 'note', 'nickName', 'userName']

export class AccountListModelCls {
  list: AccountInterface[] = []

  constructor() {
    //   mocks
    if (useMockData()) {
      this.list = mockAccountList()
      this.deletedList = mockAccountList()
    }

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
      let groupPromise = AccountGroupListModel.queryAll()
      let resSet = await AppRelationalStoreManager.querySql(
        "SELECT * FROM " + CommonConstants.ACCOUNT_TABLE_NAME + ' WHERE isDel=' + isDel
      )
      let items = rdbExtractResultRecords(resSet, {
        'id': '- INT',
        'groupId': '- INT',
        'createTime': '- DATETIME',
        'updateTime': '- DATETIME',
        'pwd': '- VARCHAR',
        'note': '- VARCHAR',
        'account': '- VARCHAR',
        'name': '- VARCHAR',
        'nickName': '- VARCHAR',
        'userName': '- VARCHAR',
      })
      Logger.info(LOG_TAG, sub + `ok, got ${items.length} items)`)

      let bindings = await bindingPromise
      let bindingContacts = await bindingContactPromise
      await groupPromise
      AccountBindingContactListModel.contact(items, bindings, bindingContacts)

      for (let item of items) {
        AccountGroupListModel.concatGroup(item)
        await this.decryptAccount(item)
      }

      return items

    } catch (e) {
      Logger.error(LOG_TAG, sub + ' failed, err:' + JSON.stringify(e))
      throw e
    }
  }

  async add(ac: AccountInterface) {
    try {
      AccountModel.shim(ac)
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
      Logger.error(LOG_TAG, "add account failed, err:" + stringifyError(e))
      throw e
    }
  }

  async update(account: AccountInterface, bindingContactActions: BindingContactAction[]) {
    try {
      Logger.info(LOG_TAG, 'update id=' + account.id)
      let originIdx = this.list.findIndex(it => it.id === account.id)
      if (originIdx == -1) {
        Logger.error('cannot find target account by id=' + account.id)
        throw new Error('cannot find target account by id=' + account.id)
      }

      let values = {
        ...account,
        updateTime: Date.now(),
      }
      delete values['createTime']
      delete values['bindings']

      let updated = {
        ...values,
        createTime: account.createTime,
        updateTime: dateTimeToDefaultString(values.updateTime),
      }
      Logger.info(LOG_TAG, 'values ' + JSON.stringify(values))
      let predicate = new relationalStore.RdbPredicates(CommonConstants.ACCOUNT_TABLE_NAME)
      predicate.equalTo('id', account.id)

      let rowId = await AppRelationalStoreManager.update(values as any, predicate)

      let newBindings: AccountBindingWithContactId[] = []

      let upsertPromises: Promise<any>[] = []
      // Logger.debug(LOG_TAG, 'bind ' + JSON.stringify(bindingContactActions))

      bindingContactActions.forEach(act => {
        if (act.action === 'add') {
          newBindings.push(act.data)
          upsertPromises.push(AccountBindingContactListModel.add({
            accountId: account.id,
            bindingId: act.data.id,

          }).then(add => {
            act.data.contactId = add.id
            act.data.createTime = add.createTime
            act.data.updateTime = add.createTime
          }))
        } else if (act.action == 'delete') {
          upsertPromises.push(AccountBindingContactListModel.delete(act.data.contactId))
        } else if (act.action == 'update') {
          upsertPromises.push(AccountBindingContactListModel.update({
            id: act.data.contactId,
            bindingId: act.data.id,
            accountId: account.id,
          }))
          newBindings.push(act.data)
        }
      })

      if (upsertPromises.length) {
        Logger.info(LOG_TAG, 'upsert account bindings, account id=' + account.id)
        await Promise.all(upsertPromises)
        Logger.info(LOG_TAG, 'upsert account bindings ok, account id=' + account.id)
      }

      updated.bindings = newBindings

      this.list[originIdx] = updated
      Logger.info(LOG_TAG, 'update ok, rowId=' + rowId)

      emitter.emit({ eventId: EventId.AccountListUpdate }, { data: { list: this.list } })
    } catch (e) {
      Logger.error(LOG_TAG, 'account update failed, id=' + account.id + ', err:' + JSON.stringify(e))
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
      emitter.emit({ eventId: EventId.AccountDeletedListUpdate }, { data: { list: this.deletedList } })
    } catch (e) {
      Logger.error(LOG_TAG, sub + 'failed,' + stringifyError(e))
      throw e
    }
  }

  async resetDataBaseData() {
    let sub = 'Account resetDataBaseData() '

    try {
      await AppRelationalStoreManager.execute('DELETE FROM ' + CommonConstants.ACCOUNT_TABLE_NAME)
      this.list = []
      this.deletedList = []
      emitter.emit({ eventId: EventId.AccountDeletedListUpdate }, { data: { list: this.deletedList } })
      emitter.emit({ eventId: EventId.AccountListUpdate }, { data: { list: this.list } })

    } catch (e) {
      Logger.error(LOG_TAG, sub + 'failed,' + stringifyError(e))

    }
  }
}

export interface BindingContactAction {
  data: AccountBindingWithContactId,
  action: 'add' | 'delete' | 'remain' | 'update'
}

export const AccountListModel = new AccountListModelCls()
