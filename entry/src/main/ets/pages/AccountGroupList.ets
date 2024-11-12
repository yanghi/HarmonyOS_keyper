import { AccountGroup } from '../common/interfaces/AccountGroup'
import { TopNavBar } from '../components/TopNavBar'
import { AccountGroupListModel, AccountGroupListModelCls } from '../model/AccountGroup'
import promptAction from '@ohos.promptAction'
import { CommonConstants } from '../common/constants/CommonConstants'
import { CustomDialogAddGroup } from '../components/CustomDialogAddGroup'

@Component
struct AccountGroupList {
  @ObjectLink listModel: AccountGroupListModelCls
  dialogController: CustomDialogController | null = new CustomDialogController({
    builder: CustomDialogAddGroup({}),
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

  }

  add() {
    this.dialogController.open()
  }

  build() {
    Column() {
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
            top: CommonConstants.PAGE_CONTENT_TOP_GAP
          })
          .swipeAction({ end: this.buildSwipeAction(idx) })
        })
      }
    }
    .backgroundColor($r('app.color.page_bg'))
    .height('100%')
  }

  @Builder buildSwipeAction(idx: number) {
    Row() {
      Button({ type: ButtonType.Normal }) {
        Row() {
          Image($r('app.media.delete_red_icon')).width(16).margin({ right: 2 })
          Text('删除')
            .fontColor($r('app.color.error'))
        }

      }
      .onClick(() => {
        this.del(this.listModel.list[idx])
      })
      .backgroundColor(Color.Transparent)
      .padding(10)
      .height('100%')
      .padding({ left: 10 })

      // Button({ type: ButtonType.Normal }) {
      //   Row() {
      //     Image($r('app.media.edit_primary_icon')).width(16).margin({ right: 2 })
      //     Text('编辑')
      //       .fontColor($r('app.color.primary'))
      //   }
      //
      // }
      // .onClick(() => {
      //   this.edit(this.listModel.list[idx])
      // })
      // .backgroundColor(Color.Transparent)
      // .padding(10)
    }.height('100%')
  }
}

@Entry
@Component
struct AccountGroupListEntry {
  listModel = AccountGroupListModel

  build() {
    Column() {
      AccountGroupList({
        listModel: this.listModel
      })
    }
    .height('100%')

  }
}