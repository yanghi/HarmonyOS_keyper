import {
  ab2str,
  stringifyError,
  stringToUint8Array,
  uint8ArrayToShowStr,
  uint8ArrayToString
} from '../common/utils/common'
import Logger from '../common/utils/Logger'
import { AccountListModel } from './Account'
import cryptoFramework from '@ohos.security.cryptoFramework'
import { cipherModel } from './Cipher'
import { AccountInterface } from '../common/interfaces/Account'
import { AccountBindingListModel } from './AccountBinding'
import { AccountBindingContactListModel } from './AccountBindingContact'
import { AppLock } from './Lock'
import { AccountBinding, AccountBindingContact } from '../common/interfaces/AccountBinding'
import { fsUtils } from '../common/utils/fsUtils'
import { ConverterModel } from './ConverterModel'
import { mockAccountList } from '../common/utils/MockData'

const TAG = '[DataManager]'
const EXPORT_TXT_FILE_NAME = "keyper.txt"

class DataManager {
  async resetAllData() {
    let sub = 'resetAllData() '

    try {
      Logger.error(TAG, sub)
      await Promise.all([
      this.resetAllDataBaseData(),
      ])

    } catch (e) {
      Logger.error(TAG, sub + 'failed,' + stringifyError(e))
      throw e
    }
  }

  async resetAllDataBaseData() {
    let sub = 'resetAllDataBaseData() '

    try {
      Logger.error(TAG, sub + 'start')
      await Promise.all([
      AccountListModel.resetDataBaseData(),
      AccountBindingListModel.resetDataBaseData(),
      AccountBindingContactListModel.resetDataBaseData()
      ])

    } catch (e) {
      Logger.error(TAG, sub + 'failed,' + stringifyError(e))

    }
  }

  async exportAsTxt(accounts: AccountInterface[]) {
    let sub = 'exportToTxt()'

    try {
      Logger.info(TAG, sub)
      await fsUtils.writeDoc(EXPORT_TXT_FILE_NAME, ConverterModel.toPlainText(accounts))
      Logger.info(TAG, sub + 'succeed')

    } catch (e) {
      Logger.error(TAG, sub + 'failed,' + stringifyError(e))
    }
  }

  async exportAsJson() {
    try {
      let res = await new PortCryptModel().output(AccountListModel.list)
      await fsUtils.writeDoc('keyper.json', res)
    } catch (e) {
      Logger.error(TAG, 'exportAsJson failed,' + stringifyError(e))
      throw e
    }
  }

  async importFromJson() {
    try {
      let buf = await fsUtils.readDoc()
      let fileStr = ab2str(buf)
      Logger.debug(TAG, 'read file data ' + fileStr)

      let res = await new PortCryptModel().input(fileStr)

      let data = res.body.data


      let importRes = await this.importDataToDb(data)
      Logger.info(TAG, 'importFromJson result ' + JSON.stringify(importRes))
      Logger.info(TAG, 'importFromJson result Data' + JSON.stringify(data))
      await AccountListModel.queryAll()
      return importRes
    } catch (e) {

      Logger.error(TAG, 'importFromJson failed,' + stringifyError(e))
      throw e

    }
  }

  private async importDataToDb(data: PortJson['body']['data']): Promise<ImportResult> {
    let result: ImportResult = {
      total: {
        account: data.accounts.length,
        binding: data.bindings.length,
        contact: data.bindings.length
      },
      succeed: {
        account: 0,
        binding: 0,
        contact: 0
      }
    }
    try {
      // old map new
      const newAccountIdMap = new Map<number, number>()
      const newBindingIdMap = new Map<number, number>()
      let bindingPromises = data.bindings.map(bd => {

        return AccountBindingListModel.add(bd).then(added => {
          newBindingIdMap.set(bd.id, added.id)
        })
      })
      let bindingRes = await Promise.allSettled(bindingPromises)

      result.succeed.binding = bindingRes.filter(br => br.status === 'fulfilled').length

      let accountPromises = data.accounts.map(ac => {
        return AccountListModel.add(ac).then((added) => {
          newAccountIdMap.set(ac.id, added.id)
        })
      })
      let accountRes = await Promise.allSettled(accountPromises)
      result.succeed.account = accountRes.filter(br => br.status === 'fulfilled').length

      let contactPromises = data.contacts.map(ct => {
        let accountId = newAccountIdMap.get(ct.accountId)

        if (!accountId) return Promise.reject(`cannot import account contact,caue imported account id=${accountId}  fail`)
        let bindingId = newBindingIdMap.get(ct.bindingId)
        if (!accountId) return Promise.reject(`cannot import account contact,caue imported binding id=${bindingId}  fail`)

        ct.accountId = accountId
        ct.bindingId = bindingId
        return AccountBindingContactListModel.add(ct)
      })

      let contactRes = await Promise.allSettled(contactPromises)
      result.succeed.account = contactRes.filter(br => br.status === 'fulfilled').length

    } catch (e) {
      Logger.error(TAG, 'importDataToDb failed,' + stringifyError(e))
    }

    return result
  }

  async testPort() {
    let sub = 'portTest() '
    try {
      Logger.debug(TAG, sub + 'output')
      let res = await new PortCryptModel().output(mockAccountList())
      Logger.debug(TAG, sub + 'input')
      let data = await new PortCryptModel().input(res)
      // Logger.debug(TAG, sub+ 'input')
      Logger.debug(TAG, sub + 'import to DB')
      let ires = await this.importDataToDb(data.body.data)

      Logger.debug(TAG, sub + 'success,' + JSON.stringify(ires))
    } catch (e) {
      Logger.error(TAG, sub + 'failed,' + stringifyError(e))
      throw e
    }
  }
}

interface ImportCounts {
  account: number
  binding: number
  contact: number
}

interface ImportResult {
  succeed: ImportCounts
  total: ImportCounts

}

interface RawPortJson {
  version: number
  body: string
  sign: string
  key: string
}

interface PortJson {
  version: number
  body: {
    data: {
      accounts: any[]
      bindings: AccountBinding[]
      contacts: AccountBindingContact[]
      users: any[]
    }
  }
}

const CRYPTO_SALT = 'KuRsS5KYQ9KfDB5X'

function mixSalt(s: string) {
  return s + CRYPTO_SALT
}

class PortCryptModel {
  private tag = '[PortConvertModel]'

  async input(raw: string): Promise<PortJson> {
    let sub = 'PortCryptModel.input() '
    Logger.info(this.tag, 'input ')
    // let raw = ''
    try {
      let json: RawPortJson = JSON.parse(raw)
      Logger.info(this.tag, sub + 'validateRawPortJson')

      await this.validateRawPortJson(raw, json)

      let body = json.body
      let md5 = await cryptoFramework.createMd('MD5')
      await md5.update({
        data: stringToUint8Array(mixSalt(json.key))
      })
      let mdRes = await md5.digest()
      let realKey = mdRes
      Logger.debug(this.tag, sub + 'realKey ' + uint8ArrayToShowStr(realKey.data))

      //  first decrypt
      Logger.info(this.tag, sub + 'first decrypt')
      Logger.debug(this.tag, sub + 'body ' + body.slice(0, 30))
      body = await cipherModel.aesDecrypt(body, { key: realKey })

      // second decrypt
      Logger.info(this.tag, sub + 'second decrypt')

      body = await cipherModel.aesDecrypt(body)
      Logger.debug(this.tag, sub + 'body ' + body.slice(0, 30))

      let bodyData = JSON.parse(body)
      let encrypted: PortJson = {
        version: json.version,
        body: bodyData,
      }

      return encrypted
    } catch (e) {

      let wrapErr = new Error('PortConvertModel.input is not invalid json file, reason:' + stringifyError(e))
      Logger.error(this.tag, stringifyError(wrapErr))
      throw wrapErr
    }
  }

  private async validateRawPortJson(raw: string, json: RawPortJson) {
    let valid = typeof json.version == 'number' && typeof json.body === 'string' && typeof json.sign == 'string'

    if (!valid) {
      throw 'invalid RawPortJson'
    }

    let sign = await this.signRawJson(json)
    if (sign !== json.sign) {
      Logger.debug(this.tag, 'json sign' + json.sign + ' conrrct ' + sign)
      throw 'The file has been tampered'
    }
    Logger.info(this.tag, 'validate sign ok')
  }

  private async signRawJson(json: RawPortJson) {
    let md5 = cryptoFramework.createMd('MD5')
    md5.update({ data: stringToUint8Array(this.rawJsonSignContent(json)) })
    let jsonMd5 = await md5.digest()

    let sign = await cipherModel.aesEncrypt(jsonMd5)
    return sign
  }

  private rawJsonSignContent(json: RawPortJson) {
    return json.version + json.key + json.body
  }

  async output(sources: AccountInterface[]) {
    let sub = 'PortCryptModel.output() '
    let accounts = sources.map(acc => {
      let data = { ...acc }
      delete data.bindings

      return data
    })
    let bindings = AccountBindingListModel.list
    let contacts = AccountBindingContactListModel.list
    let users = AppLock.userList


    let bodyData: PortJson['body'] = {
      data: {
        bindings,
        accounts,
        contacts,
        users
      }
    }

    let body = JSON.stringify(bodyData)
    //  first encrypt
    Logger.info(this.tag, sub + 'first decrypt')
    body = await cipherModel.aesEncrypt(body)
    Logger.debug(this.tag, sub + 'body ' + uint8ArrayToShowStr(body.slice(0, 32)))

    let rand = await cryptoFramework.createRandom().generateRandom(16)
    let key = uint8ArrayToString(rand.data)
    let md5 = await cryptoFramework.createMd('MD5')
    await md5.update({
      data: stringToUint8Array(mixSalt(key))
    })
    let mdRes = await md5.digest()
    let realKey = mdRes
    Logger.debug(this.tag, sub + 'realKey ' + uint8ArrayToShowStr(realKey.data))
    // second encrypt
    Logger.info(this.tag, sub + 'second decrypt')
    body = await cipherModel.aesEncrypt(body, { key: realKey })
    Logger.debug(this.tag, sub + 'body ' + uint8ArrayToShowStr(body.slice(0, 32)))


    let rawJson: RawPortJson = {
      version: 1,
      sign: '',
      key,
      body
    }


    let sign = await this.signRawJson(rawJson)
    rawJson.sign = sign

    return JSON.stringify(rawJson)
  }
}


export const dataManager = new DataManager()