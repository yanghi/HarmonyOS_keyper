import { AccountGroupListModelCls } from '../model/AccountGroup'
import { CustomDialogAddGroup } from './CustomDialogAddGroup'

@Component
export struct AccountGroupSelect {
  @ObjectLink groupModel: AccountGroupListModelCls
  @Prop groupId: number

  // @State
  onChange: (groupId: number) => void = () => {
  }
  dialogController: CustomDialogController | null = new CustomDialogController({
    builder: CustomDialogAddGroup({}),
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

  build() {
    Flex() {
      Select(this.groupModel.selectOptions)
        .value(this.groupModel.selectOptions.find(it => it.id === this.groupId)?.value as any ?? '')
        .alignSelf(ItemAlign.Center)
        .width(200)
        .onSelect((index) => {
          this.handleSelect(index)
        })
      Text('创建分组')
        .fontColor($r('app.color.primary'))
        .onClick(() => {
          this.showAddDialog()
        })
        .alignSelf(ItemAlign.Center)
    }
  }
}