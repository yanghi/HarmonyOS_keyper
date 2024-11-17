@Component
export struct DescItem {
  @Prop label: string
  @BuilderParam child: () => {}
  labelWidth = 60
  gutter = 2
  required = false

  getChars() {
    return this.label.split('')
  }

  build() {
    Flex() {
      Row() {
        Text(this.required ? '*' : '').fontColor($r('app.color.error')).position({ x: -8 })
        ForEach(this.getChars(), (char: string) => {
          Text(char)
        })
      }
      .justifyContent(FlexAlign.SpaceBetween)
      .flexShrink(0)
      .width(this.labelWidth)
      .padding({ right: 10 })
      .alignSelf(ItemAlign.Center)

      if (this.child) {
        this.child()
      }
    }

    .margin({
      top: this.gutter,
      bottom: this.gutter
    })
  }
}
