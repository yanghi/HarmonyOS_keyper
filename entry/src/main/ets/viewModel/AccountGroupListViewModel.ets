import { DEFAULT_GROUP } from '../common/constants/CommonConstants'
import { AccountInterface } from '../common/interfaces/Account'
import { AccountGroup } from '../common/interfaces/AccountGroup'
import logger from '../common/utils/Logger'
import { AccountGroupListModel } from '../model/AccountGroup'
import { AccountViewModel } from './AccountViewModel'

export interface GroupedViewModelList {
  list: AccountViewModel[]
  group: AccountGroup
}

const DEFAULT_GROUP_ID = DEFAULT_GROUP.id
const TAG = '[AccountGroupListViewModel]'

@Observed
export class AccountGroupListViewModel {
  list: GroupedViewModelList[] = []

  groupViewModel(list: AccountInterface[]) {
    let groupMap = new Map<number, GroupedViewModelList>()
    // default group
    groupMap.set(DEFAULT_GROUP_ID, {
      list: [],
      group: {
        id: DEFAULT_GROUP_ID,
        name: '默认分组',
        createTime: '',
        updateTime: ''
      }
    })

    list.forEach(item => {
      if (!item.groupId) {
        groupMap.get(DEFAULT_GROUP_ID).list.push(new AccountViewModel(item))
        return
      }

      if (groupMap.has(item.groupId)) {
        groupMap.get(item.groupId).list.push(new AccountViewModel(item))
      } else {
        let group = item.group || AccountGroupListModel.list.find(g => g.id === item.groupId)

        if (!group) {
          logger.error(TAG, 'cannot find group, account id=' + item.id + '  group id=' + item.groupId)
          return
        }
        groupMap.set(item.groupId, {
          group,
          list: [new AccountViewModel(item)]
        })
      }
    })

    this.list = Array.from(groupMap).map(([_, gl]) => gl)

    return this.list
  }
}