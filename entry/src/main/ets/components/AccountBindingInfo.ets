import { AccountBindingType } from '../common/enums/account'

const tmap = new Map([
  [AccountBindingType.Phone, '手机']]
)

function accountBindingTypeText(type: AccountBindingType): string {
  return tmap.get(type)
}

@Component
export default struct AccountBindingInfo {
  @State type: AccountBindingType = AccountBindingType.Phone
  @State bind: string = ''

  @Builder renderType(type: AccountBindingType) {

  }

  build() {
    Row() {
      Text(accountBindingTypeText(this.type))
        .margin({ right: 10 })
      Text(this.bind)
        .fontColor($r('app.color.gray_7'))
    }
  }
}