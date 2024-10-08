import { TopNavBar } from '../components/TopNavBar'
import bundleManager from '@ohos.bundle.bundleManager';
import logger from '../common/utils/Logger';


@Entry
@Component
struct AboutEntry {
  @State versionName: string = ''
  @State appName: string = ''

  aboutToAppear() {
    this.getInfo()
  }

  getInfo() {
    bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION).then((bundleInfo) => {

      let versionName = bundleInfo.versionName;
      this.versionName = versionName

    }).catch((error) => {
      console.error("get bundleInfo failed,error is " + error)
    })
  }

  build() {
    Column() {
      TopNavBar({ title: '关于', back: true }) {
      }

      Column() {
        Row() {
          Image($r('app.media.app_icon')).width(32).margin({ bottom: 10 })
        }

        Column() {
          Text($r('app.string.app_name')).margin({ bottom: 10 })

          Text('当前版本 ' + this.versionName).fontColor($r('app.color.gray_7'))
        }

        Column() {
          Text('应用的全部数据都存储在本地.敏感数据经过加密后存储,解密后展示.加密算法使用MD5和对称加密')
        }.margin({ top: 20 })
      }.margin(20)

    }
  }
}