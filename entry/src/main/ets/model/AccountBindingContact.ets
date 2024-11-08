import { AppRelationalStoreManager } from '../common/stores/relationalStore'
import Logger from '../common/utils/Logger'
import { rdbExtractResultRecords } from '../common/utils/DBUtils'
import { CommonConstants } from '../common/constants/CommonConstants'
import { AccountBinding, AccountBindingContact, AccountBindingWithContactId } from '../common/interfaces/AccountBinding'
import { AccountInterface } from '../common/interfaces/Account'
import { dateTimeToDefaultString, isValidateIntId, stringifyError } from '../common/utils/common'
import relationalStore from '@ohos.data.relationalStore'

const LOG_TAG = '[AccountBindingContactListModel]'

class AccountBindingContactListModelCls {
  list: AccountBindingContact[] = []

  async queryAll() {
    let sub = 'AccountBindingContact queryAll() '
    try {
      Logger.info(LOG_TAG, sub)
      let res = await AppRelationalStoreManager.querySql('SELECT * FROM ' + CommonConstants.ACCOUNT_BINDING_CONTACT_TABLE_NAME)
      let items = rdbExtractResultRecords(res, {
        'id': '- INT',
        'accountId': '- INT',
        'bindingId': '- INT',
        'createTime': '- DATETIME',
        'updateTime': '- DATETIME',
      })
      Logger.info(LOG_TAG, sub + 'ok,got ' + items.length + ' items')
      this.list = items
    } catch (e) {
      Logger.error(sub + 'failed, err:' + JSON.stringify(e))
    }

    return this.list
  }

  async add(data: Omit<AccountBindingContact, 'id' | 'updateTime' | 'createTime'>) {
    try {
      Logger.info(LOG_TAG, 'add contact, accountId=' + data.accountId + ' bindingId=' + data.bindingId)
      let values = {
        bindingId: data.bindingId,
        accountId: data.accountId,
        createTime: Date.now(),
        updateTime: Date.now(),
      }
      Logger.debug(LOG_TAG, 'add ' + JSON.stringify(values))

      let rowId = await AppRelationalStoreManager.insert(CommonConstants.ACCOUNT_BINDING_CONTACT_TABLE_NAME, values)
      Logger.info(LOG_TAG, 'add contact ok, accountId=' + data.accountId + ' bindingId=' + data.bindingId
      + 'row id=' + rowId
      )
      Logger.info(LOG_TAG, 'add contact ok, row id=' + rowId)

      let added: AccountBindingContact = {
        ...values,
        id: rowId,
        createTime: dateTimeToDefaultString(values.createTime),
        updateTime: dateTimeToDefaultString(values.updateTime)
      }
      this.list.push(added)
      return added
    } catch (e) {
      Logger.error('add contact failed, err:' + JSON.stringify(e))
      throw e
    }

  }

  async update(contact: Omit<AccountBindingContact, 'updateTime' | 'createTime'>) {
    try {
      Logger.info(LOG_TAG, 'update contact, contact id=' + contact.id + ' bind id=' + contact.bindingId)
      let values = {
        accountId: contact.id,
        bindingId: contact.bindingId,
        updateTime: Date.now()
      }
      let predicate = new relationalStore.RdbPredicates(CommonConstants.ACCOUNT_BINDING_CONTACT_TABLE_NAME)
      predicate.equalTo('id', contact.id)
      let rowId = await AppRelationalStoreManager.update(values, predicate)
      let idx = this.list.findIndex(it => it.id === contact.id)

      Logger.info(LOG_TAG, 'update contact ok, contact id=' + contact.id + ' bind id=' + contact.bindingId)

      if (idx > -1) {
        let original = this.list[idx]
        Object.assign(original, values, {
          updateTime: dateTimeToDefaultString(values.updateTime)
        })

        return original
      }

      throw { msg: 'cannot find original contact after update' }

    } catch (e) {
      Logger.error('update contact failed, err:' + JSON.stringify(e))
      Logger.info(LOG_TAG, 'update contact failed, contact id=' + contact.id
      + ' bind id=' + contact.bindingId + ' err:' + JSON.stringify(e))
    }
  }

  async addOrUpdate(contact: AccountBindingContact) {
    let validate = isValidateIntId(contact.id)
    if (validate) {
      this.update(contact)
    } else {
      let data = { ...contact }
      delete data['id']
      await this.add(contact)
    }
  }

  async delete(id: number) {
    try {
      Logger.info(LOG_TAG, 'delete contact, contact id=' + id)
      await AppRelationalStoreManager.execute('DELETE FROM　'
      + CommonConstants.ACCOUNT_BINDING_CONTACT_TABLE_NAME + ' WHERE id=' + id)

      Logger.info(LOG_TAG, 'delete contact ok, contact id=' + id)
      let idx = this.list.findIndex(it => it.id === id)
      if (idx > -1) {
        this.list.slice(idx, 1)
      }
    } catch (e) {
      Logger.error(LOG_TAG, 'delete contact failed, id=' + id + ' err:' + JSON.stringify(e))
    }
  }

  async deleteByBindingId(bindingId: number) {
    try {
      Logger.info(LOG_TAG, 'delete contact by bindingId, contact bindingId=' + bindingId)
      await AppRelationalStoreManager.execute('DELETE FROM　' + CommonConstants.ACCOUNT_BINDING_CONTACT_TABLE_NAME + ' WHERE bindingId=' + bindingId)
      Logger.info(LOG_TAG, 'delete contact by bindingId ok, contact bindingId=' + bindingId)

      this.list = this.list.filter(it => it.bindingId === bindingId)
    } catch (e) {
      Logger.error(LOG_TAG, 'delete contact by bindingId failed, contact bindingId=' + bindingId + ' err:' + JSON.stringify(e))

    }
  }

  async deleteByAccountId(accountId: number) {
    try {
      Logger.info(LOG_TAG, 'delete contact by accountId, contact accountId=' + accountId)
      await AppRelationalStoreManager.execute(
        'DELETE FROM　' + CommonConstants.ACCOUNT_BINDING_CONTACT_TABLE_NAME + ' WHERE accountId=' + accountId
      )
      Logger.info(LOG_TAG, 'delete contact by accountId ok, contact accountId=' + accountId)

      this.list = this.list.filter(it => it.accountId === accountId)
    } catch (e) {
      Logger.error(LOG_TAG, 'delete contact by accountId failed, contact accountId=' + accountId + ' err:' + JSON.stringify(e))

    }
  }

  async contact(accounts: AccountInterface[], bindings: AccountBinding[], contacts: AccountBindingContact[]) {
    const accountMap = new Map(accounts.map(ac => ([ac.id, ac])))
    const bindingMap = new Map(bindings.map(b => ([b.id, b])))

    accounts.forEach(ac => {
      if (!ac.bindings) {
        ac.bindings = []
      }
      if (ac.bindings.length) {
        Logger.warn(LOG_TAG, 'account bindings is not empty before contact, id=' + ac.id)
        ac.bindings = []
      }
    })

    contacts.forEach(c => {
      let failedErr = ''
      let account = accountMap.get(c.accountId)
      if (!account) {
        failedErr = 'not found account by id=' + c.accountId
      }
      let binding = bindingMap.get(c.bindingId)
      if (!bindings) {
        failedErr = 'not found account binding by id=' + c.bindingId
      }

      if (account && binding) {
        account.bindings.push({
          ...binding,
          contactId: c.id
        })
      }
      if (failedErr) {
        Logger.error(LOG_TAG, 'contact account binding failed, cause ' + failedErr)
      }
    })
  }

  async updateAccountContacts(account: AccountInterface, origins: AccountBindingWithContactId[], updated: AccountBindingWithContactId[]) {
    Logger.error(LOG_TAG, 'update  bindings not imp when update account')
    // let newAdd:  = []
  }

  hasBinding(bindingId: number) {
    return this.list.findIndex(it => it.bindingId === bindingId) > -1
  }

  async resetDataBaseData() {
    let sub = 'AccountContact resetDataBaseData() '

    try {
      await AppRelationalStoreManager.execute('DELETE FROM ' + CommonConstants.ACCOUNT_BINDING_CONTACT_TABLE_NAME)
      this.list = []
    } catch (e) {
      Logger.error(LOG_TAG, sub + 'failed,' + stringifyError(e))
    }
  }
}

export const AccountBindingContactListModel = new AccountBindingContactListModelCls()