@Component
export struct CircleButton {
  circleSize = 40
  // @BuilderParam Child
  icon: string | Resource
  buttonColor: string | Resource = '#ffffff'
  onButtonClick: () => void

  build() {
    Row() {
      Image(this.icon).width(this.circleSize * 0.5).alignSelf(ItemAlign.Center)
    }
    .width(this.circleSize)
    .height(this.circleSize)
    .borderRadius(this.circleSize)
    .backgroundColor(this.buttonColor)
    .shadow({ offsetX: 2, offsetY: 4, color: '#1f000000', radius: 6 })
    .onClick(this.onButtonClick)
    .justifyContent(FlexAlign.Center)
  }
}