@Entry
@Component
export struct NumberRange {
  private step: number = 1
  private max: number = 999
  private min: number = 1
  @Watch('onValueChange')
  @State
  value: number = this.min;

  onValueChange() {
    this.onChange?.(this.value)
  }

  onChange?: (value: number) => void

  build() {
    Flex() {
      Text('−')
        .onClick(() => this.decreaseNumber())
        .margin({ left: 10 })
        .alignSelf(ItemAlign.Center)
      Text(this.value + '')
        .fontSize(20)
        .textAlign(TextAlign.Center)
        .margin({ left: 10, right: 10 })
        .alignSelf(ItemAlign.Center)

      Text('+')
        .fontSize(20)
        .onClick(() => this.increaseNumber())
          // .fontColor('gray')
        .alignSelf(ItemAlign.Center)
        .margin({ right: 10 })
    }
  }

  private increaseNumber() {
    if (this.value < this.max) {
      let newNum = this.value + this.step
      if (newNum > this.max) {
        newNum = this.max
      }
      this.value = newNum;
    }
  }

  private decreaseNumber() {
    if (this.value > this.min) {
      let newNum = this.value - this.step
      if (newNum < this.min) {
        newNum = this.min
      }
      this.value = newNum;
    }
  }
}
