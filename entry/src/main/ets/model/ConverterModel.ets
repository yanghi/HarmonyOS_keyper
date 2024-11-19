import { CommonConstants } from '../common/constants/CommonConstants';
import { AccountInterface } from '../common/interfaces/Account';
import { AccountBinding } from '../common/interfaces/AccountBinding';
import { dateTimeToDefaultString, } from '../common/utils/common';
import { AccountModel } from './Account';

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
    return this.fieldToStr('关联' + typeStr, binding.bind)
  }

  propsToString(account: AccountInterface, props: Array<keyof AccountInterface>) {
    let str = ''
    props.forEach(key => {
      str += this.fieldToStr(AccountModel.keyToLabel(key), account[key as any])
    })

    return str
  }
}

export const ConverterModel = new Converter()