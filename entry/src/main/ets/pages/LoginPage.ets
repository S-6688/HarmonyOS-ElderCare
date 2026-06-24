/**
 * LoginPage - 登录页
 * 提供三种登录方式：
 *   1. 一键登录：使用默认用户"张爷爷"直接登录（适合老年人简化操作）
 *   2. 姓名登录：输入姓名后确认登录
 *   3. 游客模式：跳过登录，部分功能受限
 * 登录成功后将用户名和登录状态写入 AppStorage 和 Preferences，并跳转首页
 */
import { UserViewModel } from '../viewmodel/UserViewModel'
import { PreferencesUtil } from '../common/utils/PreferencesUtil'

@Entry
@Component
struct LoginPage {
  @State inputName: string = ''                     // 用户输入的姓名
  @StorageLink('fontSizeLevel') fontSizeLevel: number = 0 // 全局字体大小等级
  private userViewModel: UserViewModel = new UserViewModel()

  private scaledSize(base: number): number {
    return base + this.fontSizeLevel * 4
  }

  aboutToAppear(): void {
    const hostContext = this.getUIContext().getHostContext()
    if (hostContext) {
      PreferencesUtil.getInstance().ensureInit(hostContext)
    }
    this.userViewModel.init()
  }

  /**
   * 登录成功回调
   * 流程：ViewModel 登录 → 更新 AppStorage 全局状态 → 跳转首页
   * @param name 登录使用的用户名
   */
  private onLoginSuccess(name: string): void {
    this.userViewModel.login(name)
    // 同步更新 AppStorage，其他页面通过 @StorageLink 可实时感知
    AppStorage.setOrCreate('userName', name)
    AppStorage.setOrCreate('isLogin', true)
    try {
      this.getUIContext().getRouter().replaceUrl({ url: 'pages/Index' })
    } catch (e) {
      console.error('replaceUrl failed: ' + JSON.stringify(e))
    }
  }

  build() {
    Scroll() {
      Column() {
        Blank()
          .height(60)

        Text('银龄通')
          .fontSize(this.scaledSize(42))
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A56DB')
          .accessibilityText('银龄通应用名称')
          .accessibilityLevel('yes')

        Text('智慧养老服务平台')
          .fontSize(this.scaledSize(20))
          .fontColor('#666666')
          .margin({ top: 12 })
          .accessibilityText('智慧养老服务平台副标题')
          .accessibilityLevel('yes')

        Blank()
          .height(48)

        Column() {
          Button('一键登录')
            .width('85%')
            .height(56)
            .fontSize(this.scaledSize(24))
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.White)
            .linearGradient({
              direction: GradientDirection.Right,
              colors: [['#1A56DB', 0.0], ['#7B61FF', 1.0]]
            })
            .borderRadius(28)
            .accessibilityText('一键登录，使用默认用户张爷爷登录')
            .accessibilityLevel('yes')
            .onClick(() => {
              this.onLoginSuccess('张爷爷')
            })

          Text('无需输入，点击即可登录')
            .fontSize(this.scaledSize(14))
            .fontColor('#999999')
            .margin({ top: 12 })
            .accessibilityText('一键登录提示文字')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .margin({ bottom: 36 })

        Row() {
          Row()
            .width(40)
            .height(1)
            .backgroundColor('#CCCCCC')

          Text('或输入姓名登录')
            .fontSize(this.scaledSize(16))
            .fontColor('#999999')
            .margin({ left: 16, right: 16 })

          Row()
            .width(40)
            .height(1)
            .backgroundColor('#CCCCCC')
        }
        .margin({ bottom: 36 })

        Column() {
          TextInput({ placeholder: '请输入您的姓名' })
            .width('85%')
            .height(56)
            .fontSize(this.scaledSize(22))
            .placeholderFont({ size: this.scaledSize(20) })
            .placeholderColor('#BBBBBB')
            .fontColor('#1A56DB')
            .border({ width: 2, color: '#1A56DB', radius: 12 })
            .backgroundColor(Color.White)
            .type(InputType.Normal)
            .maxLength(20)
            .enableKeyboardOnFocus(true)
            .textAlign(TextAlign.Center)
            .accessibilityText('请输入您的姓名')
            .accessibilityLevel('yes')
            .onChange((value: string) => {
              this.inputName = value
            })

          Button('确认登录')
            .width('85%')
            .height(56)
            .fontSize(this.scaledSize(22))
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.White)
            .backgroundColor('#1A56DB')
            .borderRadius(28)
            .margin({ top: 24 })
            .enabled(this.inputName.trim().length > 0)
            .opacity(this.inputName.trim().length > 0 ? 1.0 : 0.5)
            .accessibilityText('确认登录按钮，输入姓名后点击登录')
            .accessibilityLevel('yes')
            .onClick(() => {
              if (this.inputName.trim().length > 0) {
                this.onLoginSuccess(this.inputName.trim())
              }
            })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)

        Blank()
          .height(60)

        Text('游客模式')
          .fontSize(this.scaledSize(18))
          .fontColor('#999999')
          .decoration({ type: TextDecorationType.Underline, color: '#999999' })
          .accessibilityText('游客模式入口，部分功能受限')
          .accessibilityLevel('yes')
          .onClick(() => {
            AppStorage.setOrCreate('isLogin', false)
            AppStorage.setOrCreate('userName', '游客')
            try {
              this.getUIContext().getRouter().replaceUrl({ url: 'pages/Index' })
            } catch (e) {
              console.error('replaceUrl failed: ' + JSON.stringify(e))
            }
          })

        Text('游客模式下部分功能受限')
          .fontSize(this.scaledSize(12))
          .fontColor('#CCCCCC')
          .margin({ top: 8 })
          .accessibilityText('游客模式功能受限提示')
          .accessibilityLevel('yes')

        Blank()
          .height(40)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
    .scrollBar(BarState.Off)
  }
}
