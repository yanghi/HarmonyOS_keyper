import { AccountList } from './AccountList'
import { BindingList } from './BindingList'
import { Settings } from './Settings'
import { Tools } from './Tools'
import promptAction from '@ohos.promptAction'
import common from '@ohos.app.ability.common'
import logger from '../common/utils/Logger'
import emitter from '@ohos.events.emitter'
import { EventId, LockEventPayload } from '../common/enums/Event'
import { AppLockType } from '../common/enums/app'
import { AppLock } from '../model/Lock'
import router from '@ohos.router'
import { AccountGroupListViewModel } from '../viewModel/AccountGroupListViewModel'

const TAG = '[Index]'

@Entry
@Component
struct Index {
  aboutToAppear() {
    // AppRelationalStoreManager.init()
    logger.debug(TAG, 'aboutToAppear')

    emitter.on({ eventId: EventId.AppBackground }, () => {
      logger.info(TAG, 'onBackground event')
      AppLock.startCount()
    })
    emitter.on({ eventId: EventId.AppForeground }, () => {
      logger.info(TAG, 'onForeground event')
      AppLock.resetCount()
    })

    emitter.on({ eventId: EventId.Lock }, (payload: emitter.EventData) => {
      logger.debug(TAG, 'goto lock page when app locked, reason' + JSON.stringify(payload.data))
      router.pushUrl({
        url: 'pages/Lock'
      })
    })
  }

  aboutToDisappear() {
    logger.debug(TAG, 'aboutToDisappear')
  }

  private pretime: number = 0;

  onBackPress() {
    let nowtime = Date.now();
    if (nowtime - this.pretime < 1000) {
      const mContext = getContext(this) as common.UIAbilityContext
      logger.info(TAG, 'double back press')
      mContext.terminateSelf();
    } else {
      this.pretime = nowtime;
      promptAction.showToast({
        message: '再按一次退出应用'
      })
    }

    return true;
  }

  @State current: number = 0

  @Builder TabBuilder(opts: {
    icon: string | Resource,
    selectedIcon: string | Resource,
    text: string,
    index: number
  }) {
    Column() {
      Image(this.current === opts.index ? opts.selectedIcon : opts.icon).width(24)
      Text(opts.text)
        .fontColor($r('app.color.gray_7'))
        .fontSize(12)
        .margin({ top: 2 })

    }.width('100%')
  }

  build() {
    Column() {
      Tabs({
        index: 0
      }) {
        TabContent() {
          AccountList()
        }.tabBar(
          this.TabBuilder({
            text: '账号',
            index: 0,
            icon: $r('app.media.tabbar_account_icon'),
            selectedIcon: $r('app.media.tabbar_account_active_icon')
          })
        )

        TabContent() {
          BindingList()
        }.tabBar(
          this.TabBuilder({
            text: '关联',
            index: 1,
            icon: $r("app.media.tabbar_binging_icon"),
            selectedIcon: $r("app.media.tabbar_binding_active_icon")
          }))

        TabContent() {
          Tools()
        }.tabBar(this.TabBuilder({
          text: '工具',
          index: 2,
          icon: $r("app.media.tabbar_tools_icon"),
          selectedIcon: $r("app.media.tabbar_tools_active_icon"),
        }))

        TabContent() {
          Settings()
        }.tabBar(this.TabBuilder({
          text: '设置',
          index: 3,
          icon: $r("app.media.tabbar_setting_icon"),
          selectedIcon: $r("app.media.tabbar_setting_active_icon"),
        }))
      }
      .barPosition(BarPosition.End)
      .scrollable(false)
      .onChange(current => {
        this.current = current
      })
    }

  }
}