import { AccountInterface } from '../common/interfaces/Account';
import { MaskObject } from '../model/Mask';
import { AccountBindingViewModel } from './AccountBindingViewModel';

type AccountMaskKeys = keyof Pick<AccountInterface, 'pwd' | 'account'>

const ACCOUNT_MASK_KEYS: AccountMaskKeys[] = ['pwd', 'account']

export class AccountViewModel extends MaskObject<AccountInterface, Array<AccountMaskKeys>> {
  bindings: AccountBindingViewModel[]

  constructor(data: AccountInterface) {
    super(data, ACCOUNT_MASK_KEYS)
    this.bindings = data.bindings?.map(b => new AccountBindingViewModel(b)) || []
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
}