import { AccountGroup } from '../common/interfaces/AccountGroup'
import { TopNavBar } from '../components/TopNavBar'
import { AccountGroupListModel, AccountGroupListModelCls } from '../model/AccountGroup'
import promptAction from '@ohos.promptAction'
import { CommonConstants } from '../common/constants/CommonConstants'
import { CustomDialogAddGroup } from '../components/CustomDialogAddGroup'
import logger from '../common/utils/Logger'
import { BaseLayout } from '../components/BaseLayout'
import { CircleButton } from '../components/CircleButton'

const TAG = '[AccountGroupList]'

const SWIPE_ACTION_BTN_SIZE = 30

@Component
struct AccountGroupList {
  @ObjectLink listModel: AccountGroupListModelCls
  @State editableGroup: AccountGroup | null = null
  dialogController: CustomDialogController | null = new CustomDialogController({
    builder: CustomDialogAddGroup({
      // textValue: this.editableGroup ? this.editableGroup.name : '',
      editableData: $editableGroup
    }),
    autoCancel: true,
    alignment: DialogAlignment.Center,
    offset: { dx: 0, dy: -20 },
    gridCount: 4,
    customStyle: false,
  })

  del(group: AccountGroup) {
    this.listModel.delete(group.id).then(() => {
      promptAction.showToast({
        message: '删除成功'
      })
    }).catch(() => {
      promptAction.showToast({
        message: '删除失败'
      })
    })
  }

  edit(group: AccountGroup) {
    this.editableGroup = group
    logger.debug(TAG, 'edit ' + JSON.stringify(group))
    // this.editDialogController = this.createDialogController()
    this.dialogController.open()
  }

  add() {
    this.dialogController.open()
  }

  build() {
    Column() {

      BaseLayout() {
        TopNavBar({ title: '分组管理', back: true }) {
          Button() {
            Row() {
              Image($r('app.media.add_white')).width(16).height(16).margin({ right: 5 })
              Text('添加').fontColor(0xffffff)
            }

          }
          .backgroundColor(Color.Transparent)
          .padding(5)

          .onClick(() => {
            this.add()
          })
        }

        List({ space: 10 }) {
          ForEach(this.listModel.list, (item: AccountGroup, idx) => {
            ListItem() {
              Row() {
                Text(item.name)
              }
              .justifyContent(FlexAlign.Start)
              .alignSelf(ItemAlign.Start)
              .width('100%')
              .borderRadius(10)
              .backgroundColor(0xFFFFFF)
              .padding(10)
            }
            .padding({
              left: CommonConstants.PAGE_CONTENT_HORIZONTAL_GAP,
              right: CommonConstants.PAGE_CONTENT_HORIZONTAL_GAP,
            })
            .swipeAction({ end: this.buildSwipeAction(idx) })
          })
        }.padding({
          top: CommonConstants.PAGE_CONTENT_TOP_GAP
        })
      }
    }

    .backgroundColor($r('app.color.page_bg'))
    .height('100%')
  }

  @Builder buildSwipeAction(idx: number) {
    Row() {
      CircleButton({
        buttonColor: $r('app.color.error'),
        icon: $r('app.media.delete_white'),
        circleSize: SWIPE_ACTION_BTN_SIZE,
        onButtonClick: () => {
          this.del(this.listModel.list[idx])
        }
      }).margin({ right: 10 })

      CircleButton({
        buttonColor: $r('app.color.warn'),
        icon: $r('app.media.edit_white'),
        circleSize: SWIPE_ACTION_BTN_SIZE,
        onButtonClick: () => {
          this.edit(this.listModel.list[idx])
        }
      }).margin({ right: 10 })
    }.height('100%').padding({
      left: 10,
    })
  }
}

@Entry
@Component
struct AccountGroupListEntry {
  listModel = AccountGroupListModel

  build() {
    Column() {

      BaseLayout() {
        AccountGroupList({
          listModel: this.listModel
        })
      }
    }
    .height('100%')
  }
}