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
import { CipherModel, cipherModel } from './Cipher'
import { AccountInterface } from '../common/interfaces/Account'
import { AccountBindingListModel } from './AccountBinding'
import { AccountBindingContactListModel } from './AccountBindingContact'
import { AppLock } from './Lock'
import { AccountBinding, AccountBindingContact } from '../common/interfaces/AccountBinding'
import { fsUtils } from '../common/utils/fsUtils'
import { ConverterModel } from './ConverterModel'
import { mockAccountList } from '../common/utils/MockData'
import { AccountGroup } from '../common/interfaces/AccountGroup'
import { AccountGroupListModel } from './AccountGroup'
import { DEFAULT_GROUP } from '../common/constants/CommonConstants'

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

  createJsonImporter() {
    return new JsonImporter()
  }

  async testPort() {
    let sub = 'portTest() '
    try {
      Logger.debug(TAG, sub + 'output')
      let res = await new PortCryptModel().output(mockAccountList())
      Logger.debug(TAG, sub + 'input')

      let importer = this.createJsonImporter()
      importer.setDocContent(res)
      await  importer.validateAndCheckToken()
      let ires = await importer.doFinal()

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
  group: number
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
  token?: string
}

interface TokenData {
  token: string
  secret: string
}

interface PortJson {
  version: number
  token?: TokenData
  body: {
    data: {
      accounts: AccountInterface[]
      bindings: AccountBinding[]
      contacts: AccountBindingContact[]
      users: any[]
      groups: AccountGroup[]
    }
  }
}

const CRYPTO_SALT = 'KuRsS5KYQ9KfDB5X'
const IMPORT_TOKEN = 'cOdY8jjZkH7ckH4G'

function mixSalt(s: string) {
  return s + CRYPTO_SALT
}

export class PortCryptModel {
  static tag = '[PortConvertModel]'
  private tag = PortCryptModel.tag

  constructor(private  cipher: CipherModel = cipherModel) {
  }

  private shimJson(json: PortJson) {
    if (!json.body.data.groups) {
      json.body.data.groups = []
    }
  }
  // 返回token校验结果,表明是否和当前密码一致
  async checkToken(token: string | undefined): Promise<boolean> {
    if (!token) return true

    return await PortCryptModel.checkTokenWithCipher(token, cipherModel)
  }

  static async checkTokenWithCipher(token: string, cipher: CipherModel) {
    if (!token) return true
    try {
      let decryptToken = await cipher.aesDecrypt(token)

      return decryptToken === IMPORT_TOKEN
    } catch (e) {
      Logger.error(this.tag, 'checkTokenWithCipher() failed' + stringifyError(e))
    }

    return false
  }

  async validateInput(raw: string): Promise<RawPortJson> {
    let sub = 'PortCryptModel.input() '
    let json: RawPortJson = JSON.parse(raw)
    Logger.info(this.tag, sub + 'validateRawPortJson')

    this.validateRawPortJsonSimple(json)
    return json
  }

  async decryptJson(json: RawPortJson): Promise<PortJson> {
    let sub = 'PortCryptModel.decryptJson() '
    Logger.info(this.tag, sub)
    // let raw = ''
    try {
      await this.validateRawPortJsonSign(json)
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
      body = await this.cipher.aesDecrypt(body, { key: realKey })

      // second decrypt
      Logger.info(this.tag, sub + 'second decrypt')

      body = await this.cipher.aesDecrypt(body)
      Logger.debug(this.tag, sub + 'body ' + body.slice(0, 30))

      let bodyData = JSON.parse(body)
      let encrypted: PortJson = {
        version: json.version,
        body: bodyData,
      }

      this.shimJson(encrypted)

      return encrypted
    } catch (e) {

      let wrapErr = new Error('PortConvertModel.input is not invalid json file, reason:' + stringifyError(e))
      Logger.error(this.tag, stringifyError(wrapErr))
      throw wrapErr
    }
  }

  private validateRawPortJsonSimple(json: RawPortJson) {
    let valid = typeof json.version == 'number' && typeof json.body === 'string' && typeof json.sign == 'string'

    if (!valid) {
      throw 'invalid RawPortJson'
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

  private async validateRawPortJsonSign(json: RawPortJson) {
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

    let sign = await this.cipher.aesEncrypt(jsonMd5)
    return sign
  }

  private rawJsonSignContent(json: RawPortJson) {
    return json.version + json.key + json.body + (json.token || '')
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
    let groups = AccountGroupListModel.list

    let bodyData: PortJson['body'] = {
      data: {
        bindings,
        accounts,
        contacts,
        users,
        groups
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

    Logger.info(this.tag, sub + 'gen token')
    let token = await cipherModel.aesEncrypt(IMPORT_TOKEN)

    let rawJson: RawPortJson = {
      version: 2,
      sign: '',
      key,
      body,
      token
    }


    let sign = await this.signRawJson(rawJson)
    rawJson.sign = sign

    return JSON.stringify(rawJson)
  }
}

class JsonImporter {
  private portCrypt: PortCryptModel
  private tag = '[JsonImporter]'
  private fileContent: ArrayBuffer | string
  private rawJson: RawPortJson
  private checkTokenResult: boolean

  constructor() {
    this.portCrypt = new PortCryptModel()

  }

  async readDoc() {
    let buf = await fsUtils.readDoc()
    this.fileContent = buf
  }

  getRawJson() {
    return this.rawJson
  }

  async setDocContent(content: ArrayBuffer | string) {
    this.fileContent = content
  }

  async validateAndCheckToken(): Promise<boolean> {
    let fileStr = typeof this.fileContent == 'string' ? this.fileContent : ab2str(this.fileContent)
    this.rawJson = await this.portCrypt.validateInput(fileStr)

    let checkTokenResult = this.checkTokenResult = await this.portCrypt.checkToken(this.rawJson.token)
    return checkTokenResult
  }
  // decrypt and import data to DB
  async doFinal(cipher?: CipherModel): Promise<ImportResult> {
    if (!this.checkTokenResult) {
      if (!cipher) {
        let msg = 'miss cipher params when checkTokenResult is false'
        Logger.error(this.tag, msg)
        throw { code: 401, msg }
      }
      this.portCrypt = new PortCryptModel(cipher)
    }
    let decryptedJson = await this.portCrypt.decryptJson(this.rawJson)

    return await this.importDataToDb(decryptedJson.body.data)
  }

  private async importDataToDb(data: PortJson['body']['data']): Promise<ImportResult> {
    let result: ImportResult = {
      total: {
        account: data.accounts.length,
        binding: data.bindings.length,
        contact: data.bindings.length,
        group: data.groups.length,
      },
      succeed: {
        account: 0,
        binding: 0,
        contact: 0,
        group: 0
      }
    }
    let sub = 'importDataToDb() '

    try {
      // old map new
      const newAccountIdMap = new Map<number, number>()
      const newBindingIdMap = new Map<number, number>()
      const newGroupIdMap = new Map<number, number>()

      let groupPromises = data.groups.map(gp => {
        return AccountGroupListModel.add(gp).then(added => {
          newGroupIdMap.set(gp.id, added.id)
        })
      })
      let groupRes = await Promise.allSettled(groupPromises)
      result.succeed.group = groupRes.filter(br => br.status === 'fulfilled').length

      let bindingPromises = data.bindings.map(bd => {

        return AccountBindingListModel.add(bd).then(added => {
          newBindingIdMap.set(bd.id, added.id)
        })
      })
      let bindingRes = await Promise.allSettled(bindingPromises)

      result.succeed.binding = bindingRes.filter(br => br.status === 'fulfilled').length

      let accountPromises = data.accounts.map(ac => {
        let groupId = newGroupIdMap.get(ac.groupId)
        if (!groupId && ac.groupId != DEFAULT_GROUP.id) {
          Logger.error(
            TAG,
            sub
            + 'account cannot contact correct groupId,reset to 0, origin account id='
            + ac.id + ' groupId=' + ac.groupId
          )
        }
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

      Logger.debug(TAG, 'importDataToDb ok')
    } catch (e) {
      Logger.error(TAG, 'importDataToDb failed,' + stringifyError(e))
    }

    return result
  }
}


export const dataManager = new DataManager()