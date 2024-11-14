import { CommonConstants } from '../common/constants/CommonConstants';
import { AccountBindingType } from '../common/enums/account';
import { AccountBinding, AccountBindingWithContactId } from '../common/interfaces/AccountBinding';
import { AccountBindingListModel, AccountBindingModel } from '../model/AccountBinding';
import Logger from '../common/utils/Logger'
import { MaskObject } from '../model/Mask';
import promptAction from '@ohos.promptAction';
import pasteboard from '@ohos.pasteboard';
import { stringifyError } from '../common/utils/common';

const TAG = '[AccountBindingViewModel]'
type AccountMaskKeys = keyof Pick<AccountBindingData, 'bind'>

type AccountBindingData = AccountBindingWithContactId | AccountBinding
const ACCOUNT_BINDING_MASK_KEYS: AccountMaskKeys[] = ['bind']

@Observed
export class AccountBindingViewModel extends MaskObject<AccountBindingData, Array<AccountMaskKeys>> {
  typeLabel: string
  private initCopy: AccountBindingWithContactId | AccountBinding

  constructor(data: AccountBindingWithContactId | AccountBinding) {
    super(data, ACCOUNT_BINDING_MASK_KEYS)
    Object.assign(this, { contactId: -1 }, data)
    this.initCopy = Object.assign({}, data)
    this.typeLabel = CommonConstants.AccountBindingTypeMapLabel.get(data.type)
    this.updateCurrentTypeContactOptions()
  }

  isContacted() {
    return this.contactId !== -1
  }

  isChange() {
    return this.initCopy.type !== this.type || this.initCopy.bind !== this.bind
  }

  setType(type: AccountBindingType) {
    this.typeLabel = CommonConstants.AccountBindingTypeMapLabel.get(type)
    this.type = type
    this.id = -1
    this.contactId = -1
    this.updateCurrentTypeContactOptions()

  }

  setTypeLabel(label: string) {
    this.type = CommonConstants.LabelMapAccountBindingType.get(label)
    this.typeLabel = label
    this.id = -1
    this.contactId = -1
    this.updateCurrentTypeContactOptions()

  }

  value(): AccountBindingWithContactId {
    return {
      contactId: this.contactId,
      updateTime: this.updateTime,
      createTime: this.createTime,
      id: this.id,
      bind: this.bind,
      type: this.type
    }
  }

  private currentTypeContactOptions: (SelectOption & { bindingId: number })[] = []

  getCurrentTypeContactOptions() {
    return this.currentTypeContactOptions
  }

  updateCurrentTypeContactOptions() {
    let group = AccountBindingListModel.getTypeGroup().get(this.type) || []
    this.currentTypeContactOptions = group.map(ab => ({
      value: ab.bind,
      bindingId: ab.id
    }))
  }

  contactCurrentTypeBindingWithIdx(bindingIdx: number) {
    let binding = this.currentTypeContactOptions[bindingIdx]
    if (binding) {
      this.id = binding.bindingId
      this.bind = binding.value as string
    }
  }

  copyBind() {
    let label = this.typeLabel

    let pasteboardData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.bind)

    const sysPasteboard = pasteboard.getSystemPasteboard()
    sysPasteboard.setData(pasteboardData).then(() => {
      promptAction.showToast({
        message: `${label}已复制到剪切板`
      })
    }).catch(e => {
      Logger.error(TAG, 'paste data failed,' + stringifyError(e))
    })
  }
}

export interface AccountBindingViewModel extends AccountBindingWithContactId {}
