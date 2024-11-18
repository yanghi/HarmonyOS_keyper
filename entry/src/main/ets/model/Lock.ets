import { CommonConstants } from '../common/constants/CommonConstants'
import { Lock } from '../common/interfaces/Lock'
import { AppRelationalStoreManager } from '../common/stores/relationalStore'
import { rdbExtractResultRecords } from '../common/utils/DBUtils'
import cryptoFramework from '@ohos.security.cryptoFramework';

import Logger from '../common/utils/Logger'
import { stringifyError, stringToUint8Array, uint8ArrayToString } from '../common/utils/common'
import { cipherModel } from './Cipher'
import { User } from '../common/interfaces/User'
import { EventId, LockReason } from '../common/enums/Event'
import emitter from '@ohos.events.emitter'

const TAG = '[LockModel]'
const PWD_SALT = 'VI6Vhf9kX1QNumH2FKkQFKHEqaK7OKXR'

export type CustomPwdValidate = (inputSecret: string) => Promise<boolean>

interface PwdValidateResult {
  correct: boolean,
  inputSecret: string
}

class LockModel {
  private locked: boolean = true
  private startCountTimeStamp: number = 0
  private autoLockTime = 1000 * 60 * 5
  private lockData: Lock | null = null
  private lockSetup: boolean = false
  userList: User[] = []

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
      this.userList = items
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

  async resetDataBaseData() {
    let sub = 'AccountContact resetDataBaseData() '

    try {
      await AppRelationalStoreManager.execute('DELETE FROM ' + CommonConstants.LOCK_TABLE_NAME)
      this.lockData = null
      this.userList = []
    } catch (e) {
      Logger.error(TAG, sub + 'failed,' + stringifyError(e))
    }
  }

  async lockIsSetup() {
    await this.queryLock()
    return this.lockSetup
  }

  async getCurrentUserSecretedPwd() {
    return (await this.queryLock()).pwd
  }

  private async pwdSecret(input: string) {
    let md5 = cryptoFramework.createMd('MD5')
    let salted = PWD_SALT + input
    await md5.update({ data: stringToUint8Array(salted) })
    let result = await md5.digest()
    return uint8ArrayToString(result.data)
  }

  private async customPwdValidate(pwdInput: string, customValidate: CustomPwdValidate): Promise<PwdValidateResult> {
    Logger.debug(TAG, 'customPwdValidate()')

    let inputSecret = await this.pwdSecret(pwdInput)
    let isCorrect: boolean = false
    try {
      isCorrect = await customValidate(inputSecret)

    } catch (e) {
      Logger.error(TAG, 'customPwdValidate function run error=' + stringifyError(e))

    }

    Logger.debug(TAG, 'customPwdValidate() result correct=' + isCorrect)

    return {
      correct: isCorrect,
      inputSecret
    }
  }

  async isCorrectPwd(pwdInput: string, customValidate?: CustomPwdValidate): Promise<PwdValidateResult> {
    if (customValidate) {
      return await this.customPwdValidate(pwdInput, customValidate)
    }
    let lockData = await this.queryLock();
    if (!lockData) {
      Logger.warn(TAG, 'lock password not setup')
    }

    let inputSecret = await this.pwdSecret(pwdInput)
    let correct = lockData.pwd === inputSecret
    Logger.debug(TAG, 'isCorrectPwd result correct=' + correct)
    return {
      correct,
      inputSecret
    }
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

  lock(reason: LockReason) {
    if (this.locked) return
    this.locked = true
    this.startCountTimeStamp = 0

    emitter.emit({ eventId: EventId.Lock }, { data: { reason } })
  }

  unlock() {
    this.locked = false
    this.startCountTimeStamp = 0
  }

  private countTimer: number | null = null

  startCount() {
    if (this.locked) return

    clearInterval(this.countTimer)
    this.startCountTimeStamp = Date.now()

    this.countTimer = setInterval(() => {
      if (this.isLocked()) {
        clearInterval(this.countTimer)
        this.countTimer = null
      }
    }, 1000)

    if (!this.locked) {
      this.startCountTimeStamp = Date.now()
    }
  }

  stopCount() {
    clearInterval(this.countTimer)
    this.countTimer = null
  }

  resetCount() {
    this.stopCount()
    this.startCountTimeStamp = 0
  }

  isLocked() {
    if (this.locked || !this.startCountTimeStamp) return this.locked

    const diff = Date.now() - this.startCountTimeStamp
    if (diff > this.autoLockTime) {
      this.lock(LockReason.Expired)
    }

    return this.locked
  }
}

export const AppLock = new LockModel()