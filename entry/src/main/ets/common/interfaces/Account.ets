import { AccountBindingWithContactId } from './AccountBinding';
import { AccountGroup } from './AccountGroup';

export interface AccountInterface {
  name: string
  pwd: string
  account: string
  note?: string
  bindings: AccountBindingWithContactId[]
  id: number
  updateTime: string
  createTime: string
  groupId: number
  group?: AccountGroup
  userName: string
  nickName: string
}


// export  interface  AccountData extends AccountInterface {
//   id: number
//   updateTime: string
//   createTime: string
// }