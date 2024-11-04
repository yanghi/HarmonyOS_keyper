import { AccountList } from './AccountList'
import { BindingList } from './BindingList'
import { Settings } from './Settings'
import { Tools } from './Tools'

@Entry
@Component
struct Index {
  aboutToAppear() {
    // AppRelationalStoreManager.init()
  }

  @State current: number = 0

  build() {
    Column() {
      Tabs({
        index: 0
      }) {
        TabContent() {
          AccountList()
        }.tabBar({
          text: '账号',
          icon: this.current == 0 ? $r('app.media.tabbar_account_active_icon') : $r('app.media.tabbar_account_icon')
        })

        TabContent() {
          BindingList()
        }.tabBar({
          text: '关联',
          icon: this.current == 1 ? $r("app.media.tabbar_binding_active_icon") : $r("app.media.tabbar_binging_icon")
        })

        TabContent() {
          Tools()
        }.tabBar({
          text: '工具',
          icon: this.current == 2 ? $r("app.media.tabbar_tools_active_icon") : $r("app.media.tabbar_tools_icon")
        })

        TabContent() {
          Settings()
        }.tabBar({
          text: '设置',
          icon: this.current == 3 ? $r("app.media.tabbar_setting_active_icon") : $r('app.media.tabbar_setting_icon')
        })
      }
      .barPosition(BarPosition.End)
      .scrollable(false)
      .onChange(current => {
        this.current = current
      })
    }

  }
}