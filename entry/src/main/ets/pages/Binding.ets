import { AccountBindingListModel, AccountBindingModel, bindingOptions } from '../model/AccountBinding'
import promptAction from '@ohos.promptAction'
import router from '@ohos.router'
import { AccountBindingViewModel } from '../viewModel/AccountBindingViewModel'
import { TopNavBar } from '../components/TopNavBar'
import logger from '../common/utils/Logger'
import { BaseLayout } from '../components/BaseLayout'

interface BindingParams {
  id?: number
}

const TAG = '[BindingEntry]'

@Entry
@Component
struct Binding {
  @State binding: AccountBindingViewModel = new AccountBindingViewModel(AccountBindingModel.emptyData())
  @State isEdit: boolean = false

  handleEditParams(ps) {
    if (!ps.id) {
      this.isEdit = false
      return
    }
    let target = AccountBindingListModel.list.find(a => a.id === ps.id)
    if (!target) {
      this.isEdit = false
      logger.error(TAG, 'cannot find by route params.id=' + ps.id)
      return
    }

    this.isEdit = true
    this.binding = new AccountBindingViewModel(target)
  }

  onPageShow() {
    let ps = router.getParams() as BindingParams | undefined
    if (ps) {
      this.handleEditParams(ps)
    } else {
      this.isEdit = false
    }
  }

  update() {
    return AccountBindingListModel.update(this.binding).then(() => {
      promptAction.showToast({
        message: '修改成功'
      })
      setTimeout(() => {
        router.back()
      }, 1000)
    }).catch(() => {
      promptAction.showToast({
        message: '修改失败'
      })
    })
  }

  add() {
    return AccountBindingListModel.add(this.binding).then(() => {
      promptAction.showToast({
        message: '添加成功'
      })
      setTimeout(() => {
        router.back()
      }, 1000)
    }).catch(() => {
      promptAction.showToast({
        message: '添加失败'
      })
    })
  }

  async submit() {
    if (this.isEdit) {
      await  this.update()
    } else {
      await  this.add()
    }
  }

  build() {
    Column() {
      BaseLayout() {
        // NavBackBar({ title: '添加绑定' })
        Column() {
          TopNavBar({ title: this.isEdit ? '编辑关联' : '添加关联', back: true }) {

          }
        }.padding({ bottom: 15 })

        Flex() {
          Text()

          Select(bindingOptions)
            .value(this.binding.typeLabel)
            .onSelect((idx, v) => {
              this.binding.setTypeLabel(v)
            })
            .alignSelf(ItemAlign.Center)
            .margin({ right: 15 })
          TextInput({ placeholder: '关联相关账号', text: this.binding.bind })
            .onChange(v => {
              this.binding.bind = v
            })
        }

        Row() {
          Button('保存')
            .width('80%')
            .padding(10)
            .margin({ top: 20 })
            .onClick(() => {
              this.submit()
            })
        }
      }
    }.height('100%')
  }
}