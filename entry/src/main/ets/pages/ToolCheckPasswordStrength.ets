import { CommonConstants } from '../common/constants/CommonConstants'
import {
  CheckPasswordStrengthResult,
  PasswordStrength,
  checkPasswordStrength
} from '../common/utils/CheckPasswordStrength'

import logger from '../common/utils/Logger'

const TAG = '[ToolCheckPasswordStrength]'

function mapPasswordStrengthToText(strength: PasswordStrength) {
  logger.debug(TAG, 'map tx ' + strength)
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
  .height(6)
  .width(50)
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
export struct ToolCheckPasswordStrength {
  @State checkResult: CheckPasswordStrengthResult | null = null
  pwd: string = ''
  @State strengthBlocks: Array<string | Resource> = default_block_colors
  @State tips: string[] = [
    '使用两种以上的组合,数字/小写字母/大写字母/标点符号',
    '长度建议使用8位及以上',
    '避免使用连续的相同字符,如111,666',
    '避免使用键盘的连续字符,如asd,123'
  ]

  check() {
    let result = this.checkResult = checkPasswordStrength(this.pwd)


    const colors = [danger, danger, warn, pass, pass]
    let activeColor = colors[result.strength]
    this.strengthBlocks = colors.map((color, idx) => {
      logger.info(TAG, 'cls ' + idx + ' ac ' + result.strength + ' ' + (typeof result.strength))
      // if() return inactive

      return idx > result.strength ? inactive : activeColor
    })
    logger.info(TAG, 'col' + JSON.stringify(this.strengthBlocks))
  }

  handPwdChange(pwd: string) {
    this.pwd = pwd
    if (pwd) {
      this.check()
    } else {
      this.checkResult = null
      this.strengthBlocks = default_block_colors
    }
  }

  build() {
    Column() {
      TextInput({ text: this.pwd })
        .type(InputType.Password)
        .onChange((v) => {
          this.pwd = v

          if (v) {
            this.check()
          } else {
            this.checkResult = null
          }

        })
      Row() {
        Row() {
          ForEach(this.strengthBlocks, (color: string) => {
            Row() {
            }
            .strengthBlock()
            .margin({ left: 3 })
            .backgroundColor(color)
            .alignSelf(ItemAlign.Center)
          })

        }

        Row() {
          Text(this.checkResult ? mapPasswordStrengthToText(this.checkResult.strength) : '')
            .alignSelf(ItemAlign.Center)
            .textAlign(TextAlign.End)
        }
      }
      .margin({ top: 5 })
      .height(40)
      .justifyContent(FlexAlign.SpaceBetween)
      .width('100%')

      Row() {
        Row() {
          Text('长度 ')
          Text(this.pwd.length + '')
            .fontColor(this.pwd.length > 8 ? contain : notContain)
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

      Column() {
        Text('如何提升密码强度:').width('100%').margin({ top: 30 })

        ForEach(this.tips, (tip: string, index) => {
          Row() {
            Text((index + 1) + '. ').margin({ right: 2 }).fontColor($r('app.color.gray_7')).alignSelf(ItemAlign.Start)
            Text(tip).fontColor($r('app.color.gray_7'))
          }.margin({ top: 10 })
          .width('100%')
        })
      }

    }.height('100%')
    .padding({ left: CommonConstants.PAGE_CONTENT_HORIZONTAL_GAP, right: CommonConstants.PAGE_CONTENT_HORIZONTAL_GAP })
    .margin({ top: 10 })
  }
}