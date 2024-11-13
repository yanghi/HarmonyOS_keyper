import promptAction from '@ohos.promptAction'
import { AccountGroup } from '../common/interfaces/AccountGroup'
import logger from '../common/utils/Logger'
import { AccountGroupListModel } from '../model/AccountGroup'

const noop = () => {
}
const TAG = '[CustomDialogAddGroup]'

@CustomDialog
export struct CustomDialogAddGroup {
  controller?: CustomDialogController
  cancel: () => void = () => {
  }
  confirm: () => void = () => {

  }
  onAddNew: (group: AccountGroup) => void = noop

  add() {
    return AccountGroupListModel.add({
      name: this.textValue
    }).then(added => {
      this.onAddNew(added)
      promptAction.showToast({
        message: '创建成功'
      })
    }).catch(e => {
      promptAction.showToast({
        message: '创建失败'
      })
    })
  }

  update() {
    return AccountGroupListModel.update({
      ...this.editableData,
      name: this.textValue
    }).then(() => {
      promptAction.showToast({
        message: '修改成功'
      })
    }).catch(e => {
      promptAction.showToast({
        message: '修改失败'
      })
    })
  }

  async submit() {
    if (!this.textValue) {
      promptAction.showToast({
        message: '请输入分组名称'
      })
      return
    }
    if (this.editableData) {
      await this.update()
    } else {
      await this.add()
    }


    if (this.controller != undefined) {
      this.controller.close()
      this.confirm()
    }

  }

  @State textValue: string = ''
  @Link
  @Watch('onEditableDataChange')
  editableData: AccountGroup | null

  onEditableDataChange() {
    this.textValue = this.editableData ? this.editableData.name : ''
  }

  aboutToAppear() {
    logger.debug(TAG, 'aboutToAppear, editableData: ' + JSON.stringify(this.editableData))
    this.textValue = this.editableData ? this.editableData.name : ''
  }

  build() {
    Column() {
      Text(this.editableData ? '修改分组' : '添加分组')
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
        Button('确定')
          .onClick(() => {

            this.submit()
          }).backgroundColor(0xffffff).fontColor($r('app.color.primary'))
      }.margin({ bottom: 10, top: 10 })
    }
  }
}
