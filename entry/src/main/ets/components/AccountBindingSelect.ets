import logger from '../common/utils/Logger'
import { AccountBindingListModel } from '../model/AccountBinding'
import { AccountBindingViewModel } from '../viewModel/AccountBindingViewModel'

const TAG = '[AccountBindingSelect]'

@Component
export struct AccountBindingSelect {
  bindingListModel = AccountBindingListModel

  aboutToAppear() {
    let viewModelList: AccountBindingViewModel[] = []
    Array.from(AccountBindingListModel.getTypeGroup()).forEach(([t, list]) => {
      viewModelList.push(...list.map(it => new AccountBindingViewModel(it)))
    })

  }

  private isSelected(id: number) {
    return this.selectedBindingIdList.includes(id)
  }

  private unselect(id: number) {
    this.selectedBindingIdList = this.selectedBindingIdList.filter(tid => tid !== id)
  }

  private select(id: number) {
    this.selectedBindingIdList = this.selectedBindingIdList.concat(id)
  }

  private toggle(id: number) {
    if (this.isSelected(id)) {
      this.unselect(id)
    } else {
      this.select(id)
    }
  }

  @Link @Watch('cg') show: boolean

  cg() {
    logger.debug(TAG, 'cg' + this.show)
  }

  submit() {
    logger.debug(TAG, 'submit ' + JSON.stringify(this.selectedBindingIdList))
    this.onChange?.(this.selectedBindingIdList)
    this.show = false
  }

  cancel() {
    this.show = false
    this.selectedBindingIdList = []

  }

  @State selectedBindingIdList: number[] = []
  onChange: (selected: number[]) => void

  build() {
    Row() {
      Panel(this.show) {
        Column() {
          Row() {
            Text(`已选择 ${this.selectedBindingIdList.length} 个`).fontColor($r('sys.color.ohos_fa_text_secondary'))
            Row() {
              Button() {
                Row() {
                  Text('取消').fontColor(Color.White)
                }
              }.onClick(() => {
                this.cancel()
              })
              .margin({ right: 10 })
              .backgroundColor(Color.Transparent)

              Button() {
                Row() {
                  Text('确定').fontColor(Color.White)
                }
              }.onClick(() => {
                this.submit()
              })
              .backgroundColor(Color.Transparent)

            }
          }.justifyContent(FlexAlign.SpaceBetween)
          .padding(6)
          .width('100%')
          .margin(10)

          Column() {
            ForEach(this.bindingListModel.list, (binding: AccountBindingViewModel) => {
              Row() {
                Text(binding.typeLabel)
                Text(binding.bind)
                Text(this.isSelected(binding.id) ? 'Y' : 'N').width(40)
              }.onClick(() => {
                this.toggle(binding.id)
              })
            })
          }
        }
        .height('100%')
        .backgroundColor('red')
      }
      .type(PanelType.Foldable)
      .dragBar(false)
      .mode(PanelMode.Half)
      // .dragBar(true) // 默认开启
      .halfHeight(500) // 默认一半
      .onChange((width: number, height: number, mode: PanelMode) => {
        console.info(`width:${width},height:${height},mode:${mode}`)
      })
    }
  }
}