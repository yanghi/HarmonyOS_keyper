import { CommonConstants, DEFAULT_GROUP } from '../common/constants/CommonConstants'
import { AccountInterface } from '../common/interfaces/Account'
import { AccountGroup } from '../common/interfaces/AccountGroup'
import { AppRelationalStoreManager } from '../common/stores/relationalStore'
import { dateTimeToDefaultString, isValidateIntId, stringifyError } from '../common/utils/common'
import { rdbExtractResultRecords } from '../common/utils/DBUtils'
import logger from '../common/utils/Logger'
import relationalStore from '@ohos.data.relationalStore'
import emitter from '@ohos.events.emitter'
import { EventId } from '../common/enums/Event'

const TAG = '[AccountGroupListModel]'

@Observed
export class AccountGroupListModelCls {
  list: AccountGroup[] = []
  selectOptions: (SelectOption & {
    id: number,
    group: AccountGroup
  })[] = []

  private updateList() {
    this.selectOptions = [DEFAULT_GROUP].concat(this.list).map(it => ({
      value: it.name,
      id: it.id,
      group: it
    }))
    this.emitListUpdate()
  }

  private emitListUpdate() {
    emitter.emit({ eventId: EventId.AccountGroupListUpdate }, { data: { list: this.list } })
  }

  async queryAll() {
    let sub = 'AccountGroup queryAll() '
    try {
      logger.info(TAG, sub)
      let resSet = await AppRelationalStoreManager.querySql(
        "SELECT * FROM " + CommonConstants.ACCOUNT_GROUP_TABLE_NAME
      )
      let items = rdbExtractResultRecords(resSet, {
        'id': '- INT',
        'createTime': '- DATETIME',
        'updateTime': '- DATETIME',
        'name': '- VARCHAR',
      })

      this.list = items
      this.updateList()
      logger.info(TAG, sub + 'ok, got ' + items.length + ' items')

    } catch (e) {
      logger.error(TAG, sub + 'failed,' + stringifyError(e))
      throw e
    }
  }

  async add(data: Pick<AccountGroup, 'name'>) {
    let sub = 'AccountGroup add() '

    try {
      logger.info(TAG, sub)
      let addValues = {
        ...data,
        updateTime: Date.now(),
        createTime: Date.now()
      }
      delete addValues['id']
      let rowId = await AppRelationalStoreManager.insert(
        CommonConstants.ACCOUNT_GROUP_TABLE_NAME,
        addValues
      )
      let newAdd: AccountGroup = {
        ...addValues,
        id: rowId,
        createTime: dateTimeToDefaultString(addValues.createTime),
        updateTime: dateTimeToDefaultString(addValues.updateTime),
      }

      this.list.push(newAdd)
      this.updateList()

      return newAdd
    } catch (e) {
      logger.error(TAG, sub + 'failed,' + stringifyError(e))
      throw e
    }
  }

  async delete(id: number) {
    let sub = `AccountGroup delete(id=${id}) `
    try {
      logger.info(TAG, sub)
      let originIdx = this.list.findIndex(it => it.id === id)
      if (originIdx == -1) {
        logger.error('cannot find target group by id=' + id)
        throw new Error('cannot find target group by id=' + id)
      }
      await AppRelationalStoreManager.execute(
        'DELETE FROM ' + CommonConstants.ACCOUNT_GROUP_TABLE_NAME + ' WHERE id=' + id
      )
      this.list.splice(originIdx, 1)
      logger.error(TAG, sub + 'ok')
      this.updateList()

    } catch (e) {
      logger.error(TAG, sub + 'failed,' + stringifyError(e))
      throw e
    }
  }

  async update(data: AccountGroup) {
    let sub = 'AccountGroup update() '
    try {
      logger.info(TAG, sub)
      let originIdx = this.list.findIndex(it => it.id === data.id)
      if (originIdx == -1) {
        logger.error('cannot find target group by id=' + data.id)
        throw new Error('cannot find target group by id=' + data.id)
      }
      let values = {
        ...data,
        updateTime: Date.now(),
      }
      delete values['createTime']
      delete values['bindings']

      let predicate = new relationalStore.RdbPredicates(CommonConstants.ACCOUNT_GROUP_TABLE_NAME)
      predicate.equalTo('id', data.id)
      predicate
      let rowId = await AppRelationalStoreManager.update(values as any, predicate)

      let updated = {
        ...values,
        createTime: data.createTime,
        updateTime: dateTimeToDefaultString(values.updateTime),
      }

      this.list[originIdx] = updated
      this.updateList()

      return updated
    } catch (e) {
      logger.error(TAG, sub + 'failed,' + stringifyError(e))
      throw e
    }
  }

  concatGroup(acc: AccountInterface) {
    if (!isValidateIntId(acc.groupId) || acc.groupId == DEFAULT_GROUP.id) {
      return
    }
    let target = this.list.find(it => it.id === acc.groupId)

    if (!target) {
      logger.error(TAG, 'cannot find group by groupId=' + acc.groupId + ' account id=' + acc.id)
      return
    }

    acc.group = target
  }
}


export const AccountGroupListModel = new AccountGroupListModelCls()