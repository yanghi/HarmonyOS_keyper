import { CommonConstants } from '../common/constants/CommonConstants'
import { Lock } from '../common/interfaces/Lock'
import { AppRelationalStoreManager } from '../common/stores/relationalStore'
import { rdbExtractResultRecords } from '../common/utils/DBUtils'
import cryptoFramework from '@ohos.security.cryptoFramework';

import Logger from '../common/utils/Logger'
import { stringToUint8Array, uint8ArrayToString } from '../common/utils/common'
import { cipherModel } from './Cipher'

const TAG = '[LockModel]'
const PWD_SALT = 'VI6Vhf9kX1QNumH2FKkQFKHEqaK7OKXR'

class LockModel {
  private locked: boolean = true
  private lockTimeStamp: number = 0
  private autoLockTime = 1000 * 60 * 2
  private lockData: Lock | null = null
  private lockSetup: boolean = false

  async queryLock() {
    if (this.lockData) return this.lockData
    try {
      let resSet = await AppRelationalStoreManager.querySql(`SELECT * FROM ${CommonConstants.LOCK_TABLE_NAME}`)
      let items = rdbExtractResultRecords(resSet, {
        'id': '- INT',
        'createTime': '- DATETIME',
        'updateTime': '- DATETIME',
        'pwd': '- VARCHAR',
      })
      this.lockSetup = !!items.length
      this.lockData = items[0]

      if (this.lockData) {
        // 16 bytes
        let pwdMd = this.lockData.pwd

        cipherModel.setAESKeyBlob(pwdMd)
      }
      Logger.info(TAG, 'get lock ok, lockSetup=' + this.lockSetup)
    } catch (e) {
      Logger.error(TAG, 'query lock failed, err:' + JSON.stringify(e))
    }
  }

  async lockIsSetup() {
    await this.queryLock()
    return this.lockSetup
  }

  private async pwdSecret(input: string) {
    let md5 = cryptoFramework.createMd('MD5')
    let salted = PWD_SALT + input
    await md5.update({ data: stringToUint8Array(salted) })
    let result = await md5.digest()
    Logger.debug(TAG, 'len' + result.data.byteLength)
    return uint8ArrayToString(result.data)
  }

  async isCorrectPwd(pwdInput: string) {
    let correct = await this.queryLock();
    if (!correct) {
      Logger.warn(TAG, 'lock password not setup')
      return false
    }
    let inputSecret = await this.pwdSecret(pwdInput)
    return correct.pwd === inputSecret
  }

  async createLock(pwdInput: string) {
    try {
      let lockVal = {
        pwd: await this.pwdSecret(pwdInput),
        updateTime: Date.now(),
        createTime: Date.now()
      }
      Logger.info(TAG, 'create lock: ' + lockVal.pwd)

      let insertRes = await AppRelationalStoreManager.insert(CommonConstants.LOCK_TABLE_NAME, lockVal)
      this.queryLock()
      Logger.info(TAG, 'create lock ok, raw  id=' + insertRes)
    } catch (e) {
      Logger.error(TAG, 'create lock failed, err:', JSON.stringify(e))
      throw e
    }
  }

  lock() {
    this.locked = true
    this.lockTimeStamp = 0
  }

  unlock() {
    this.locked = false
    this.lockTimeStamp = Date.now()
  }

  startCount() {
    if (!this.locked) {
      this.lockTimeStamp = Date.now()
    }
  }

  isLocked() {
    if (this.locked) return true

    const diff = Date.now() - this.lockTimeStamp
    if (diff > this.autoLockTime) {
      this.lock()
    }

    return this.locked
  }
}

export const AppLock = new LockModel()