import cryptoFramework from '@ohos.security.cryptoFramework';
import Logger from '../common/utils/Logger'
import util from '@ohos.util';
import { stringifyError } from '../common/utils/common';

const TAG: string = '[CipherModel]'

const AES128: string = 'AES128';
const AES128_PKCS7: string = 'AES128|PKCS7';

const AES128_KEY = [217, 129, 244, 219, 110, 41, 124, 112, 198, 101, 35, 182, 24, 105, 203, 81]

function stringToUint8Array(str) {
  let arr = [];
  for (let i = 0, j = str.length; i < j; ++i) {
    arr.push(str.charCodeAt(i));
  }
  return new Uint8Array(arr);
}

function uint8ArrayToShowStr(uint8Array) {
  return Array.prototype.map
    .call(uint8Array, (x) => ('00' + x.toString(16)).slice(-2))
    .join('');
}

function uint8ArrayToString(array) {
  let arrayString = '';
  for (let i = 0; i < array.length; i++) {
    arrayString += String.fromCharCode(array[i]);
  }
  return arrayString;
}

type CryptoMessage = string | cryptoFramework.DataBlob | Uint8Array

function convertCryptoMessage(msg: CryptoMessage): cryptoFramework.DataBlob {
  if (typeof msg == 'string') return { data: stringToUint8Array(msg) }

  if (msg instanceof Uint8Array) return { data: msg }

  if (msg.data && msg.data instanceof Uint8Array) return msg

  throw { code: 401, msg: 'invalid CryptoMessage' }
}

interface CryptoParams {
  key?: cryptoFramework.DataBlob
  // decode or encode
  textCode?: boolean
}

const defaultCryptoParams: CryptoParams = {
  textCode: true
}

export class CipherModel {
  private _AESKeyBlob: Uint8Array | null = null

  setAESKeyBlob(data: string | Uint8Array) {
    let keyBlob = typeof data === 'string' ? stringToUint8Array(data) : data
    if (keyBlob.byteLength != 16) {
      Logger.error(TAG, 'keyMaterialBlob should be 16 bytes, but got ' + keyBlob.byteLength + ' bytes')
      return
    }

    Logger.debug(TAG, 'setAESKeyBlob ok')

    this._AESKeyBlob = keyBlob
  }

  private getAESKeyBlob() {
    if (this._AESKeyBlob) {
      return Promise.resolve({ data: this._AESKeyBlob })
    }

    Logger.warn(TAG, 'keyMaterialBlob is not setup, use default key')

    let keyMaterial = new Uint8Array(AES128_KEY)
    return Promise.resolve({ data: keyMaterial })
  }

  private async getAesSymKey(keyData?: cryptoFramework.DataBlob) {
    let symKeyGenerator = cryptoFramework.createSymKeyGenerator(AES128)

    if (!symKeyGenerator) throw Error('createSymKeyGenerator err')

    Logger.info(TAG, 'aesEncrypt symKeyGenerator.convertKey')
    const key = await symKeyGenerator.convertKey(keyData || await this.getAESKeyBlob())

    return key
  }

  async aesEncrypt(message: CryptoMessage, params: CryptoParams = defaultCryptoParams) {

    const key = await this.getAesSymKey(params.key)

    let cipher = cryptoFramework.createCipher(AES128_PKCS7);

    await cipher.init(cryptoFramework.CryptoMode.ENCRYPT_MODE, key, null)

    // let messageUint8 = new util.TextEncoder().encodeInto(message)
    let msgBlob = typeof message === 'string' && params.textCode ?
      { data: new util.TextEncoder().encodeInto(message) } :
    convertCryptoMessage(message)

    let r = await cipher.doFinal(msgBlob)

    if (r == null) {
      throw new Error('finalOutput is null')
    }

    // Logger.info(TAG, 'aes encrypt: ' + uint8ArrayToShowStr(r.data))

    let encryptedStr = uint8ArrayToString(r.data)
    // Logger.info(TAG, 'aes encrypt str: ' + r.data)

    return encryptedStr
  }

  async aesDecrypt(message: string, params: CryptoParams = defaultCryptoParams) {
    try {
      const key = await this.getAesSymKey(params.key)

      let cipher = cryptoFramework.createCipher(AES128_PKCS7);

      await cipher.init(cryptoFramework.CryptoMode.DECRYPT_MODE, key, null)

      let finalOutput = await cipher.doFinal({ data: stringToUint8Array(message) })

      let decryptStr: string
      if (params.textCode) {
        decryptStr = util.TextDecoder.create('utf-8', { fatal: true }).decodeWithStream(finalOutput.data)
      } else {
        decryptStr = uint8ArrayToString(finalOutput.data)
      }


      // Logger.debug(TAG, 'aesDecrypt str: ' + decryptStr)
      return decryptStr

    } catch (e) {
      Logger.error(TAG, 'aesDecrypt failed,' + stringifyError(e))
      throw e
    }
  }

  async aesDecryptProperties<T extends object>(data: T, keys: string[]) {
    let decryptPromises: Promise<any>[] = []
    Logger.debug(TAG, 'aesDecryptProperties data before:' + JSON.stringify(data))
    keys.forEach(key => {
      let val = data[key]
      if (typeof val !== 'string' || val == '') return
      decryptPromises.push(this.aesDecrypt(val).then((res) => {
        data[key] = res
      }))
    })

    await Promise.all(decryptPromises).catch(e => {
      throw { msg: 'aesDecryptProperties ' + stringifyError(e) }
    })
    Logger.debug(TAG, 'aesDecryptProperties data result:' + JSON.stringify(data))

    return data
  }

  async aesEncryptProperties<T extends object>(data: T, keys: string[]) {
    let promises: Promise<any>[] = []
    Logger.debug(TAG, 'aesEncryptProperties data before:' + JSON.stringify(data))
    keys.forEach(key => {
      let val = data[key]
      if (typeof val !== 'string' || val == '') return
      promises.push(this.aesEncrypt(val).then((res) => {
        data[key] = res
      }))
    })

    await Promise.all(promises).catch(e => {
      Logger.error(TAG, 'aesEncryptProperties data err :' +
      JSON.stringify(e))
      throw e
    })
    Logger.debug(TAG, 'aesEncryptProperties data result:' + JSON.stringify(data))

    return data
  }

  async testAes() {
    try {
      Logger.debug(TAG, 'testAes')

      let r = await cipherModel.aesEncrypt('this is test! 这是测试!')
      await cipherModel.aesDecrypt(r)
    } catch (e) {
      Logger.error(TAG, 'testAes er ' + JSON.stringify(e))
    }
  }

  async testAesBigJsonText() {
    try {
      Logger.debug(TAG, 'testAesBigText')

      let arr: string[] = []
      for (let i = 0;i < 10000; i++) {
        let randStr = Math.random().toString(16)
        arr.push(randStr)
      }
      let data = {
        list: arr
      }
      let en = await cipherModel.aesEncrypt(JSON.stringify(data))
      let de = await cipherModel.aesDecrypt(en)

      let json = JSON.parse(de)
      let pass = json.list[9999] === data.list[9999] && json.list.length === data.list.length
      Logger.warn(TAG, 'testAesBigText pass ' + pass)
    } catch (e) {
      Logger.error(TAG, 'testAesBigText er ' + JSON.stringify(e))
    }

  }
}

export const cipherModel = new CipherModel()
