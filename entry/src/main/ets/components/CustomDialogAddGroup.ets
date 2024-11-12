import promptAction from '@ohos.promptAction'
import { AccountGroupListModel } from '../model/AccountGroup'

@CustomDialog
export struct CustomDialogAddGroup {
  controller?: CustomDialogController
  cancel: () => void = () => {
  }
  confirm: () => void = () => {

  }

  handleConfirm() {
    if (!this.textValue) {
      promptAction.showToast({
        message: '请输入分组名称'
      })
      return
    }
    AccountGroupListModel.add({
      name: this.textValue
    })

    if (this.controller != undefined) {
      this.controller.close()
      this.confirm()
    }

  }

  @State textValue: string = ''
  @State edit: boolean = false

  build() {
    Column() {
      Text(this.edit ? '修改' : '添加分组')
        .fontSize(20)
        .margin({ top: 10, bottom: 10 })
      TextInput({ placeholder: '', text: this.textValue }).width('90%')
        .onChange((value: string) => {
          this.textValue = value
        })
      Flex({ justifyContent: FlexAlign.SpaceAround }) {
        Button('取消')
          .onClick(() => {
            if (this.controller != undefined) {
              this.controller.close()
              this.cancel()
            }
          }).backgroundColor(0xffffff).fontColor(Color.Black)
        Divider().vertical(true).width(1).height(24).alignSelf(ItemAlign.Center)
        Button('确定')
          .onClick(() => {

            this.handleConfirm()
          }).backgroundColor(0xffffff).fontColor(Color.Red)
      }.margin({ bottom: 10, top: 10 })
    }
  }
}
