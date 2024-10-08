import { AccountBindingWithContactId } from './AccountBinding';

export interface AccountInterface {
  name: string
  pwd: string
  account: string
  note?: string
  bindings: AccountBindingWithContactId[]
  id: number
  updateTime: string
  createTime: string
}


// export  interface  AccountData extends AccountInterface {
//   id: number
//   updateTime: string
//   createTime: string
// }