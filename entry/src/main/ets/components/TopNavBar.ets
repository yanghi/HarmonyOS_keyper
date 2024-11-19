import router from '@ohos.router'
import { CommonConstants } from '../common/constants/CommonConstants'

@Component
export struct TopNavBar {
  @Prop title: string
  private back: boolean = false
  @BuilderParam child: () => {}
  @StorageProp('avoidTopHeight') avoidTopHeight: number = 0

  build() {
    Row() {
      Row() {
        if (this.back) {
          Button() {
            Image($r('app.media.back_white'))
              .width(20)
              .height(20)

          }.backgroundColor(Color.Transparent)
          .padding(5)
          .margin({ right: 5 })
          .onClick(() => {
            router.back()
          })
        }


        if (this.title) {
          Text(this.title)
            .fontSize(18)
            .fontWeight(500)
            .fontColor(0xffffff)
        }
      }

      Column() {
        this.child?.()
      }
    }
    .width('100%')
    .padding({
      left: 10,
      right: 10,
      bottom: 10,
      top: this.avoidTopHeight
    })
    .backgroundColor($r('app.color.primary'))
    .justifyContent(FlexAlign.SpaceBetween)
    .height(40 + this.avoidTopHeight)
  }
}