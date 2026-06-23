import { AppColors, AppSizes, scaledSize } from '../common/constants/Styles'
import { Constants } from '../common/constants/Constants'
import { UserViewModel } from '../viewmodel/UserViewModel'
import { PreferencesUtil } from '../common/utils/PreferencesUtil'

const FONT_LEVEL_LABELS: string[] = ['标准', '较大', '最大']

@Entry
@Component
struct Settings {
  @StorageLink('fontSizeLevel') fontSizeLevel: number = 0
  @StorageLink('isLogin') isLogin: boolean = false
  @StorageLink('userName') userName: string = '游客'
  @State isNotificationOn: boolean = true
  private userViewModel: UserViewModel = new UserViewModel()

  private sz(base: number): number {
    return scaledSize(base, this.fontSizeLevel)
  }

  aboutToAppear(): void {
    const hostContext = this.getUIContext().getHostContext()
    if (hostContext) {
      PreferencesUtil.getInstance().ensureInit(hostContext)
    }
    this.userViewModel.init()
  }

  private handleLogout(): void {
    this.userViewModel.logout()
    AppStorage.setOrCreate('isLogin', false)
    AppStorage.setOrCreate('userName', '')
    try {
      this.getUIContext().getRouter().replaceUrl({ url: 'pages/LoginPage' })
    } catch (e) {
      console.error('replaceUrl failed: ' + JSON.stringify(e))
    }
  }

  build() {
    Column() {
      Row() {
        Text('<')
          .fontSize(this.sz(24))
          .fontColor(AppColors.TEXT_PRIMARY)
          .padding({ right: 8 })
          .accessibilityText('返回')
          .accessibilityLevel('yes')
          .onClick(() => {
            this.getUIContext().getRouter().back()
          })

        Text('设置')
          .fontSize(this.sz(22))
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Blank()
          .width(32)
      }
      .width('100%')
      .height(AppSizes.BAR_HEIGHT)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor(AppColors.BG_CARD)

      Scroll() {
        Column({ space: AppSizes.SECTION_SPACE }) {
          Column() {
            Row() {
              Column() {
                Text(this.userName)
                  .fontSize(this.sz(20))
                  .fontWeight(FontWeight.Medium)
                  .fontColor(AppColors.TEXT_PRIMARY)

                Text('已登录')
                  .fontSize(this.sz(14))
                  .fontColor(AppColors.SUCCESS)
                  .margin({ top: 4 })
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
            }
            .width('100%')
            .padding(20)
            .backgroundColor(AppColors.BG_CARD)
            .borderRadius(AppSizes.CARD_RADIUS)
          }

          Column() {
            Row() {
              Text('消息通知')
                .fontSize(this.sz(17))
                .fontColor(AppColors.TEXT_PRIMARY)
                .layoutWeight(1)

              Toggle({ type: ToggleType.Switch, isOn: this.isNotificationOn })
                .width(48)
                .height(28)
                .selectedColor(AppColors.PRIMARY)
                .onChange((isOn: boolean) => {
                  this.isNotificationOn = isOn
                })
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 16, bottom: 16 })
            .alignItems(VerticalAlign.Center)

            Divider().color(AppColors.DIVIDER).padding({ left: 20, right: 20 })

            Row() {
              Text('紧急联系人管理')
                .fontSize(this.sz(17))
                .fontColor(AppColors.TEXT_PRIMARY)
                .layoutWeight(1)

              Text('>')
                .fontSize(this.sz(18))
                .fontColor(AppColors.TEXT_HINT)
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 16, bottom: 16 })
            .alignItems(VerticalAlign.Center)
            .accessibilityText('紧急联系人管理')
            .accessibilityLevel('yes')
            .onClick(() => {
              this.getUIContext().getRouter().pushUrl({ url: 'pages/EmergencyContact' })
            })
          }
          .width('100%')
          .backgroundColor(AppColors.BG_CARD)
          .borderRadius(AppSizes.CARD_RADIUS)
          .clip(true)

          Column() {
            Row() {
              Text('字体大小')
                .fontSize(this.sz(17))
                .fontColor(AppColors.TEXT_PRIMARY)
                .layoutWeight(1)

              Text(FONT_LEVEL_LABELS[this.fontSizeLevel])
                .fontSize(this.sz(15))
                .fontColor(AppColors.PRIMARY)
                .fontWeight(FontWeight.Medium)
                .padding({ left: 12, right: 12, top: 4, bottom: 4 })
                .backgroundColor(AppColors.PRIMARY_LIGHT)
                .borderRadius(12)
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 16, bottom: 8 })
            .alignItems(VerticalAlign.Center)
            .accessibilityText(`字体大小：${FONT_LEVEL_LABELS[this.fontSizeLevel]}`)
            .accessibilityLevel('yes')

            Row() {
              Slider({
                value: this.fontSizeLevel,
                min: AppSizes.FONT_LEVEL_STANDARD,
                max: AppSizes.FONT_LEVEL_MAX,
                step: 1,
                style: SliderStyle.OutSet
              })
              .layoutWeight(1)
              .trackColor(AppColors.ICON_BG)
              .selectedColor(AppColors.PRIMARY)
              .blockColor(AppColors.PRIMARY)
              .trackThickness(6)
              .showSteps(true)
              .accessibilityText('字体大小调节滑块')
              .accessibilityLevel('yes')
              .onChange((value: number) => {
                const level: number = Math.round(value)
                this.fontSizeLevel = level
                AppStorage.setOrCreate('fontSizeLevel', level)
                PreferencesUtil.getInstance().put(Constants.KEY_FONT_SIZE_LEVEL, level)
              })
            }
            .width('100%')
            .padding({ left: 20, right: 20, bottom: 8 })

            Row() {
              ForEach(FONT_LEVEL_LABELS, (label: string, index?: number) => {
                Text(label)
                  .fontSize(this.sz(12))
                  .fontColor(this.fontSizeLevel === index ? AppColors.PRIMARY : AppColors.TEXT_HINT)
                  .layoutWeight(1)
                  .textAlign(TextAlign.Center)
              }, (label: string, index?: number) => `${index}`)
            }
            .width('100%')
            .padding({ left: 20, right: 20, bottom: 8 })

            Row() {
              Text('预览效果')
                .fontSize(this.sz(14))
                .fontColor(AppColors.TEXT_SECONDARY)
                .margin({ right: 12 })

              Text('银龄通')
                .fontSize(this.sz(20))
                .fontWeight(FontWeight.Bold)
                .fontColor(AppColors.PRIMARY)
            }
            .width('100%')
            .padding({ left: 20, right: 20, bottom: 20 })
            .alignItems(VerticalAlign.Center)
          }
          .width('100%')
          .backgroundColor(AppColors.BG_CARD)
          .borderRadius(AppSizes.CARD_RADIUS)

          Column() {
            Row() {
              Text('关于银龄通')
                .fontSize(this.sz(17))
                .fontColor(AppColors.TEXT_PRIMARY)
                .layoutWeight(1)

              Text('v1.0.0')
                .fontSize(this.sz(14))
                .fontColor(AppColors.TEXT_HINT)
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 16, bottom: 16 })
            .alignItems(VerticalAlign.Center)

            Divider().color(AppColors.DIVIDER).padding({ left: 20, right: 20 })

            Row() {
              Text('隐私政策')
                .fontSize(this.sz(17))
                .fontColor(AppColors.TEXT_PRIMARY)
                .layoutWeight(1)

              Text('>')
                .fontSize(this.sz(18))
                .fontColor(AppColors.TEXT_HINT)
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 16, bottom: 16 })
            .alignItems(VerticalAlign.Center)

            Divider().color(AppColors.DIVIDER).padding({ left: 20, right: 20 })

            Row() {
              Text('用户协议')
                .fontSize(this.sz(17))
                .fontColor(AppColors.TEXT_PRIMARY)
                .layoutWeight(1)

              Text('>')
                .fontSize(this.sz(18))
                .fontColor(AppColors.TEXT_HINT)
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 16, bottom: 16 })
            .alignItems(VerticalAlign.Center)
          }
          .width('100%')
          .backgroundColor(AppColors.BG_CARD)
          .borderRadius(AppSizes.CARD_RADIUS)
          .clip(true)

          Button('退出登录')
            .width('92%')
            .height(AppSizes.BUTTON_HEIGHT)
            .fontSize(this.sz(20))
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.TEXT_WHITE)
            .backgroundColor(AppColors.DANGER)
            .borderRadius(AppSizes.BUTTON_RADIUS)
            .margin({ top: 24, bottom: 40 })
            .accessibilityText('退出登录')
            .accessibilityLevel('yes')
            .onClick(() => {
              this.handleLogout()
            })
        }
        .width('92%')
        .padding({ top: 16 })
      }
      .scrollBar(BarState.Off)
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_PAGE)
    .alignItems(HorizontalAlign.Center)
  }
}
