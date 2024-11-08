import {
  checkPasswordStrength,
  CheckPasswordStrengthResult,
  PasswordStrength
} from '../common/utils/CheckPasswordStrength'
import logger from '../common/utils/Logger'

const TAG = '[PasswordStrengthIndicator Component]'

function mapPasswordStrengthToText(strength: PasswordStrength) {
  switch (strength) {
    case PasswordStrength.VeryWeak:
      return '非常低'
    case PasswordStrength.Weak:
      return '低'
    case PasswordStrength.Mid:
      return '一般'
    case PasswordStrength.Strong:
      return '高'
    case PasswordStrength.VeryStrong:
      return '非常高'
  }
}

@Styles function strengthBlock() {
  .borderRadius(3)
  .backgroundColor('gray')

}

let danger = '#f56c6c'
let warn = '#FF9100'
let pass = '#5CB900'
let inactive = '#DDDDDD'
let contain = '#2cb117'
let notContain = $r('app.color.gray_7')
let default_block_colors = [inactive, inactive, inactive, inactive, inactive]

@Component
export struct PasswordStrengthIndicator {
  @Prop @Watch('onPassWordChange') password: string
  @State checkResult: CheckPasswordStrengthResult | null = null
  @State strengthBlocks: Array<string | Resource> = default_block_colors
  private onStrengthResultChange?: (result: CheckPasswordStrengthResult | null) => void
  showInfo: boolean = false

  onPassWordChange() {

    if (this.password) {
      this.check()
    } else {
      this.checkResult = null
      this.strengthBlocks = default_block_colors
      this.onStrengthResultChange?.(null)

    }
  }

  check() {
    let result = this.checkResult = checkPasswordStrength(this.password)

    this.onStrengthResultChange?.(result)
    const colors = [danger, danger, warn, pass, pass]
    let activeColor = colors[result.strength]
    this.strengthBlocks = colors.map((color, idx) => {

      return idx > result.strength ? inactive : activeColor
    })
  }

  build() {
    Column() {
      Row() {
        Row() {
          ForEach(this.strengthBlocks, (color: string) => {
            Row() {
            }
            .strengthBlock()
            .height(4)
            .margin({ left: 3 })
            .width(40)
            .backgroundColor(color)
            .alignSelf(ItemAlign.Center)
          })
        }

        Row() {
          Text(this.checkResult ? mapPasswordStrengthToText(this.checkResult.strength) : '请输入')
            .alignSelf(ItemAlign.Center)
            .textAlign(TextAlign.End)
            .fontColor($r('app.color.gray_7'))
            .fontSize(12)
        }
      }
      // .margin({ top: 5 })
      .height(30)
      .justifyContent(FlexAlign.SpaceBetween)
      .width('100%')

      if (this.showInfo) {
        Row() {
          Row() {
            Text('长度 ').fontColor('#666666')
            Text(this.password.length + '')
              .fontColor(this.password.length > 8 ? contain : notContain)
          }.margin({ right: 20 })

          Row() {
            Text('数字')
              .fontColor(this.checkResult && this.checkResult.contain.numbers ? contain : notContain)
              .margin({ left: 5 })
            Text('小写')
              .margin({ left: 5 })
              .fontColor(this.checkResult && this.checkResult.contain.lowerCase ? contain : notContain)
            Text('大写')
              .margin({ left: 5 })
              .fontColor(this.checkResult && this.checkResult.contain.upperCase ? contain : notContain)
            Text('标点')
              .margin({ left: 5 })
              .fontColor(this.checkResult && this.checkResult.contain.symbols ? contain : notContain)
          }.alignSelf(ItemAlign.Center)
        }.width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
      }
    }
  }
}