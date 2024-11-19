import { AccountInterface } from '../common/interfaces/Account'
import { TopNavBar } from '../components/TopNavBar'
import { AccountListModel } from '../model/Account'
import emitter from '@ohos.events.emitter'
import { EventId } from '../common/enums/Event'
import logger from '../common/utils/Logger'
import { CommonConstants } from '../common/constants/CommonConstants'
import promptAction from '@ohos.promptAction'
import { BaseLayout } from '../components/BaseLayout'

const TAG = '[RecycleBin]'

@Entry
@Component
struct RecycleBin {
  @State list: AccountInterface[] = AccountListModel.deletedList

  aboutToAppear() {
    AccountListModel.queryAllDeleted().catch(() => {

    })
    emitter.on({ eventId: EventId.AccountDeletedListUpdate }, () => {
      this.list = AccountListModel.deletedList?.slice() || []
    })
  }

  handleHardDelete(acc: AccountInterface) {
    AccountListModel.hardDelete(acc.id).catch(() => {

    })
  }

  handleRestore(acc: AccountInterface) {
    AccountListModel.restore(acc.id).catch(() => {

    })
  }

  handleHardDeleteAll() {
    AlertDialog.show({
      title: '清空回收站',
      message: '清空回收站,该操作不可恢复',
      autoCancel: true,
      alignment: DialogAlignment.Center,
      gridCount: 4,
      offset: { dx: 0, dy: -20 },
      primaryButton: {
        value: '清空',
        fontColor: 'red',
        action: () => {
          logger.info(TAG, 'user confirm to clear all bin data')
          AccountListModel.hardDeleteAll().catch(() => {
            promptAction.showToast({
              message: '清空失败'
            })
          })
        }
      },
      secondaryButton: {
        value: '取消',
        action: () => {

        }
      },
      cancel: () => {

      }
    })

  }

  build() {
    Column() {
      BaseLayout() {

        Column() {
          TopNavBar({ title: '回收站', back: true }) {
            Row() {
              Button() {
                Row() {
                  Image($r('app.media.trash_white_icon')).width(14).margin({ right: 2 })
                  Text('清空').fontColor(Color.White)
                }.padding(4)
              }.backgroundColor(Color.Transparent)
              .onClick(() => {
                this.handleHardDeleteAll()
              })
            }
          }
        }

        Column() {
          if (!this.list.length) {
            Row() {
              Text('无数据').fontColor($r('app.color.gray_7'))
            }.height('100%')
          }

          List({ space: 10 }) {
            ForEach(this.list, (acc: AccountInterface, idx) => {
              ListItem() {
                Column() {
                  Row() {
                    Text(acc.name)
                  }
                  .borderRadius(10)
                  .backgroundColor(0xFFFFFF)
                  .padding(10)
                  .width('100%')
                  .shadow({ offsetX: 2, offsetY: 4, color: '#1f000000', radius: 6 })
                  .margin({ right: 10 })
                }
              }
              .padding({ left: 10 })
              .swipeAction({ end: this.ItemSwipeEnd(acc) })
            })
          }
        }
        .padding({ top: CommonConstants.PAGE_CONTENT_TOP_GAP })
      }

    }
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }

  @Builder ItemSwipeEnd(acc: AccountInterface) {
    Row() {
      Button() {
        Row() {
          Image($r('app.media.delete_red_icon')).width(16).margin({ right: 2 })
          Text('彻底删除').fontColor($r('app.color.error'))
        }

      }
      .backgroundColor(Color.Transparent)
      .onClick(() => {
        this.handleHardDelete(acc)
      })

      Button() {
        Row() {
          Image($r('app.media.resotre_primary_icon')).width(16).margin({ right: 2 })

          Text('恢复').fontColor($r('app.color.primary'))
        }

      }
      .backgroundColor(Color.Transparent)
      .onClick(() => {
        this.handleRestore(acc)
      }).margin({ left: 10 })
    }
    .padding(10)
  }
}