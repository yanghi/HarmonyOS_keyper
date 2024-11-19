import Logger from '../common/utils/Logger'

@Component
export struct BaseLayout {
  @StorageProp('avoidTopHeight') avoidTopHeight: number = 0
  @StorageProp('avoidBottomHeight') avoidBottomHeight: number = 0
  topNav = true

  aboutToAppear() {
    Logger.debug('BaseLayout', 'avto' + this.avoidTopHeight + ' bot ' + this.avoidBottomHeight)
  }

  @BuilderParam child: () => {}

  build() {
    Column() {
      this.child()
    }.padding({
      top: this.topNav ? 0 : this.avoidTopHeight,
      bottom: this.avoidBottomHeight
    })
  }
}