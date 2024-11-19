import UIAbility from '@ohos.app.ability.UIAbility';
import hilog from '@ohos.hilog';
import window from '@ohos.window';
import emitter from '@ohos.events.emitter';
import deviceInfo from '@ohos.deviceInfo';

const PREFIX = 'KeyperEntryAbility'

export default class EntryAbility extends UIAbility {
  isEmulator = true

  onCreate(want, launchParam) {
    this.echoInfo()
    hilog.info(0x0000, PREFIX, '%{public}s', 'Ability onCreate');
    window.getLastWindow(this.context).then((win) => {
      win.setWindowPrivacyMode(true).then(() => {
        hilog.info(0x0000, PREFIX, '%{public}s', 'setWindowPrivacyMode=true succeed');
      })
    })
  }

  onDestroy() {
    hilog.info(0x0000, PREFIX, '%{public}s', 'Ability onDestroy');
  }

  echoInfo() {
    let info = '';

    ['osFullName', 'marketName', 'brand', 'deviceType', 'productSeries', 'versionId'].forEach(key => {
      info += `\n    ${key}=${deviceInfo[key]}`
    })
    // deviceInfo.osFullName
    hilog.info(0x0000, PREFIX, '%{public}s', 'deviceInfo: \n' + info);

  }

  onWindowStageCreate(windowStage: window.WindowStage) {
    // Main window is created, set main page for this ability
    hilog.info(0x0000, PREFIX, '%{public}s', 'Ability onWindowStageCreate');
    let windowClass: window.Window = null;
    let avoidTopHeight = 0
    let bottomAvoidHeight = 0

    const loadContent = () => {
      windowStage.loadContent('pages/Lock', (err, data) => {
        if (err.code) {
          hilog.error(0x0000, PREFIX, 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');

          return;
        }

        let navHeightVp = px2vp(avoidTopHeight)
        let bottomAvoidHeightVp = px2vp(bottomAvoidHeight)
        AppStorage.SetOrCreate('avoidTopHeight', navHeightVp)
        AppStorage.SetOrCreate('avoidBottomHeight', bottomAvoidHeightVp)
        hilog.info(0x0000, PREFIX, 'avoidArea(vp) top: %{public}s bottom %{public}s', '' + navHeightVp, '' + bottomAvoidHeightVp);

        hilog.info(0x0000, PREFIX, 'Succeeded in loading the content. Data: %{public}s', JSON.stringify(data) ?? '');
      });
    }

    windowStage.getMainWindow((err, data) => {

      if (err.code) {
        console.error('Failed to obtain the main window. Cause: ' + JSON.stringify(err));
        loadContent()
        return;
      }

      windowClass = data;
      console.info('Succeeded in obtaining the main window. Data: ' + JSON.stringify(data));

      windowClass.on('avoidAreaChange', (data) => {
        if (data.type === window.AvoidAreaType.TYPE_SYSTEM) {
          let navHeightVp = px2vp(data.area.topRect.height)
          let bottomAvoidHeightVp = px2vp(data.area.bottomRect.height)
          hilog.info(0x0000, PREFIX, `sys avoidAreaChange new area(vp): top ${navHeightVp} bottom ${bottomAvoidHeightVp}`);

          AppStorage.SetOrCreate('avoidTopHeight', navHeightVp)
          AppStorage.SetOrCreate('avoidBottomHeight', bottomAvoidHeightVp)
        }
      })

      windowClass.setWindowLayoutFullScreen(true)
        .then(() => {
          let avoidArea = data.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM)
          avoidTopHeight = avoidArea.topRect.height
          bottomAvoidHeight = avoidArea.bottomRect.height
          hilog.info(0x0000, PREFIX, 'sys avoidArea(px) top: %{public}s bottom %{public}s', '' + avoidTopHeight, '' + bottomAvoidHeight);

          hilog.info(0x0000, PREFIX, 'setWindowLayoutFullScreen succeed');

        })
        .catch((e) => {
          hilog.error(0x0000, PREFIX, 'setWindowLayoutFullScreen failed, ' + JSON.stringify(e));
        })


      windowClass.setWindowSystemBarEnable(this.isEmulator ? ['status'] : ['status', 'navigation'], (err) => {
        loadContent()

        if (err.code) {
          hilog.error(0x0000, PREFIX, 'setWindowSystemBarEnable failed' + JSON.stringify(err));

          return;
        }
        hilog.info(0x0000, PREFIX, 'setWindowSystemBarEnable succeed');
      });
    })

  }

  onWindowStageDestroy() {
    // Main window is destroyed, release UI related resources
    hilog.info(0x0000, PREFIX, '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground() {
    // Ability has brought to foreground
    hilog.info(0x0000, PREFIX, '%{public}s', 'Ability onForeground');
    emitter.emit({
      eventId: 500
    })
  }

  onBackground() {
    // Ability has back to background
    hilog.info(0x0000, PREFIX, '%{public}s', 'Ability onBackground');
    emitter.emit({
      eventId: 501
    })
  }
}

