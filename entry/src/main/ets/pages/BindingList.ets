import { AccountBinding } from '../common/interfaces/AccountBinding'
import { AccountBindingListModel, AccountBindingListModelCls } from '../model/AccountBinding'
import router from '@ohos.router'
import Logger from '../common/utils/Logger'
import emitter from '@ohos.events.emitter'
import { EventId } from '../common/enums/Event'
import { AccountBindingViewModel } from '../viewModel/AccountBindingViewModel'
import promptAction from '@ohos.promptAction'
import { TopNavBar } from '../components/TopNavBar'

@Component
export struct BindingList {
  @State listModel: AccountBindingListModelCls = AccountBindingListModel
  @State list: AccountBindingViewModel[] = []

  aboutToAppear() {
    Logger.info("BindingList get list" + JSON.stringify(this.listModel.list))
    emitter.on({ eventId: EventId.AccountBindingListUpdate }, () => {
      this.list = AccountBindingListModel.list.map(b => new AccountBindingViewModel(b))
    })
  }

  onPageShow() {
    Logger.info("BindingList onPageShow get list" + JSON.stringify(this.listModel.list))
  }

  deleteBinding(binding: AccountBindingViewModel) {
    AlertDialog.show(
      {
        title: '删除绑定',
        message: AccountBindingListModel.hasBindingAccount(binding.id) ? '有账号使用了该绑定,删除后自动解绑,确认删除吗?' : '确认删除吗?',
        autoCancel: true,
        alignment: DialogAlignment.Center,
        gridCount: 4,
        offset: { dx: 0, dy: -20 },
        primaryButton: {
          value: '删除',
          fontColor: 'red',
          action: () => {
            console.info('Callback when the first button is clicked')
            AccountBindingListModel.delete(binding.id).then(ok => {
              promptAction.showToast({
                message: ok ? '删除成功' : '删除失败,请重试'
              })
            })
          }
        },
        secondaryButton: {
          value: '取消',
          action: () => {
            console.info('Callback when the second button is clicked')
          }
        },
        cancel: () => {
          console.info('Closed callbacks')
        }
      }
    )
  }

  build() {
    Column() {
      Row() {
        TopNavBar({ title: '关联' }) {
          Button() {
            Row() {
              Image($r('app.media.add_white')).width(16).height(16).margin({ right: 5 })
              Text('添加').fontColor(0xffffff)
            }

          }
          .backgroundColor(Color.Transparent)
          .padding(5)

          .onClick(() => {
            router.pushUrl({
              url: 'pages/Binding'
            })
          })
        }
      }
      .margin({ bottom: 25 })

      if (!this.list.length) {
        Row() {
          Text('无关联数据').fontColor($r('app.color.gray_7'))
        }.height('100%')
      }
      List({ space: 10 }) {
        ForEach(this.list, (acItem: AccountBindingViewModel, idx) => {
          ListItem() {
            Row() {
              Text(acItem.typeLabel).margin({ right: 10 })
              Text(acItem.bind).fontColor('#8c8c8c')
            }
            .justifyContent(FlexAlign.Start)
            .alignSelf(ItemAlign.Start)
            .width('100%')
            .borderRadius(10)
            .backgroundColor(0xFFFFFF)
            .padding(10)

          }.swipeAction({ end: this.SwipeActions(idx) })
          .padding({
            left: 10,
            right: 10
          })

        })
        if (this.list.length > 10) {
          ListItem() {
            Row() {
              Text('没有更多了').fontSize(12).alignSelf(ItemAlign.Center).fontColor($r('app.color.gray_7'))
            }.margin({ bottom: 60 })
            .justifyContent(FlexAlign.Center)
            .width('100%')
          }
        }

      }
    }
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }

  @Builder SwipeActions(idx: number) {
    Row() {
      Button({ type: ButtonType.Normal }) {
        Row() {
          Image($r('app.media.delete_red_icon')).width(16).margin({ right: 2 })
          Text('删除')
            .fontColor($r('app.color.error'))
        }

      }
      .onClick(() => {
        this.deleteBinding(this.list[idx])

      })
      .backgroundColor(Color.Transparent)
      .padding(10)
      .height('100%')
      .padding({ left: 10 })
    }

    .height('100%')
  }
}