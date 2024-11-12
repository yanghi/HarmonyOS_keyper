import router from '@ohos.router'
import { AccountBindingModel, bindingOptions } from '../model/AccountBinding'
import { AccountListModel, AccountModel, BindingContactAction } from '../model/Account'
import { AccountInterface } from '../common/interfaces/Account'
import { AccountBindingViewModel } from '../viewModel/AccountBindingViewModel'
import promptAction from '@ohos.promptAction'
import Logger from '../common/utils/Logger'
import { isValidateIntId } from '../common/utils/common'
import { TopNavBar } from '../components/TopNavBar'
import { PasswordStrengthIndicator } from '../components/PasswordStrengthIndicator'
import { CommonConstants } from '../common/constants/CommonConstants'
import { AccountGroupListModel, AccountGroupListModelCls } from '../model/AccountGroup'
import { AccountGroupSelect } from '../components/AccountGroupSelect'

interface AccountParams {
  id?: number
}

const TAG = '[AccountEntry]'

@Entry
@Component
struct AccountEntry {
  @State account: AccountInterface = AccountModel.emptyData()
  @State isEdit: boolean = false
  @State labelBindings: AccountBindingViewModel[] = [
    new AccountBindingViewModel(AccountBindingModel.emptyData())]

  foreUpdateLabelBindings() {
    this.labelBindings = this.labelBindings.concat()
  }

  @State groupModel: AccountGroupListModelCls = AccountGroupListModel

  handleEditParams(ps: AccountParams) {
    if (ps.id) {
      let editData = AccountListModel.list.find(a => a.id === ps.id)
      if (editData) {
        this.account = { ...editData }
        Logger.debug(TAG, 'edit data: ' + JSON.stringify(editData))
        this.isEdit = true
        this.labelBindings = editData.bindings.map(b => new AccountBindingViewModel(b))
        if (!this.labelBindings.length) {
          this.pushEmptyBinding()
        }
        return
      }
    }

    this.isEdit = false
  }

  onPageShow() {
    let ps = router.getParams() as AccountParams | undefined
    if (ps) {
      this.handleEditParams(ps)
    } else {
      this.isEdit = false
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
        message: '账号修改失败'
      })
    })
  }

  async submit() {
    Logger.info(TAG, 'submit account id=' + this.account.id)
    if (!this.account.name) {
      promptAction.showToast({
        message: '账号名称不能为空'
      })
      return
    }
    if (isValidateIntId(this.account.id)) {
      this.update()
    } else {
      this.create()
    }

  }

  dropBinding(idx: number) {
    this.labelBindings.splice(idx, 1)
  }

  pushEmptyBinding() {
    this.labelBindings.push(new AccountBindingViewModel(AccountBindingModel.emptyData()))
  }

  build() {
    Row() {

      Column() {
        TopNavBar({ title: this.isEdit ? '编辑账号' : '添加账号', back: true }) {

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
            Text('分组')
              .flexShrink(0)
              .alignSelf(ItemAlign.Center)
              .margin({ right: 10 })
            AccountGroupSelect({
              groupId: this.account.groupId,
              groupModel: AccountGroupListModel,
              onChange: (groupId: number) => {
                this.account.groupId = groupId
                Logger.debug(TAG, 'gid ' + groupId)
              }
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

          Flex() {
            Column() {
              Text('密码').fontColor(Color.Transparent)
            }
            .flexShrink(0)
            .alignSelf(ItemAlign.Center)
            .margin({ right: 10 })

            Row() {
              PasswordStrengthIndicator({
                password: this.account.pwd
              })
            }

          }
          // .margin({ bottom: 10 })

          Flex() {
            Text('用户名')
              .flexShrink(0)
              .alignSelf(ItemAlign.Center)
              .margin({ right: 10 })
            TextInput({
              text: this.account.userName
            })
              .onChange(v => {
                this.account.userName = v
              })
          }
          .alignSelf(ItemAlign.Center)
          .margin({ bottom: 10 })

          Flex() {
            Text('昵称')
              .flexShrink(0)
              .alignSelf(ItemAlign.Center)
              .margin({ right: 10 })
            TextInput({
              text: this.account.nickName
            })
              .onChange(v => {
                this.account.nickName = v
              })
          }
          .alignSelf(ItemAlign.Center)
          .margin({ bottom: 10 })


          Row() {
            Text('关联')
            Button() {
              Row() {
                Image($r('app.media.add_primary')).width(16).height(16).margin({ right: 5 })
                Text('创建关联').fontColor($r('app.color.primary')).fontSize(14)
              }
            }
            .backgroundColor(Color.Transparent)
            .margin({ left: 20 })
            .onClick(() => {
              router.pushUrl({
                url: 'pages/Binding'
              })
            })
          }
          .alignSelf(ItemAlign.Start)
          .justifyContent(FlexAlign.SpaceBetween)

          ForEach(this.labelBindings, (bindingItem: AccountBindingViewModel, index) => {
            Row() {
              Row() {
                Select(bindingOptions)
                  .value(bindingItem.typeLabel)
                  .onSelect((idx, v) => {
                    bindingItem.setTypeLabel(v)
                    bindingItem.bind = ''
                    this.foreUpdateLabelBindings()
                  })
                  .alignSelf(ItemAlign.Center)
                  .margin({ right: 15 })
                  .selectedOptionFont({
                    size: 14,
                    weight: FontWeight.Lighter
                  })


                if (bindingItem.getCurrentTypeContactOptions().length) {
                  Select(bindingItem.getCurrentTypeContactOptions())
                    .value(bindingItem.bind)
                    .onSelect((idx, v) => {
                      bindingItem.contactCurrentTypeBindingWithIdx(idx)
                    })
                } else {
                  Text("无数据").fontColor($r('app.color.gray_6')).alignSelf(ItemAlign.Center).fontSize(14)
                }
              }

              Row() {
                if (this.labelBindings.length > 1) {

                  Button() {
                    Row() {
                      Image($r('app.media.remove_red')).width(16).margin({ right: 2 })
                      // Text('移除').fontColor($r('app.color.error')).fontSize(14)
                    }
                  }
                  .margin({ left: 5 })
                  .backgroundColor(Color.Transparent)
                  .onClick(() => {
                    this.dropBinding(index)
                  })
                }

                Button() {
                  Row() {
                    Image($r('app.media.add_primary')).width(16).margin({ right: 2 })
                    // Text('添加').fontColor($r('app.color.primary')).fontSize(14)
                  }
                }
                .margin({ left: 5 })

                .backgroundColor(Color.Transparent)
                .onClick(() => {
                  this.pushEmptyBinding()
                })
              }
              .alignSelf(ItemAlign.Center)
            }
            // .margin({ top: 5 })
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
          })
          //
          // Row() {
          //
          // }.justifyContent(FlexAlign.End)
          // .width('100%')
          // .margin({bottom: 10})

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
          .margin({ top: 10 })
          // submit
          Row() {
            Button('保存')
              .width('80%')
              .padding(10)
              .margin({ top: 40 })
              .onClick(() => {
                this.submit()
              })
          }
        }
        .padding({
          left: CommonConstants.PAGE_CONTENT_HORIZONTAL_GAP,
          right: CommonConstants.PAGE_CONTENT_HORIZONTAL_GAP,
          top: CommonConstants.PAGE_CONTENT_TOP_GAP
        })
      }
    }
  }
}