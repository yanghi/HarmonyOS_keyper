import { AccountInterface } from '../common/interfaces/Account';
import { MaskObject } from '../model/Mask';
import { AccountBindingViewModel } from './AccountBindingViewModel';
import pasteboard from '@ohos.pasteboard';
import promptAction from '@ohos.promptAction';
import { stringifyError } from '../common/utils/common';
import logger from '../common/utils/Logger';

type AccountMaskKeys = keyof Pick<AccountInterface, 'pwd' | 'account'>

const ACCOUNT_MASK_KEYS: AccountMaskKeys[] = ['pwd', 'account']
const TAG = '[AccountViewModel]'

@Observed
export class AccountViewModel extends MaskObject<AccountInterface, Array<AccountMaskKeys>> {
  bindings: AccountBindingViewModel[]

  constructor(data: AccountInterface) {
    super(data, ACCOUNT_MASK_KEYS)
    this.bindings = data.bindings?.map(b => new AccountBindingViewModel(b)) || []
  }

  forceUpdateBindingList() {
    this.bindings = this.bindings.slice()
  }

  isMaskKey(key: string): key is AccountMaskKeys {
    return ACCOUNT_MASK_KEYS.includes(key as any)
  }

  isAllMasked() {

    return super.isAllMasked() && this.bindings.every(bd => bd.isAllMasked())
  }

  toggleAllMask() {
    super.toggleAllMask()
    this.bindings.forEach(bd => {
      bd.toggleAllMask()
    })
  }

  keyLabel(key: keyof AccountInterface) {

    let label = ''
    switch (key) {
      case 'pwd':
        label = '密码'
        break
      case 'account':
        label = '账号'
        break
      case 'userName':
        label = '用户名'
        break
      case 'nickName':
        label = '昵称'
        break
      case 'note':
        label = '备注'
        break
    }

    return label
  }

  copyProp(key: keyof AccountInterface) {
    let val = this.data[key] as string

    let label = this.keyLabel(key)


    let pasteboardData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, val)

    const sysPasteboard = pasteboard.getSystemPasteboard()
    sysPasteboard.setData(pasteboardData).then(() => {
      promptAction.showToast({
        message: `${label}已复制到剪切板`
      })
    }).catch(e => {
      logger.error(TAG, 'paste data failed,' + stringifyError(e))
    })
  }
}