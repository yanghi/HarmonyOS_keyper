import { requestPasswordVerify } from '../common/utils/app'
import { TopNavBar } from '../components/TopNavBar'
import { AccountListModel } from '../model/Account'
import Logger from '../common/utils/Logger'
import router from '@ohos.router'
import promptAction from '@ohos.promptAction'
import { CommonConstants } from '../common/constants/CommonConstants'
import { dataManager } from '../model/DataManager'

@Styles function listItemCard() {
  .backgroundColor(0xffffff)
  .padding(10)
  // .borderRadius(10)
}

@Styles function listItemStyles() {
  // .padding({ left: 10, right: 10 })
  .margin({ bottom: 0 })
}

const TAG = '[SettingsEntry]'

@Component
export struct Settings {
  exportToExt() {
    AlertDialog.show({
      title: '明文导出',
      message: '账号数据解密成明文后导出成文本文件,在点击"确定"按钮后输入密码后导出',
      autoCancel: true,
      alignment: DialogAlignment.Center,
      gridCount: 4,
      offset: { dx: 0, dy: -20 },
      primaryButton: {
        value: '确定',
        fontColor: 'red',
        action: () => {
          Logger.info(TAG, 'user confirm to export data')
          requestPasswordVerify({
            id: 'setting.exportAsTxt',
            reasonTitle: '明文导出'
          }, {}, () => {
            Logger.warn(TAG, 'user export after verified')
            dataManager.exportAsTxt(AccountListModel.list).then(() => {
              promptAction.showToast({
                message: '文件保存成功,请妥善保管'
              })
            }).catch(() => {
              promptAction.showToast({
                message: '文件保存失败'
              })
            })
          })

        }
      },
      secondaryButton: {
        value: '取消',
        action: () => {

        }
      },
      cancel: () => {

      }
    })

  }

  exportAsJson() {
    dataManager.exportAsJson().then(() => {
      promptAction.showToast({
        message: '导出成功'
      })
    }).catch(e => {
      promptAction.showToast({
        message: '导出失败'
      })
    })
  }

  importFromJson() {
    dataManager.importFromJson()
      .then(() => {
        promptAction.showToast({
          message: '导入成功'
        })
      })
      .catch(e => {
        promptAction.showToast({
          message: '导入失败'
        })
      })
  }

  handleExportAsJson() {
    if (!AccountListModel.list.length) {
      promptAction.showToast({
        message: '没有可以导出的数据'
      })
      return
    }

    AlertDialog.show({
      title: '导出',
      message: '导出您的数据,导出后可以在其他设备上使用Keyper导入,在点击"确定"按钮后输入密码后导出',
      autoCancel: true,
      alignment: DialogAlignment.Center,
      gridCount: 4,
      offset: { dx: 0, dy: -20 },
      primaryButton: {
        value: '确定',
        fontColor: 'red',
        action: () => {
          Logger.info(TAG, 'user confirm to reset data')
          requestPasswordVerify({
            id: 'setting.export',
            reasonTitle: '导出'
          }, {}, () => {
            Logger.warn(TAG, 'user export after verified')
            this.exportAsJson()
          })
        }
      },
      secondaryButton: {
        value: '取消',
        action: () => {

        }
      },
      cancel: () => {

      }
    })
  }

  handleReset() {
    AlertDialog.show({
      title: '重置数据',
      message: '重置您的全部数据,该操作不可恢复,在点击"确定"按钮后输入密码后重置',
      autoCancel: true,
      alignment: DialogAlignment.Center,
      gridCount: 4,
      offset: { dx: 0, dy: -20 },
      primaryButton: {
        value: '确定',
        fontColor: 'red',
        action: () => {
          Logger.info(TAG, 'user confirm to reset data')
          requestPasswordVerify({
            id: 'setting.reset',
            reasonTitle: '重置数据'
          }, {}, () => {
            Logger.warn(TAG, 'user reset after verified')
            dataManager.resetAllData().then(() => {
              promptAction.showToast({
                message: '重置成功'
              })
              setTimeout(() => {
                router.pushUrl({
                  url: 'pages/Lock'
                })
              }, 3000)
            }).catch(e => {
              promptAction.showToast({
                message: '重置失败'
              })
            })
          })
        }
      },
      secondaryButton: {
        value: '取消',
        action: () => {

        }
      },
      cancel: () => {

      }
    })
  }

  build() {
    Column() {
      Column() {
        TopNavBar({ title: '设置' }) {
        }
      }.padding({ bottom: CommonConstants.PAGE_CONTENT_TOP_GAP })

      List({ space: 10 }) {
        ListItemGroup() {
          ListItem() {
            this.buildListItem('回收站', () => {
              router.pushUrl({
                url: 'pages/RecycleBin'
              })
            })
          }.listItemStyles()
        }

        ListItemGroup({ header: this.itemHeader('数据') }) {
          // for test
          // ListItem() {
          //   this.buildListItem('测试', () => {
          //     dataManager.testPort().then(()=>{
          //       promptAction.showToast({
          //         message: '成功'
          //       })
          //     }).catch(e=>{
          //       promptAction.showToast({
          //         message: '失败'
          //       })
          //     })
          //   })
          // }.listItemStyles()

          ListItem() {
            this.buildListItem('导出', () => {
              this.handleExportAsJson()
            })
          }.listItemStyles()

          ListItem() {
            this.buildListItem('导入', () => {
              this.importFromJson()
            })
          }.listItemStyles()

          ListItem() {
            this.buildListItem('明文导出', () => {
              this.exportToExt()
            })
          }.listItemStyles()

          ListItem() {
            this.buildListItem('重置数据', () => {
              this.handleReset()
            })
          }.listItemStyles()
        }.borderRadius(10)
        .divider({ strokeWidth: 1, endMargin: 15 })

        ListItemGroup() {
          ListItem() {
            this.buildListItem('关于', () => {
              router.pushUrl({
                url: 'pages/About'
              })
            })
          }.listItemStyles()
        }.divider({ strokeWidth: 1, endMargin: 15, startMargin: 15 })
      }
      .padding({ left: 10, right: 10 })

    }
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .backgroundColor($r('app.color.page_bg'))
  }

  @Builder buildListItem(text: string, onClick: ((event?: ClickEvent) => void)) {
    Row() {
      Text(text)
      Image($r('app.media.right_arrow_icon')).width(16).height(16)
    }
    .justifyContent(FlexAlign.SpaceBetween)
    .width('100%')
    .onClick(onClick)
    .listItemCard()
  }

  @Builder itemHeader(title: string) {
    // Text(title)
    //   .fontSize(18)
    //   .padding(5)
  }
}