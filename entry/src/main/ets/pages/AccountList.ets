import { AccountInterface } from '../common/interfaces/Account'
import { AccountListModel } from '../model/Account'
import router from '@ohos.router'
import emitter from '@ohos.events.emitter'
import { EventId } from '../common/enums/Event'
import Logger from '../common/utils/Logger'
import promptAction from '@ohos.promptAction'
import { TopNavBar } from '../components/TopNavBar'
import { CommonConstants } from '../common/constants/CommonConstants'
import { AccountViewModel } from '../viewModel/AccountViewModel'
import { AccountBindingViewModel } from '../viewModel/AccountBindingViewModel'

const TAG = '[Account list page]'

@Component
export struct AccountList {
  // @State list: AccountInterface [] = []
  @State list: AccountViewModel[] = AccountListModel.list.map(a => new AccountViewModel(a))
  updateListEventHandle = () => {
    this.list = AccountListModel.list.map(a => new AccountViewModel(a))
  }

  forceUpdateList() {
    this.list = this.list.slice()
  }

  aboutToAppear() {
    AccountListModel.queryAll().catch(() => {

    })
    emitter.on({ eventId: EventId.AccountListUpdate }, this.updateListEventHandle)
  }

  edit(item: AccountInterface) {
    router.pushUrl({
      url: 'pages/Account',
      params: {
        id: item.id
      }
    })
  }

  del(item: AccountInterface) {
    AlertDialog.show({
      title: '删除该账号',
      message: '',
      autoCancel: true,
      alignment: DialogAlignment.Center,
      gridCount: 4,
      offset: { dx: 0, dy: -20 },
      primaryButton: {
        value: '删除',
        fontColor: 'red',
        action: () => {
          Logger.info(TAG, 'user confirm to delete account id=' + item.id)
          AccountListModel.delete(item.id)
            .then(() => {
              Logger.info(TAG, 'account soft delete successful after user confirm, id=' + item.id)
              promptAction.showToast({
                message: '账号删除成功,你可以在回收站恢复'
              })
            })
            .catch(() => {
              promptAction.showToast({
                message: '删除失败',
              })
            })
        }
      },
      secondaryButton: {
        value: '取消',
        action: () => {
          Logger.info('user cancel delete account id=' + item.id)
        }
      },
      cancel: () => {
        Logger.info('user cancel delete account id=' + item.id)
      }
    })
  }

  build() {
    Row() {

      Column() {
        Row() {
          TopNavBar({ title: '账号' }) {
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
                url: 'pages/Account'
              })
            })
          }
        }

        if (!this.list.length) {
          Row() {
            Text('无账号数据').fontColor($r('app.color.gray_7'))
          }.height('100%')
        }
        List({ space: 10 }) {
          ForEach(this.list, (item: AccountViewModel, idx) => {
            ListItem() {
              Column() {
                Column() {
                  Row() {
                    Text(item.data.name)
                      .align(Alignment.Center)
                      .fontColor('#1890ff')
                      .margin({ bottom: 6 })
                    Button() {
                      Row() {
                        Image(item.isAllMasked()
                          ? $r('app.media.eye_open_primary_icon') : $r('app.media.eye_close_primary_icon')).width(18)
                      }

                    }.backgroundColor(Color.Transparent)
                    .margin({ left: 5 })
                    .onClick(() => {
                      item.toggleAllMask()
                      this.forceUpdateList()
                    })

                  }.width('100%')
                  .justifyContent(FlexAlign.SpaceBetween)
                  .align(Alignment.Center)

                  Row() {
                    Text("账号")
                      .margin({ right: 10 })
                    Text(item.getValue('account'))
                      .fontColor($r('app.color.gray_7'))
                      .onClick(() => {
                        item.toggleMask('account')
                        this.forceUpdateList()
                      })
                  }

                  Row() {
                    Text("密码")
                      .margin({ right: 10 })
                    Text(item.getValue('pwd'))
                      .fontColor($r('app.color.gray_7'))
                      .onClick(() => {
                        item.toggleMask('pwd')
                        this.forceUpdateList()
                      })
                  }

                  if (item.data.note) {
                    Row() {
                      Text("备注")
                        .margin({ right: 10 })
                      Text(item.data.note)
                        .fontColor($r('app.color.gray_7'))

                    }
                  }
                  ForEach(item.bindings, (bindingItem: AccountBindingViewModel) => {
                    Row() {
                      Text(bindingItem.typeLabel)
                        .margin({ right: 10 })
                      Text(bindingItem.getValue('bind'))
                        .fontColor($r('app.color.gray_7'))
                        .onClick(() => {
                          bindingItem.toggleMask('bind')
                          this.forceUpdateList()
                        })
                    }
                  })
                }
                .width('100%')
                .padding(10)
                .alignItems(HorizontalAlign.Start)
                // .width('100%')
                .borderRadius(10)
                .backgroundColor(0xFFFFFF)
                .padding(10)
                .shadow({ offsetX: 2, offsetY: 4, color: '#1f000000', radius: 6 })

              }.padding({ left: 10 })
              .onClick(() => {
                Logger.debug(TAG, 'click list col')
              })
            }
            .width('100%')
            .swipeAction({ end: this.SwipeActions(idx) })
            .padding({ right: 10 })
            .onClick(() => {
              Logger.debug(TAG, 'click list')
            })
          })

          if (this.list.length > 3) {
            ListItem() {
              Row() {
                Text('没有更多了').fontSize(12).alignSelf(ItemAlign.Center).fontColor($r('app.color.gray_7'))
              }.margin({ bottom: 100, top: 40 })
              .justifyContent(FlexAlign.Center)
              .width('100%')
            }
          }
        }
        .padding({ top: CommonConstants.PAGE_CONTENT_TOP_GAP })
      }.width('100%')
    }
    .height('100%')
    .width('100%')
    .alignItems(VerticalAlign.Top)
    .backgroundColor($r('app.color.page_bg'))
  }

  @Builder SwipeActions(idx: number) {
    Row() {
      Button({ type: ButtonType.Normal }) {
        Row() {
          Image($r('app.media.delete_red_icon')).width(16).margin({ right: 2 })
          Text('删除').fontColor($r('app.color.error'))
        }

      }
      .onClick(() => {
        this.del(this.list[idx].data)
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
        this.edit(this.list[idx].data)
      })
      .backgroundColor(Color.Transparent)
      .padding(10)
      // .height('100%')
    }.height('100%')
  }
}