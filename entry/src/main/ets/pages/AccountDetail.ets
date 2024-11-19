import { TopNavBar } from '../components/TopNavBar'
import { AccountListModel, AccountModel } from '../model/Account'
import { AccountViewModel } from '../viewModel/AccountViewModel'
import router from '@ohos.router'
import promptAction from '@ohos.promptAction'
import { CommonConstants, DEFAULT_GROUP } from '../common/constants/CommonConstants'
import logger from '../common/utils/Logger'
import { AccountInterface } from '../common/interfaces/Account'
import { AccountBindingViewModel } from '../viewModel/AccountBindingViewModel'
import { requestDeleteAccount } from '../common/utils/Actions'
import { DescItem } from '../components/DescItem'
import { SelectionModel } from '../model/Selection'
import { ConverterModel } from '../model/ConverterModel'
import pasteboard from '@ohos.pasteboard'
import { stringifyError } from '../common/utils/common'
import { BaseLayout } from '../components/BaseLayout'


interface AccountDetailParams {
  id: number
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
  @ObjectLink @Watch('onAccountChange') account: AccountViewModel

  onAccountChange() {
    logger.debug(TAG, 'set cp keys')
    this.copyMenuOptions = this.account.copyableKeys().map(k => ({
      id: k,
      text: this.account.keyLabel(k)
    }))
  }

  del() {
    requestDeleteAccount(this.account.data).then(() => {
      router.back()
    }).catch(() => {

    })
  }

  aboutToAppear() {
    logger.debug(TAG, 'aboutToAppear')
    this.onAccountChange()
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

  @State copyMenuOptions: Array<{
    id: string,
    text: string
  }> = []
  @ObjectLink copyKeysSelection: SelectionModel

  // mcc: any
  mcc = new CustomDialogController({

    builder: () => {
      this.MultiCopyDialogContent()
    },
    // cancel: ()=>{},
    autoCancel: true,
    alignment: DialogAlignment.Center,
    offset: { dx: 0, dy: -20 },
    gridCount: 4,
    customStyle: false
  })

  @Builder MultiCopyDialogContent() {
    Column() {
      Row() {
        Text('自由复制').fontSize(20).margin({ top: 10, bottom: 10 })
      }

      ForEach(this.copyMenuOptions, (item) => {
        Row() {
          Text(item.text).width(80)

          Checkbox() {
          }
          .select(this.copyKeysSelection.isSelected(item.id))
          .onClick(() => {
            this.copyKeysSelection.toggle(item.id)
          }).margin({ left: 20 })
        }.margin({ bottom: 10 })

      })
      Flex({ justifyContent: FlexAlign.SpaceAround }) {
        Button() {
          Row() {
            Text('取消')
          }
        }.onClick(() => {
          this.mcc.close()
        })
        .margin({ right: 10 })
        .backgroundColor(0xffffff)

        Button() {
          Row() {
            Text('复制').fontColor($r('app.color.primary'))
          }
        }.backgroundColor(0xffffff)
        .onClick(() => {
          if (!this.copyKeysSelection.selected.length) {
            promptAction.showToast({
              message: '请选择至少一项进行复制'
            })
            return
          }

          let str = ConverterModel.propsToString(this.account.data, this.copyKeysSelection.selected as any)
          logger.info(TAG, 'multi copy keys ' + JSON.stringify(this.copyKeysSelection.selected))
          let pasteboardData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, str)

          const sysPasteboard = pasteboard.getSystemPasteboard()
          sysPasteboard.setData(pasteboardData).then(() => {
            promptAction.showToast({
              message: `已复制到剪切板`
            })
          }).catch(e => {
            logger.error(TAG, 'paste data failed,' + stringifyError(e))
          })

          this.mcc.close()
        })
      }
      .margin({ top: 10, bottom: 10 })
    }
  }

  @Builder MenuItemBuilder(opt: {
    text: string,
    fontColor?: string | Resource
  }) {
    Row() {
      Text(opt.text).fontColor(opt.fontColor)
    }
  }

  @Builder CopyMenuBuilder() {
    Menu() {
      ForEach(this.copyMenuOptions, (item) => {
        MenuItem({
          content: item.text
        }).onClick(() => {
          // this.account.
          logger.debug(TAG, 'cp ' + item.id)
          this.account.copyProp(item.id)
        })
      })

      MenuItem({
        content: '自由复制',
      })
        .onClick(() => {
          this.mcc.open()
        })
    }

  }

  build() {
    Column() {
      TopNavBar({ title: '账号详情', back: true }) {
      }

      Column() {
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
        .flexGrow(6)
        .padding({
          top: 15,
          left: CommonConstants.PAGE_CONTENT_HORIZONTAL_GAP,
          right: CommonConstants.PAGE_CONTENT_HORIZONTAL_GAP
        })

        // fixed bottom bar
        Row() {
          Button() {
            Row() {
              Image(this.account.isAllMasked()
                ? $r('app.media.eye_open_primary_icon') : $r('app.media.eye_close_primary_icon'))
                .width(18).margin({ right: 2 })
              Text(this.account.isAllMasked() ? '显示' : '隐藏').fontColor($r('app.color.primary'))
            }

          }.backgroundColor(Color.Transparent)
          .margin({ left: 5 })
          .onClick(() => {
            this.account.toggleAllMask()
            logger.debug(TAG, 'tg mask')
            this.account.forceUpdateBindingList()
            // this.forceUpdateList()
          })

          Button({ type: ButtonType.Normal }) {
            Row() {
              Image($r('app.media.delete_red_icon')).width(16).margin({ right: 2 })
              Text('删除').fontColor($r('app.color.error'))
            }
          }
          .onClick(() => {
            this.del()
          })
          .backgroundColor(Color.Transparent)

          .padding(10)


          Button({ type: ButtonType.Normal }) {
            Row() {
              Image($r('app.media.edit_primary_icon')).width(16).margin({ right: 2 })
              Text('编辑')
                .fontColor($r('app.color.primary'))
            }
          }
          .onClick(() => {
            this.edit()
          })
          .backgroundColor(Color.Transparent)
          .padding(10)

          if (this.copyMenuOptions.length) {
            Button({ type: ButtonType.Normal }) {
              Row() {
                Image($r('app.media.copy_primary')).width(16).margin({ right: 2 })
                Text('复制')
                  .fontColor($r('app.color.primary'))
              }
            }
            .bindMenu(this.CopyMenuBuilder)
            .backgroundColor(Color.Transparent)
            .padding(10)
          } else {
            Button({ type: ButtonType.Normal }) {
              Row() {
                Image($r('app.media.copy_gray')).width(16).margin({ right: 2 })
                Text('复制')
                  .fontColor('#bfbfbf')
              }
            }
            .onClick(() => {
              promptAction.showToast({
                message: '没有可以复制的内容'
              })
            })
            .backgroundColor(Color.Transparent)
            .padding(10)
          }


        }
        .height(50)
        .width('100%')
        .backgroundColor(Color.White)
        .justifyContent(FlexAlign.SpaceAround)
        .borderRadius({
          topLeft: 5,
          topRight: 5
        })
      }

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
  @State multiCopyKeysSelection: SelectionModel<keyof AccountInterface> = new SelectionModel<keyof AccountInterface>()

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
      BaseLayout() {
        AccountDetail({
          account: this.account,
          copyKeysSelection: this.multiCopyKeysSelection
        })
      }
    }.height('100%')
  }
}