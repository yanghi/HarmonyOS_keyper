import UIAbility from '@ohos.app.ability.UIAbility';
import hilog from '@ohos.hilog';
import window from '@ohos.window';
import emitter from '@ohos.events.emitter';

const PREFIX = 'KeyperEntryAbility'

export default class EntryAbility extends UIAbility {
  onCreate(want, launchParam) {
    hilog.info(0x0000, PREFIX, '%{public}s', 'Ability onCreate');
    window.getLastWindow(this.context).then((win) => {
      win.setWindowPrivacyMode(true).then(() => {
        hilog.info(0x0000, 'Keyper', '%{public}s', 'setWindowPrivacyMode=true succeed');
      })
    })
  }

  onDestroy() {
    hilog.info(0x0000, PREFIX, '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage) {
    // Main window is created, set main page for this ability
    hilog.info(0x0000, PREFIX, '%{public}s', 'Ability onWindowStageCreate');
    let windowClass: window.Window = null;


    const loadContent = () => {
      windowStage.loadContent('pages/Lock', (err, data) => {
        if (err.code) {
          hilog.error(0x0000, PREFIX, 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');

          return;
        }

        let navHeightVp = px2vp(navBarHe)
        AppStorage.SetOrCreate('navHeight', navHeightVp)
        hilog.info(0x0000, PREFIX, '%{public}s', 'avoidArea navHeight vp' + navHeightVp);

        hilog.info(0x0000, PREFIX, 'Succeeded in loading the content. Data: %{public}s', JSON.stringify(data) ?? '');
      });
    }

    let navBarHe = 100
    windowStage.getMainWindow((err, data) => {

      if (err.code) {
        console.error('Failed to obtain the main window. Cause: ' + JSON.stringify(err));
        loadContent()
        return;
      }

      windowClass = data;
      console.info('Succeeded in obtaining the main window. Data: ' + JSON.stringify(data));

      let avoidArea = data.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM)
      navBarHe = avoidArea.topRect.height
      hilog.info(0x0000, PREFIX, '%{public}s', 'avoidArea nav H' + avoidArea.topRect.height);

      windowClass.setWindowSystemBarEnable(['status', 'navigation'], (err) => {
        if (err.code) {
          loadContent()
          console.error('Failed to set the system bar to be visible. Cause:' + JSON.stringify(err));
          return;
        }
        console.info('Succeeded in setting the system bar to be visible.');
      });

      windowClass.setWindowLayoutFullScreen(true).finally(loadContent)
    })

    // windowStage.loadContent('pages/Lock', (err, data) => {
    //   if (err.code) {
    //     hilog.error(0x0000, TAG, 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
    //     return;
    //   }
    //
    //   let navHeightVp = px2vp(navBarHe)
    //   AppStorage.SetOrCreate('navHeight', navHeightVp)
    //   hilog.info(0x0000, TAG, '%{public}s', 'avoidArea navHeight vp' +navHeightVp);
    //
    //   hilog.info(0x0000, TAG, 'Succeeded in loading the content. Data: %{public}s', JSON.stringify(data) ?? '');
    // });
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

