import { CommonConstants } from '../common/constants/CommonConstants';
import { AccountInterface } from '../common/interfaces/Account';
import { AccountBinding } from '../common/interfaces/AccountBinding';
import Logger from '../common/utils/Logger'
import picker from '@ohos.file.picker';
import fs from '@ohos.file.fs';
import { dateTimeToDefaultString, stringifyError } from '../common/utils/common';

const TAG = '[Converter]'

class Converter {
  async exportToExt(accounts: AccountInterface[]) {
    let extStr = ''
    accounts.forEach(acc => {
      extStr += this.fieldToStr('账号', acc.name)
      extStr += this.fieldToStr('密码', acc.pwd)
      extStr += this.fieldToStr('备注', acc.note)

      acc.bindings.forEach(bd => {
        extStr += this.bindingToStr(bd)
      })

      extStr += this.fieldToStr('创建于', dateTimeToDefaultString(acc.createTime))
      extStr += this.fieldToStr('更新于', dateTimeToDefaultString(acc.updateTime))

      extStr += '\n\n'
    })

    const documentSaveOptions = new picker.DocumentSaveOptions();
    documentSaveOptions.newFileNames = ["keyper.txt"];

    const documentViewPicker = new picker.DocumentViewPicker();
    try {
      Logger.info(TAG, 'documentViewPicker.save')
      let documentSaveResult = await  documentViewPicker.save(documentSaveOptions)
      Logger.debug(TAG, 'uri' + documentSaveResult[0])
      let uri = documentSaveResult[0];

      Logger.info(TAG, 'documentViewPicker.save to file succeed and URI is:' + uri);
      let file = fs.openSync(uri, fs.OpenMode.READ_WRITE);
      Logger.info(TAG, 'file fd: ' + file.fd);

      let writeLen = fs.writeSync(file.fd, extStr);
      Logger.info(TAG, 'write data to file succeed and size is:' + writeLen);
      fs.closeSync(file);
    } catch (e) {
      Logger.error(TAG, 'write failed, err:' + stringifyError(e) + ' msg ' + e?.message)
      throw e
    }

    return extStr
  }

  private fieldToStr(name: string, value: string) {
    if (!value) return '\n'
    return name + ':' + value + '\n'
  }

  private bindingToStr(binding: AccountBinding) {
    let typeStr = CommonConstants.AccountBindingTypeMapLabel.get(binding.type)
    return this.fieldToStr('绑定' + typeStr, binding.bind)
  }
}

export const ConverterModel = new Converter()