import { Constants } from '../common/constants/Constants'
import { PreferencesUtil } from '../common/utils/PreferencesUtil'

@Entry
@Component
struct SplashPage {
  @State fadeLevel: number = 0
  @State scaleLevel: number = 0.8
  @State prefsReady: boolean = false
  private isFirstLaunch: boolean = true
  private isLogin: boolean = false

  aboutToAppear(): void {
    const hostContext = this.getUIContext().getHostContext()
    if (hostContext) {
      PreferencesUtil.getInstance().ensureInit(hostContext)
    }
    this.isFirstLaunch = PreferencesUtil.getInstance().getBoolean(Constants.KEY_IS_FIRST_LAUNCH, true)
    this.isLogin = PreferencesUtil.getInstance().getBoolean(Constants.KEY_IS_LOGIN, false)
    this.prefsReady = true

    this.getUIContext().animateTo({ duration: 1000, curve: Curve.EaseOut }, () => {
      this.fadeLevel = 1
      this.scaleLevel = 1
    })

    setTimeout(() => {
      this.navigateNext()
    }, 2000)
  }

  private navigateNext(): void {
    const router = this.getUIContext().getRouter()
    try {
      if (this.isFirstLaunch) {
        router.replaceUrl({ url: 'pages/GuidePage' })
      } else if (this.isLogin) {
        router.replaceUrl({ url: 'pages/Index' })
      } else {
        router.replaceUrl({ url: 'pages/LoginPage' })
      }
    } catch (e) {
      console.error('navigateNext failed: ' + JSON.stringify(e))
    }
  }

  build() {
    Column() {
      Column() {
        Text('银龄通')
          .fontSize(56)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .textShadow({ radius: 8, color: '#1A3A7A', offsetX: 2, offsetY: 2 })

        Text('智慧养老服务平台')
          .fontSize(20)
          .fontColor('#D6E4FF')
          .margin({ top: 16 })
          .letterSpacing(4)
      }
      .scale({ x: this.scaleLevel, y: this.scaleLevel })
      .opacity(this.fadeLevel)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .linearGradient({
      angle: 135,
      colors: [['#1A56DB', 0.0], ['#4A90D9', 0.5], ['#7B61FF', 1.0]]
    })
  }
}
