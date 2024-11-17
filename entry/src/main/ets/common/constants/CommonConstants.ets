import { AccountBindingType } from '../enums/account'
import { AccountGroup } from '../interfaces/AccountGroup'

export namespace CommonConstants {
  export const True = 1

  export const False = 0

  export const ACCOUNT_TABLE_NAME = 'account'

  export const SQL_CREATE_ACCOUNT_TABLE = `CREATE TABLE IF NOT EXISTS ${ACCOUNT_TABLE_NAME}
          (
           id INTEGER PRIMARY KEY AUTOINCREMENT,
           account CHAR(50) NOT NULL,
           name CHAR(50) NOT NULL,
           userName CHAR(50),
           nickName CHAR(50),
           note CHAR(100),
           pwd CHAR(50),
           createTime DATETIME,
           updateTime DATETIME,
           isDel INTEGER DEFAULT 0,
           groupId INTEGER DEFAULT 0
          );
`

  export const LOCK_TABLE_NAME = 'lock'

  export const SQL_CREATE_LOCK_TABLE = `CREATE TABLE IF NOT EXISTS ${LOCK_TABLE_NAME}
(
   id INTEGER PRIMARY KEY AUTOINCREMENT,
   pwd CHAR(50),
   createTime DATETIME,
   updateTime DATETIME
);
`

  export const ACCOUNT_BINDING_TABLE_NAME = 'account_binding'

  export const CREATE_ACCOUNT_BINDING_TABLE_SQL = `CREATE TABLE IF NOT EXISTS ${ACCOUNT_BINDING_TABLE_NAME}
          (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          type INTEGER NOT NULL,
          bind CHAR(50) NOT NULL,
          createTime DATETIME,
          updateTime DATETIME,
          isDel INTEGER DEFAULT 0
       );`

  export const ACCOUNT_BINDING_CONTACT_TABLE_NAME = 'account_binding_contact'

  export const SQL_CREATE_ACCOUNT_BINDING_CONTACT_TABLE = `CREATE TABLE IF NOT EXISTS ${ACCOUNT_BINDING_CONTACT_TABLE_NAME}
             (
             id INTEGER PRIMARY KEY AUTOINCREMENT,
             accountId INTEGER NOT NULL,
             bindingId INTEGER NOT NULL,
             createTime DATETIME,
             updateTime DATETIME
  );`


  export const ACCOUNT_GROUP_TABLE_NAME = 'account_group'

  export const SQL_CREATE_ACCOUNT_GROUP_TABLE = `CREATE TABLE IF NOT EXISTS ${ACCOUNT_GROUP_TABLE_NAME}
             (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name CHAR(30),
            createTime DATETIME,
            updateTime DATETIME
  );`

  const AccountBindingTypeMapLabelEntries: [AccountBindingType, string][] = [
    [AccountBindingType.Phone, '手机'],
    [AccountBindingType.Email, '邮箱'],
    [AccountBindingType.Wechat, '微信'],
    [AccountBindingType.QQ, 'QQ'],
    [AccountBindingType.ID, '身份证'],
    [AccountBindingType.Google, '谷歌账号'],
    [AccountBindingType.AppleID, '苹果账号'],
    [AccountBindingType.HuaweiID, '华为账号']
  ]

  export const AccountBindingTypeMapLabel = new Map(AccountBindingTypeMapLabelEntries)

  export const LabelMapAccountBindingType = new Map(AccountBindingTypeMapLabelEntries.map(v => ([v[1], v[0]])))

  export const PAGE_CONTENT_TOP_GAP = 25

  export const PAGE_CONTENT_HORIZONTAL_GAP = 10

  export const SYS_NAV_HEIGHT: number = AppStorage.Get('navHeight') || 30
}

export const DEFAULT_GROUP: AccountGroup = {
  id: 0,
  name: '默认分组',
  createTime: '',
  updateTime: ''
}