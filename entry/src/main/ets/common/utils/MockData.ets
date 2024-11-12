import { AccountBindingType } from '../enums/account'
import { AccountInterface } from '../interfaces/Account'
import { AccountBinding } from '../interfaces/AccountBinding'

export function mockBindingList(): AccountBinding[] {
  return [
    {
      id: 1,
      bind: '12345678',
      type: AccountBindingType.Phone,
      createTime: '',
      updateTime: ''
    },
    {
      id: 2,
      bind: '123666666',
      type: AccountBindingType.Phone,
      createTime: '',
      updateTime: ''
    },
    {
      id: 3,
      type: AccountBindingType.Email,
      bind: 'abc@test.com',
      createTime: '',
      updateTime: ''
    }
  ]
}

export function mockAccountList(): AccountInterface[] {
  return [
    {
      pwd: '123',
      account: 'zhangshan',
      name: '163',
      bindings: [{
        type: AccountBindingType.Phone,
        bind: '17722223333',
        createTime: '',
        updateTime: '',
        id: 0,
        contactId: -1,

      }],
      createTime: '',
      updateTime: '',
      nickName: '',
      userName: '',
      groupId: 0,
      id: 1,
    },
    {
      pwd: '333',
      account: '唐僧爱洗头',
      name: '大话西游',
      bindings: [{
        type: AccountBindingType.Email,
        bind: 'test@abc.com',
        createTime: '',
        updateTime: '',
        id: 0,
        contactId: -1,
      }],
      createTime: '',
      updateTime: '',
      nickName: '',
      userName: '',
      groupId: 0,
      id: 2,
    },
    {
      pwd: 'sf.Fs333',
      account: 'gss',
      name: 'ABC',
      bindings: [{
        type: AccountBindingType.Email,
        bind: 'helloworld@word.com',
        createTime: '',
        updateTime: '',
        id: 0,
        contactId: -1,
      }],
      createTime: '',
      updateTime: '',
      nickName: '',
      userName: '',
      groupId: 0,
      id: 3,
    },
    {
      pwd: '333',
      account: 'gss',
      name: 'ABC',
      bindings: [{
        type: AccountBindingType.Phone,
        bind: '177',
        createTime: '',
        updateTime: '',
        id: 0,
        contactId: -1,
      }],
      createTime: '',
      updateTime: '',
      id: 4,
      nickName: '',
      userName: '',
      groupId: 0,
    },
    {
      pwd: '333',
      account: 'gss',
      name: 'ABC',
      bindings: [{
        type: AccountBindingType.Phone,
        bind: '177',
        createTime: '',
        updateTime: '',
        id: 0,
        contactId: -1,
      }],
      createTime: '',
      updateTime: '',
      id: 5,
      nickName: '',
      userName: '',
      groupId: 0,
    },
  ]
}

export function useMockData(): boolean {
  return false
}