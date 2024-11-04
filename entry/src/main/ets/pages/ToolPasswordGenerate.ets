import { logger } from '../common/utils/Logger'
import { TopNavBar } from '../components/TopNavBar'
import { DigitType, PasswordGenerator } from '../model/PasswordGenrator'
import pasteboard from '@ohos.pasteboard'
import promptAction from '@ohos.promptAction'
import { stringifyError } from '../common/utils/common'
import { NumberRange } from '../components/NumberRange'

interface DigitState {
  use: boolean
  required: boolean
}

const CheckboxGap = 10

const TAG = '[PasswordGenerate]'

@Component
export struct ToolPasswordGenerate {
  @State useNumeric: DigitState = {
    use: true,
    required: false
  }
  @State useUpperAlpha: DigitState = {
    use: true,
    required: false
  }
  @State useLowerAlpha: DigitState = {
    use: true,
    required: false
  }
  @State usePunctuation: DigitState = {
    use: true,
    required: false
  }
  @State generatedPasswordList: string[] = []
  @State fixedLength: number = 12
  @State useRandLength: boolean = true
  generateAmount: number = 5

  copyToPasteboard(val: string) {
    let pasteboardData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, val)

    const sysPasteboard = pasteboard.getSystemPasteboard()
    sysPasteboard.setData(pasteboardData).then(() => {
      promptAction.showToast({
        message: '已复制到剪切板'
      })
    }).catch(e => {
      logger.error(TAG, 'paste data failed,' + stringifyError(e))
    })
  }

  generate() {
    // if(1){
    //   logger.debug(TAG, 'len ' + JSON.stringify(this.length))
    //   return
    // }
    let digits = []
    if (this.useUpperAlpha.use) {
      digits.push({
        type: DigitType.UpperAlpha,
        required: this.useUpperAlpha.required
      })
    }
    if (this.useLowerAlpha) {
      digits.push({
        type: DigitType.LowerAlpha,
        required: this.useLowerAlpha.required
      })
    }

    if (this.useLowerAlpha) {
      digits.push({
        type: DigitType.Punctuation,
        required: this.useLowerAlpha.required
      })
    }
    if (this.useNumeric.use) {
      digits.push({
        type: DigitType.Numeric,
        required: this.useNumeric.required
      })
    }

    logger.debug('pwd', JSON.stringify(digits))

    let lengthData = this.useRandLength ? undefined : [this.fixedLength, this.fixedLength] as any
    let result = new PasswordGenerator({
      digit: digits,
      length: lengthData
    }).generateMultiple(this.generateAmount)
    this.generatedPasswordList = result
  }

  @Builder buildResult() {
    Column() {

      Row() {
        Text('生成结果')
      }.margin({ top: 20, bottom: 15 })

      List() {
        ForEach(this.generatedPasswordList, (pwd: string) => {
          ListItem() {
            Row() {
              Text(pwd)
              Text('复制').fontColor($r('app.color.primary')).onClick(() => {
                this.copyToPasteboard(pwd)
              })
                .margin({ left: 10 })
            }.margin({ bottom: 10 })
            .justifyContent(FlexAlign.Center)
          }
          .width('100%')

        })
      }.height(200)

    }
  }

  build() {
    Column() {
      Column() {
        Row() {
          Text('长度')
          Toggle({
            type: ToggleType.Switch,
            isOn: this.useRandLength
          })
            .onChange((isOn) => {
              this.useRandLength = isOn
            })
          Text('随机')

          if (!this.useRandLength) {
            NumberRange({
              value: 12,
              max: 32,
              onChange: (val) => {
                this.fixedLength = val
              }
            })
          }
        }.width('100%')

        Row() {
          Text('生成集')

        }.width('100%')

        Flex() {
          Row() {
            Checkbox({ name: '数字', group: 'checkboxGroup' })
              .selectedColor('#007DFF')
              .select(this.useNumeric.use)
              .onChange((value: boolean) => {
                this.useNumeric.use = value
              })
              .margin({ right: 5 })
            Text('数字')
          }
          .margin({ right: CheckboxGap })

          Row() {
            Checkbox({ name: '大写字母', group: 'checkboxGroup' })
              .selectedColor('#007DFF')
              .select(this.useUpperAlpha.use)
              .onChange((value: boolean) => {
                this.useUpperAlpha.use = value
              })
              .margin({ right: 5 })
            Text('大写字母')
          }
          .margin({ right: CheckboxGap })

          Row() {
            Checkbox({ name: '小写字母', group: 'checkboxGroup' })
              .selectedColor('#007DFF')
              .select(this.useLowerAlpha.use)
              .onChange((value: boolean) => {
                this.useLowerAlpha.use = value
              })
              .margin({ right: 5 })

            Text('小写字母')
          }
          .margin({ right: CheckboxGap })


          Row() {
            Checkbox({ name: '标点符号', group: 'checkboxGroup' })
              .selectedColor('#007DFF')
              .select(this.usePunctuation.use)
              .onChange((value: boolean) => {
                this.usePunctuation.use = value
              })
              .margin({ right: 5 })

            Text('标点符号')
          }
        }
        .width('100%')
        .margin({ top: 10, bottom: 10 })

        Row() {
          Text('必须包含')
        }.width('100%')

        Flex() {
          Row() {
            Checkbox({ name: '数字', group: 'checkboxGroup' })
              .selectedColor('#007DFF')
              .select(this.useNumeric.required)
              .onChange((value: boolean) => {
                this.useNumeric.required = value
              })
              .margin({ right: 5 })

            Text('数字')
          }
          .margin({ right: CheckboxGap })

          Row() {
            Checkbox({ name: '大写字母', group: 'checkboxGroup' })
              .selectedColor('#007DFF')
              .select(this.useUpperAlpha.required)
              .onChange((value: boolean) => {
                this.useUpperAlpha.required = value
              })
              .margin({ right: 5 })
            Text('大写字母')
          }
          .margin({ right: CheckboxGap })

          Row() {
            Checkbox({ name: '小写字母', group: 'digitRequired' })
              .selectedColor('#007DFF')
              .select(this.useLowerAlpha.required)
              .onChange((value: boolean) => {
                this.useLowerAlpha.required = value
              })
              .margin({ right: 5 })

            Text('小写字母')
          }
          .margin({ right: CheckboxGap })

          Row() {
            Checkbox({ name: '标点符号', group: 'digitRequired' })
              .selectedColor('#007DFF')
              .select(this.usePunctuation.required)
              .onChange((value: boolean) => {
                this.usePunctuation.required = value
              })
              .margin({ right: 5 })

            Text('标点符号')
          }
        }
        .width('100%')
        .margin({ top: 10, bottom: 10 })

        Row() {
          Text('生成数量')
        }.width('100%')

        NumberRange({ value: this.generateAmount,
          max: 20,
          onChange: (v) => {
            this.generateAmount = v
          } })
          .margin({ top: 10, bottom: 10 })

        Button() {
          Row() {
            Text(this.generatedPasswordList.length ? '重新生成' : '生成').fontColor(Color.White)
          }
        }.onClick(() => {
          this.generate()
        })
        .width('60%')
        .padding(10)
        .margin({ top: 30 })
      }
      .padding(10)

      this.buildResult()
    }.height('100%')
  }
}