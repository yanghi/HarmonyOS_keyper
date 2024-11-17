import { DEFAULT_GROUP } from '../common/constants/CommonConstants'
import { AccountGroup } from '../common/interfaces/AccountGroup'
import { AccountGroupListModelCls } from '../model/AccountGroup'
import { CustomDialogAddGroup } from './CustomDialogAddGroup'

@Component
export struct AccountGroupSelect {
  @ObjectLink groupModel: AccountGroupListModelCls
  @Watch('onGroupIdChange')
  @Prop groupId: number
  @State editableData: AccountGroup | null = null
  // @State
  private onGroupIdChange() {
    let target = this.groupModel.list.find(it => it.id === this.groupId)
    if (target) {
      this.selected = target
    }
  }

  onChange: (groupId: number) => void = () => {
  }
  dialogController: CustomDialogController | null = new CustomDialogController({
    builder: CustomDialogAddGroup({ editableData: $editableData }),
    autoCancel: true,
    alignment: DialogAlignment.Center,
    offset: { dx: 0, dy: -20 },
    gridCount: 4,
    customStyle: false,
  })

  showAddDialog() {
    this.dialogController && this.dialogController.open()
  }

  aboutToDisappear() {
    this.dialogController = null
  }

  handleSelect(index: number) {
    let gid = this.groupModel.selectOptions[index].id

    this.onChange(gid)
  }

  handleGroupClick(group: AccountGroup) {
    let gid = group.id
    this.selected = group
    this.onChange(gid)
    this.show = false
  }

  @State selected: AccountGroup = DEFAULT_GROUP
  @State show: boolean = false

  build() {
    Flex() {
      // Select(this.groupModel.selectOptions)
      //   .value(this.groupModel.selectOptions.find(it => it.id === this.groupId)?.value as any ?? '')
      //   .alignSelf(ItemAlign.Center)
      //   .width(200)
      //   .onSelect((index) => {
      //     this.handleSelect(index)
      //   })

      Row() {
        Text(this.selected.name)
        Image($r("app.media.arrow_down_filled_black")).width(14).margin({ left: 5 })
      }.padding({
        top: 6,
        bottom: 6,
        left: 12,
        right: 12
      })
      .backgroundColor('#fcfcfc')
      .borderRadius(10)
      .onClick(() => {
        TextPickerDialog.show({
          range: this.groupModel.selectOptions.map(o => o.value as string),
          selected: this.selected ? this.groupModel.selectOptions.findIndex(o => o.id === this.selected.id) : 0,
          onAccept: (value: TextPickerResult) => {
            // 设置select为按下确定按钮时候的选中项index，这样当弹窗再次弹出时显示选中的是上一次确定的选项
            this.handleGroupClick(this.groupModel.selectOptions[value.index]?.group)
            console.info("TextPickerDialog:onAccept()" + JSON.stringify(value))
          },
          onCancel: () => {
            console.info("TextPickerDialog:onCancel()")
          },
          onChange: (value: TextPickerResult) => {
            console.info("TextPickerDialog:onChange()" + JSON.stringify(value))
          }
        })
      })

      Text('新增分组')
        .fontColor($r('app.color.primary'))
        .alignSelf(ItemAlign.Center)
        .onClick(() => {
          this.showAddDialog()

        })
    }
  }
}