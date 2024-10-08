import { AccountBindingListModel, AccountBindingModel, bindingOptions } from '../model/AccountBinding'
import promptAction from '@ohos.promptAction'
import router from '@ohos.router'
import { AccountBindingViewModel } from '../viewModel/AccountBindingViewModel'
import { TopNavBar } from '../components/TopNavBar'

@Entry
@Component
struct Binding {
  @State binding: AccountBindingViewModel = new AccountBindingViewModel(AccountBindingModel.emptyData())

  async submit() {
    await AccountBindingListModel.add(this.binding)
    promptAction.showToast({
      message: '添加绑定成功'
    })
    setTimeout(() => {
      router.back()
    }, 1000)
  }

  build() {
    Row() {
      Column() {
        // NavBackBar({ title: '添加绑定' })
        Column() {
          TopNavBar({ title: '添加绑定', back: true }) {

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
          TextInput({ placeholder: '绑定相关账号' })
            .onChange(v => {
              this.binding.bind = v
            })
        }

        Row() {
          Button('添加绑定')
            .width('80%')
            .padding(10)
            .margin({ top: 20 })
            .onClick(() => {
              this.submit()
            })
        }
      }
    }
  }
}