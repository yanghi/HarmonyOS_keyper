import { CommonConstants } from '../common/constants/CommonConstants';
import { AccountInterface } from '../common/interfaces/Account';
import { AccountBinding, AccountBindingContact } from '../common/interfaces/AccountBinding';
import Logger from '../common/utils/Logger'
import picker from '@ohos.file.picker';
import fs from '@ohos.file.fs';
import {
  ab2str,
  dateTimeToDefaultString,
  stringifyError,
  stringToUint8Array,
  uint8ArrayToShowStr,
  uint8ArrayToString
} from '../common/utils/common';
import { cipherModel } from './Cipher';
import cryptoFramework from '@ohos.security.cryptoFramework';
import { AccountBindingListModel } from './AccountBinding';
import { AccountListModel } from './Account';
import { AccountBindingContactListModel } from './AccountBindingContact';
import { AppLock } from './Lock';
import { mockAccountList } from '../common/utils/MockData';

const TAG = '[Converter]'

class Converter {
  toPlainText(accounts: AccountInterface[]) {
    let txt = ''
    accounts.forEach(acc => {
      txt += this.fieldToStr('账号', acc.name)
      txt += this.fieldToStr('密码', acc.pwd)
      txt += this.fieldToStr('备注', acc.note)

      acc.bindings.forEach(bd => {
        txt += this.bindingToStr(bd)
      })

      txt += this.fieldToStr('创建于', dateTimeToDefaultString(acc.createTime))
      txt += this.fieldToStr('更新于', dateTimeToDefaultString(acc.updateTime))

      txt += '\n\n'
    })

    return txt
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