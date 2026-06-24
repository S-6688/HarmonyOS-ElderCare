/**
 * GuidePage - 引导页（首次启动时展示）
 * 功能：通过 Swiper 展示3页引导内容（健康管理、用药提醒、紧急呼叫）
 * 仅在首次启动时显示，点击"立即体验"或"跳过"后标记非首次启动并跳转登录页
 */
import { PreferencesUtil } from '../common/utils/PreferencesUtil'
import { Constants } from '../common/constants/Constants'

class GuideItemData {
  title: string = ''
  desc: string = ''
  color: string = ''
  icon: string = ''
}

@Entry
@Component
struct GuidePage {
  @State currentIndex: number = 0 // 当前展示的引导页索引

  private guideItems: GuideItemData[] = []

  aboutToAppear(): void {
    const item1: GuideItemData = new GuideItemData()
    item1.title = '健康管理'
    item1.desc = '记录血压、血糖、心率等健康数据'
    item1.color = '#1A56DB'
    item1.icon = '健'
    const item2: GuideItemData = new GuideItemData()
    item2.title = '用药提醒'
    item2.desc = '准时提醒服药，不再忘记'
    item2.color = '#7B61FF'
    item2.icon = '药'
    const item3: GuideItemData = new GuideItemData()
    item3.title = '紧急呼叫'
    item3.desc = '一键联系家人，安全有保障'
    item3.color = '#E74C3C'
    item3.icon = '联'
    this.guideItems = [item1, item2, item3]
  }

  /** 标记非首次启动，后续启动不再显示引导页 */
  private markFirstLaunchDone(): void {
    const hostContext = this.getUIContext().getHostContext()
    if (hostContext) {
      PreferencesUtil.getInstance().ensureInit(hostContext)
    }
    PreferencesUtil.getInstance().put(Constants.KEY_IS_FIRST_LAUNCH, false)
    PreferencesUtil.getInstance().put(Constants.KEY_GUIDE_VERSION, Constants.CURRENT_GUIDE_VERSION)
  }

  build() {
    Column() {
      Swiper() {
        ForEach(this.guideItems, (item: GuideItemData, index?: number) => {
          Column() {
            Text(item.icon)
              .fontSize(80)
              .fontColor(Color.White)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 32 })

            Text(item.title)
              .fontSize(32)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1A1A1A')
              .margin({ bottom: 16 })

            Text(item.desc)
              .fontSize(20)
              .fontColor('#666666')
              .textAlign(TextAlign.Center)
              .width('70%')
              .lineHeight(32)
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .padding({ left: 40, right: 40 })
        }, (item: GuideItemData, index?: number) => `${index}_${item.title}`)
      }
      .index(this.currentIndex)
      .indicator(new DotIndicator()
        .itemWidth(8)
        .itemHeight(8)
        .selectedItemWidth(16)
        .selectedItemHeight(8)
        .color('#CCCCCC')
        .selectedColor('#1A56DB'))
      .loop(false)          // 禁止循环滑动
      .autoPlay(false)      // 禁止自动播放
      .duration(500)
      .curve(Curve.EaseInOut)
      .onChange((index: number) => {
        this.currentIndex = index
      })
      .layoutWeight(1)

      Column() {
        // "立即体验"按钮：仅在最后一页显示，点击后完成引导
        Button('立即体验')
          .width('80%')
          .height(56)
          .fontSize(22)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
          .backgroundColor('#1A56DB')
          .borderRadius(28)
          .accessibilityText('立即体验按钮，点击进入登录页')
          .accessibilityLevel('yes')
          .onClick(() => {
            this.markFirstLaunchDone()
            this.getUIContext().getRouter().replaceUrl({ url: 'pages/LoginPage' })
          })
          .visibility(this.currentIndex === this.guideItems.length - 1 ? Visibility.Visible : Visibility.Hidden)

        Row() {
          // "跳过"按钮：随时可跳过引导
          Text('跳过')
            .fontSize(16)
            .fontColor('#999999')
            .accessibilityText('跳过引导页')
            .accessibilityLevel('yes')
            .onClick(() => {
              this.markFirstLaunchDone()
              this.getUIContext().getRouter().replaceUrl({ url: 'pages/LoginPage' })
            })
        }
        .margin({ top: 20, bottom: 40 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
  }
}
