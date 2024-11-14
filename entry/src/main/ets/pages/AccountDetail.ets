import { TopNavBar } from '../components/TopNavBar'
import { AccountListModel, AccountModel } from '../model/Account'
import { AccountViewModel } from '../viewModel/AccountViewModel'
import router from '@ohos.router'
import promptAction from '@ohos.promptAction'
import { CommonConstants, DEFAULT_GROUP } from '../common/constants/CommonConstants'
import logger from '../common/utils/Logger'
import { AccountInterface } from '../common/interfaces/Account'
import { AccountBindingViewModel } from '../viewModel/AccountBindingViewModel'


interface AccountDetailParams {
  id: number
}

@Component
struct DescItem {
  @Prop label: string
  @BuilderParam child: () => {}

  getChars() {
    return this.label.split('')
  }

  build() {
    Flex() {
      Row() {
        ForEach(this.getChars(), (char: string) => {
          Text(char)
        })
      }
      .justifyContent(FlexAlign.SpaceBetween)
      .flexShrink(0)
      .width(60)
      .padding({ right: 10 })

      if (this.child) {
        this.child()
      }
    }
    .padding({
      top: 2,
      bottom: 2
    })
  }
}

@Component
struct DescText {
  @Prop text: string

  build() {
    Text(this.text).fontColor('#666666').textAlign(TextAlign.Start).alignSelf(ItemAlign.Center)
  }
}

const TAG = '[AccountDetail]'

@Styles function SectionCard() {
  .borderRadius(10)
  .backgroundColor(Color.White)
  .shadow({ offsetX: 2, offsetY: 4, color: '#1f000000', radius: 6 })
  .padding(10)
  .margin({ bottom: 10 })
}


@Component
struct AccountDetail {
  @ObjectLink account: AccountViewModel

  del() {

  }

  edit() {
    router.pushUrl({
      url: 'pages/Account',
      params: {
        id: this.account.data.id
      }
    })
  }

  @Builder DetailItem(key: keyof AccountInterface) {
    DescItem({ label: this.account.keyLabel(key) }) {
      if (this.account.getValue(key)) {
        DescText({ text: this.account.getValue(key) as any || '' })
          .onClick(() => {
            logger.debug(TAG, 'click prop text ' + key)
            if (this.account.isMaskKey(key)) {
              this.account.toggleMask(key)
            }
          })
          .gesture(
            LongPressGesture({ repeat: false })
              .onAction((event: GestureEvent) => {
                if (event.repeat) return

                this.account.copyProp(key)
              })
          )
      } else {
        DescText({ text: '-' })
      }

    }
  }

  @Builder SectionTitle(title: string) {
    Flex() {
      Text(title).fontColor('#333333').fontSize(18).margin({ bottom: 6 }).fontWeight(FontWeight.Bold)
    }
  }

  build() {
    Column() {
      TopNavBar({ title: '账号详情', back: true }) {
      }

      Column() {
        Column() {
          Row() {
            Text(this.account.data.name)
              .fontColor($r('app.color.primary'))
              .fontSize(20)
              .fontWeight(FontWeight.Bolder)
              .textAlign(TextAlign.Start)

            Row() {
              Button() {
                Row() {
                  Image(this.account.isAllMasked()
                    ? $r('app.media.eye_open_primary_icon') : $r('app.media.eye_close_primary_icon'))
                    .width(18)
                }

              }.backgroundColor(Color.Transparent)
              .margin({ left: 5 })
              .onClick(() => {
                this.account.toggleAllMask()
                logger.debug(TAG, 'tg mask')
                this.account.forceUpdateBindingList()
                // this.forceUpdateList()
              })

            }
          }.margin({ bottom: 3 })
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)

          Row() {
            Text(this.account.data.group?.name || DEFAULT_GROUP.name)
              .backgroundColor($r('app.color.info'))
              .borderRadius(20)
              .height(24)
              .padding({ left: 9, right: 9 })
              .fontColor('white')
              .fontSize(14)
          }.width('100%')
          .margin({ bottom: 3 })

          .justifyContent(FlexAlign.Start)

          Text('创建于 ' + this.account.data.createTime)
            .fontSize(12).fontColor($r('app.color.gray_7'))
            .width('100%')

          Text('更新于 ' + this.account.data.updateTime)
            .fontSize(12).fontColor($r('app.color.gray_7'))
            .width('100%')

        }
        .margin({ bottom: 10 }).width('100%')
        .justifyContent(FlexAlign.Start)

        this.SectionTitle('基本信息')
        // .padding({ left: CommonConstants.PAGE_CONTENT_HORIZONTAL_GAP })

        Column() {

          this.DetailItem('account')
          this.DetailItem('pwd')

          ForEach(this.account.bindings, (binding: AccountBindingViewModel) => {
            DescItem({ label: binding.typeLabel + '' }) {
              DescText({ text: binding.getValue('bind') })
                .onClick(() => {
                  binding.toggleMask('bind')
                  this.account.forceUpdateBindingList()
                })
                .gesture(
                  LongPressGesture({ repeat: false })
                    .onAction((event: GestureEvent) => {

                      if (event.repeat) return

                      binding.copyBind()
                    })
                )
            }
          })
        }.SectionCard()

        this.SectionTitle('其他信息')

        Column() {
          this.DetailItem('userName')
          this.DetailItem('nickName')
          this.DetailItem('note')
        }
        .SectionCard()
      }
      .padding({
        top: 15,
        left: CommonConstants.PAGE_CONTENT_HORIZONTAL_GAP,
        right: CommonConstants.PAGE_CONTENT_HORIZONTAL_GAP
      })
      // .backgroundColor('red')
      .flexGrow(5)
    }
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }
}

@Entry
@Component
struct AccountDetailEntry {
  @State account: AccountViewModel = new AccountViewModel(AccountModel.emptyData())
  // @State account: AccountViewModel = new AccountViewModel(AccountListModel.list[0])

  onPageShow() {
    let ps = router.getParams() as AccountDetailParams | undefined
    if (ps) {
      if (!ps.id) {
        logger.debug(TAG, 'invalid route params')
        return
      }
      let target = AccountListModel.list.find(t => t.id === ps.id)
      if (!target) {
        promptAction.showToast({
          message: '该账号已被删除'
        })
        setTimeout(() => {
          router.back()
        }, 3000)
        return
      }

      this.account = new AccountViewModel(target)
    }
  }

  build() {
    Column() {
      AccountDetail({
        account: this.account
      })
    }.height('100%')
  }
}