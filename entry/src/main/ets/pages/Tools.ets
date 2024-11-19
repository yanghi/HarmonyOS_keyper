import { BaseLayout } from '../components/BaseLayout'
import { TopNavBar } from '../components/TopNavBar'
import { ToolCheckPasswordStrength } from './ToolCheckPasswordStrength'
import { ToolPasswordGenerate } from './ToolPasswordGenerate'

@Component
export struct Tools {
  @State fontColor: string = '#182431'
  @State selectedFontColor: string = '#007DFF'
  @State currentIndex: number = 0

  @Builder TabBuilder(index: number, name: string) {

    Column() {
      Text(name)
        .fontColor(this.currentIndex === index ? this.selectedFontColor : this.fontColor)
        .fontSize(16)
        .fontWeight(this.currentIndex === index ? 500 : 400)
        .lineHeight(22)
        .margin({ top: 17, bottom: 7 })
      Divider()
        .strokeWidth(2)
        .color('#007DFF')
        .opacity(this.currentIndex === index ? 1 : 0)
    }.width('100%')
  }

  build() {
    Column() {

      BaseLayout() {
        Column() {
          TopNavBar({ title: '工具' }) {
          }
        }

        Tabs({ barPosition: BarPosition.Start }) {
          TabContent() {
            ToolPasswordGenerate()
          }.tabBar(this.TabBuilder(0, '密码生成'))

          TabContent() {
            ToolCheckPasswordStrength()
          }.tabBar(this.TabBuilder(1, '强度检测'))
        }
        .barMode(BarMode.Fixed)
        .barWidth(200)
        .barHeight(56)
        .animationDuration(400)
        .onChange((index: number) => {
          this.currentIndex = index
        })
        .backgroundColor('#F1F3F5')
      }
    }

    .height('100%')
  }
}