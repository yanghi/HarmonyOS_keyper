import { AccountBindingType } from '../enums/account';

export interface AccountBinding {
  id: number
  updateTime: string
  createTime: string
  type: AccountBindingType
  bind: string
}

export interface AccountBindingWithContactId extends AccountBinding {
  contactId: number
}

export interface AccountBindingContact {
  id: number
  updateTime: string
  createTime: string
  accountId: number
  bindingId: number
}