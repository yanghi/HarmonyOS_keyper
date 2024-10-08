import cryptoFramework from '@ohos.security.cryptoFramework';
import hilog from '@ohos.hilog';
import Logger from '../common/utils/Logger'
import util from '@ohos.util';
import { stringifyError } from '../common/utils/common';
import huks from '@ohos.security.huks';

const TAG: string = '[CipherModel]'
const AES_ENCRYPT_KEY: string = '5QXzAbJj0TJN9OQNvxFhhw==';

const RSA_ENCRYPT_KEY: string =
  'MFwwDQYJKoZIhvcNAQEBBQADSwAwSAJBALXJZEloyLbBB6UbUQzUtM3WGTkcd4dn4HgCxL5wHcdICoLbv6EiUjcaQq8c906hqv6/J7Bv9Owj59XMauKweJUCAwEAAQ==';
const RSA_DECRYPT_KEY: string =
  'MIIBVAIBADANBgkqhkiG9w0BAQEFAASCAT4wggE6AgEAAkEAtclkSWjItsEHpRtRDNS0zdYZORx3h2fgeALEvnAdx0gKgtu/oSJSNxpCrxz3TqGq/r8nsG/07CPn1cxq4rB4lQIDAQABAkA3boG2IM2TbKj4H6xHTVUUrwRh9dw83eAEuFNl/qoV6c4zRUAx+efZ29rDz6CVWuAhxaVBDUOmOHvyxOL8m8IBAiEA3EcTP1jngtiJ8lffvIVbehM6p7437+9UScKMXZSy/PkCIQDTRFj00GbAW9oKqEWTrUCWNxNFCSR82Mlw1sZvQh5LfQIgBApBrh3BUUMLdKhr8Bc6EEkeAEma2Qm4sAmjbWv2xHECIF81ux1BWj0wZ9hLs2d1Odk4ot+G2kHFdSr8L9tuIbcFAiEA2rEXmzyQTxZM1N4QDkaLJiCwSfMTYu48DxfUcevbfhA=';
const RSA512_PRIMES_2: string = 'RSA512|PRIMES_2';
const RSA512_PKCS1: string = 'RSA512|PKCS1';
const AES128: string = 'AES128';
const AES128_PKCS7: string = 'AES128|PKCS7';

const AES_ALG = '3DES192'
const AES_CIPHER = 'AES128|PKCS7'

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

function genKeyMaterialBlob() {
  let arr = [
    0xba, 0x3d, 0xc2, 0x71, 0x21, 0x1e, 0x30, 0x56,
    0xad, 0x47, 0xfc, 0x5a, 0x46, 0x39, 0xee, 0x7c,
    0xba, 0x3b, 0xc2, 0x71, 0xab, 0xa0, 0x30, 0x72]; // keyLen = 192 (24 bytes)
  let keyMaterial = new Uint8Array(arr);

  // return {data: stringToUint8Array('XJ2j1voBb6CHAyJqKK5duGQ3')}
  return { data: keyMaterial };
}

export class CipherModel {
  private _keyBlob: Uint8Array | null = null

  setKeyMaterialBlob(data: string | Uint8Array) {
    let keyBlob = typeof data === 'string' ? stringToUint8Array(data) : data
    if (keyBlob.byteLength != 24) {
      Logger.error(TAG, 'keyMaterialBlob should be 24 bytes, but got ' + keyBlob.byteLength + ' bytes')
      return
    }

    Logger.debug(TAG, 'setKeyMaterialBlob ok')

    this._keyBlob = keyBlob
  }

  private getKeyMaterialBlob() {
    if (this._keyBlob) {
      return Promise.resolve({ data: this._keyBlob })
    }

    Logger.warn(TAG, 'keyMaterialBlob is not setup, use default key')
    let arr = [
      0xba, 0x3d, 0xc2, 0x71, 0x21, 0x1e, 0x30, 0x56,
      0xad, 0x47, 0xfc, 0x5a, 0x46, 0x39, 0xee, 0x7c,
      0xba, 0x3b, 0xc2, 0x71, 0xab, 0xa0, 0x30, 0x72]; // keyLen = 192 (24 bytes)
    let keyMaterial = new Uint8Array(arr);

    // return {data: stringToUint8Array('XJ2j1voBb6CHAyJqKK5duGQ3')}
    return Promise.resolve({ data: keyMaterial })
  }

  async aesEncrypt(message: string) {
    let symKeyGenerator = cryptoFramework.createSymKeyGenerator(AES_ALG)

    if (!symKeyGenerator) throw Error('createSymKeyGenerator err')

    let cipher = cryptoFramework.createCipher(AES_CIPHER);

    Logger.info(TAG, 'aesEncrypt symKeyGenerator.convertKey')
    // const key = await symKeyGenerator.convertKey({ data: stringToUint8Array(pubKey) })
    const key = await symKeyGenerator.convertKey(await this.getKeyMaterialBlob())

    let encodedKey = key.getEncoded();

    Logger.info(TAG, 'key getEncoded hex: ' + uint8ArrayToShowStr(encodedKey.data));
    await cipher.init(cryptoFramework.CryptoMode.ENCRYPT_MODE, key, null)

    let messageUint8 = new util.TextEncoder().encodeInto(message)
    // let r = await cipher.doFinal({ data: stringToUint8Array(message) })
    let r = await cipher.doFinal({ data: messageUint8 })

    if (r == null) {
      throw new Error('finalOutput is null')
    }

    Logger.info(TAG, 'aes encrypt: ' + uint8ArrayToShowStr(r.data))

    let encryptedStr = uint8ArrayToString(r.data)
    Logger.info(TAG, 'aes encrypt str: ' + r.data)

    return encryptedStr
  }

  async aesDecrypt(message: string) {
    try {

      let symKeyGenerator = cryptoFramework.createSymKeyGenerator(AES_ALG)

      if (!symKeyGenerator) throw Error('createSymKeyGenerator err')

      let cipher = cryptoFramework.createCipher(AES_CIPHER);

      // const key = await symKeyGenerator.convertKey({ data: stringToUint8Array(pubKey) })
      const key = await symKeyGenerator.convertKey(await this.getKeyMaterialBlob())

      let encodedKey = key.getEncoded();

      Logger.info(TAG, 'key getEncoded hex: ' + uint8ArrayToShowStr(encodedKey.data));
      await cipher.init(cryptoFramework.CryptoMode.DECRYPT_MODE, key, null)
      // let messageUint8 = new util.TextEncoder(message).encodeInto()

      let finalOutput = await cipher.doFinal({ data: stringToUint8Array(message) })

      let decryptStr = util.TextDecoder.create('utf-8', { fatal: true }).decodeWithStream(finalOutput.data)

      Logger.debug(TAG, 'aesDecrypt str: ' + decryptStr)
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

  async testAesEncrypt() {
    try {
      Logger.debug(TAG, 'testAesEncrypt')

      let r = await cipherModel.aesEncrypt('Hei22fdddddddddddddssss返回')
      await cipherModel.aesDecrypt(r)
    } catch (e) {
      Logger.error(TAG, 'testAesEncrypt er ' + JSON.stringify(e) + (e))
    }
  }
}

export const cipherModel = new CipherModel()

export async function testAES() {
  try {
    let r = await cipherModel.aesEncrypt('Hei')
  } catch (e) {
    hilog.error(0xFF00, 's', '%{public}s, %{public}s', '[aes]', 'ff')
    console.error('test er', e)
  }
}