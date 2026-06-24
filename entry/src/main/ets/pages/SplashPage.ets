/**
 * SplashPage - 闪屏页（应用启动入口页面）
 * 功能：显示带渐变背景的闪屏动画，2秒后根据应用状态自动跳转
 * 跳转逻辑：
 *   首次启动 → GuidePage（引导页）
 *   非首次 + 已登录 → Index（首页）
 *   非首次 + 未登录 → LoginPage（登录页）
 */
import { Constants } from '../common/constants/Constants'
import { PreferencesUtil } from '../common/utils/PreferencesUtil'

@Entry
@Component
struct SplashPage {
  @State fadeLevel: number = 0       // 透明度动画值（0→1 渐显）
  @State scaleLevel: number = 0.8    // 缩放动画值（0.8→1 放大）
  private shouldShowGuide: boolean = true // 是否需要展示引导页
  private isLogin: boolean = false      // 是否已登录

  aboutToAppear(): void {
    // 确保 Preferences 已初始化（在页面级而非 Ability 级的保险措施）
    const hostContext = this.getUIContext().getHostContext()
    if (hostContext) {
      PreferencesUtil.getInstance().ensureInit(hostContext)
    }
    // 读取引导页完成状态和登录状态，决定跳转目标
    // guideVersion 用于兼容模拟器中残留的旧 isFirstLaunch=false 状态：
    // 只有完成当前版本引导后，后续启动才跳过 GuidePage。
    const guideVersion: number = PreferencesUtil.getInstance().getNumber(Constants.KEY_GUIDE_VERSION, 0)
    const isLegacyFirstLaunch: boolean =
      PreferencesUtil.getInstance().getBoolean(Constants.KEY_IS_FIRST_LAUNCH, true)
    this.shouldShowGuide = guideVersion < Constants.CURRENT_GUIDE_VERSION || isLegacyFirstLaunch
    this.isLogin = PreferencesUtil.getInstance().getBoolean(Constants.KEY_IS_LOGIN, false)

    // 启动渐显+放大动画，持续1秒
    this.getUIContext().animateTo({ duration: 1000, curve: Curve.EaseOut }, () => {
      this.fadeLevel = 1
      this.scaleLevel = 1
    })

    // 2秒后执行跳转
    setTimeout(() => {
      this.navigateNext()
    }, 2000)
  }

  /**
   * 根据应用状态跳转到下一个页面
   * 优先级：首次启动 > 登录状态
   */
  private navigateNext(): void {
    const router = this.getUIContext().getRouter()
    try {
      if (this.shouldShowGuide) {
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
      .scale({ x: this.scaleLevel, y: this.scaleLevel }) // 缩放动画
      .opacity(this.fadeLevel)                            // 渐显动画
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
