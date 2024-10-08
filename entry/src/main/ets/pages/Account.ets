import router from '@ohos.router'
import { AccountBindingModel, bindingOptions } from '../model/AccountBinding'
import { AccountListModel, AccountModel, BindingContactAction } from '../model/Account'
import { AccountInterface } from '../common/interfaces/Account'
import { AccountBindingViewModel } from '../viewModel/AccountBindingViewModel'
import promptAction from '@ohos.promptAction'
import Logger from '../common/utils/Logger'
import { isValidateIntId } from '../common/utils/common'
import { TopNavBar } from '../components/TopNavBar'

interface BackBarOptions {
  title?: string
}

interface AccountParams {
  id?: number
}

const TAG = '[AccountEntry]'

@Entry
@Component
struct AccountEntry {
  @State account: AccountInterface = AccountModel.emptyData()
  @State labelBindings: AccountBindingViewModel[] = [
    new AccountBindingViewModel(AccountBindingModel.emptyData())]

  foreUpdateLabelBindings() {
    this.labelBindings = this.labelBindings.concat()
  }

  onPageShow() {
    let ps = router.getParams() as AccountParams | undefined
    if (ps) {
      if (ps.id) {
        let editData = AccountListModel.list.find(a => a.id === ps.id)
        if (editData) {
          this.account = { ...editData }
          Logger.debug(TAG, 'edit data: ' + JSON.stringify(editData))
          this.labelBindings = editData.bindings.map(b => new AccountBindingViewModel(b))
        }
      }
    }
  }

  async create() {
    Logger.info(TAG, 'create submit')

    const bindings = this.labelBindings.map(lb => lb.value())
    Logger.debug(TAG, 'create bindings ' + JSON.stringify(bindings))

    await AccountListModel.add({
      ...this.account,
      bindings
    }).then(added => {
      promptAction.showToast({
        message: "账号添加成功"
      })
      setTimeout(() => {
        router.back()
      }, 1000)
    }).catch(() => {
      promptAction.showToast({
        message: '创建账号失败'
      })
    })

  }

  async update() {
    Logger.info(TAG, 'update submit')
    let updateBindings: BindingContactAction[] = []
    this.labelBindings.forEach(lb => {
      if (!lb.isContacted()) {
        if (lb.isChange()) {
          updateBindings.push({
            data: lb.value(),
            action: 'add'
          })
        } else {
          Logger.info(TAG, 'binding contact is invalidate value, bind=' + lb.bind)
        }
        return
      }

      updateBindings.push({
        data: lb.value(),
        action: lb.isChange() ? 'remain' : 'update'
      })
    })

    await AccountListModel.update({
      ...this.account
    }, updateBindings).then(() => {
      promptAction.showToast({
        message: "账号修改成功"
      })
      setTimeout(() => {
        router.back()
      }, 1000)
    }).catch(() => {
      promptAction.showToast({
        message: '修改账号失败'
      })
    })
  }

  async submit() {
    Logger.info(TAG, 'submit account id=' + this.account.id)
    if (isValidateIntId(this.account.id)) {
      this.update()
    } else {
      this.create()
    }

  }

  build() {
    Row() {

      Column() {
        TopNavBar({ title: '添加账号', back: true }) {

        }

        Column() {

          Flex() {
            Text('名称')
              .flexShrink(0)
              .alignSelf(ItemAlign.Center)
              .margin({ right: 10 })
            TextInput({
              text: this.account.name
            })
              .onChange(v => {
                this.account.name = v
              })
          }
          .alignSelf(ItemAlign.Center)
          .margin({ bottom: 10 })

          Flex() {
            Text('账号')
              .flexShrink(0)
              .alignSelf(ItemAlign.Center)
              .margin({ right: 10 })
            TextInput({
              text: this.account.account
            })
              .onChange(v => {
                this.account.account = v
              })
          }
          .margin({ bottom: 10 })

          Flex() {
            Column() {
              Text('密码')
            }
            .flexShrink(0)
            .alignSelf(ItemAlign.Center)
            .margin({ right: 10 })

            Column() {
              TextInput({
                text: this.account.pwd,
              })
                .type(InputType.Password)
                .onChange(v => {
                  this.account.pwd = v
                })
            }

          }
          .margin({ bottom: 10 })

          Flex() {
            Column() {
              Text('备注')
            }
            .flexShrink(0)
            .alignSelf(ItemAlign.Center)
            .margin({ right: 10 })

            TextInput({
              text: this.account.note,
            }).onChange(v => {
              this.account.note = v
            })
          }

          Row() {
            Text('关联')
              .fontColor($r('app.color.gray_7'))
            Button() {
              Row() {
                Image($r('app.media.add_white')).width(16).height(16).margin({ right: 5 })
                Text('新增关联').fontColor($r('app.color.primary'))
              }
            }
            .backgroundColor(Color.Transparent)
            .padding(5)
            .onClick(() => {
              router.pushUrl({
                url: 'pages/Binding'
              })
            })
          }.margin({ top: 10 })
          .alignSelf(ItemAlign.Start)
          .justifyContent(FlexAlign.SpaceBetween)

          ForEach(this.labelBindings, (bindingItem: AccountBindingViewModel) => {
            Flex() {
              Select(bindingOptions)
                .value(bindingItem.typeLabel)
                .onSelect((idx, v) => {
                  bindingItem.setTypeLabel(v)
                  bindingItem.bind = ''
                  this.foreUpdateLabelBindings()
                })
                .alignSelf(ItemAlign.Center)
                .margin({ right: 15 })

              if (bindingItem.getCurrentTypeContactOptions().length) {
                Select(bindingItem.getCurrentTypeContactOptions())
                  .value(bindingItem.bind)
                  .onSelect((idx, v) => {
                    bindingItem.contactCurrentTypeBindingWithIdx(idx)
                  })
              } else {
                Text("无").fontColor($r('app.color.gray_6')).alignSelf(ItemAlign.Center)
              }

            }
            .margin({ bottom: 10 })

          })

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
        .padding(10)
      }
    }
  }
}