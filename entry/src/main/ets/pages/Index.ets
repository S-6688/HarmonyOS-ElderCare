import { call } from '@kit.TelephonyKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { HealthData } from '../model/HealthData'
import { MedicineReminder } from '../model/MedicineReminder'
import { EmergencyContact as ContactModel } from '../model/EmergencyContact'
import { HealthViewModel } from '../viewmodel/HealthViewModel'
import { AppColors, AppSizes, scaledSize } from '../common/constants/Styles'
import { Constants } from '../common/constants/Constants'
import { PreferencesUtil } from '../common/utils/PreferencesUtil'

class HealthCardInfo {
  type: string = ''
  value: string = ''
  unit: string = ''
  color1: string = ''
  color2: string = ''
}

@Entry
@Component
struct Index {
  @State currentIndex: number = 0
  @StorageLink('fontSizeLevel') fontSizeLevel: number = 0
  @StorageLink('userName') userName: string = '游客'
  @StorageLink('isLogin') isLogin: boolean = false
  @State greeting: string = '早上好'
  @State currentDate: string = ''
  healthCards: HealthCardInfo[] = []
  medicineReminders: MedicineReminder[] = []
  @State emergencyContacts: ContactModel[] = []
  private healthViewModel: HealthViewModel = new HealthViewModel()

  private sz(base: number): number {
    return scaledSize(base, this.fontSizeLevel)
  }

  aboutToAppear(): void {
    const hostContext = this.getUIContext().getHostContext()
    if (hostContext) {
      PreferencesUtil.getInstance().ensureInit(hostContext)
    }
    this.checkLoginStatus()
    this.updateGreeting()
    this.loadHealthData()
    this.loadMedicineReminders()
    this.loadEmergencyContacts()
  }

  private checkLoginStatus(): void {
    const loginStatus: boolean = PreferencesUtil.getInstance().getBoolean(Constants.KEY_IS_LOGIN, false)
    if (!loginStatus) {
      try {
        this.getUIContext().getRouter().replaceUrl({ url: 'pages/LoginPage' })
      } catch (e) {
        console.error('replaceUrl failed: ' + JSON.stringify(e))
      }
    }
  }

  private updateGreeting(): void {
    const hour: number = new Date().getHours()
    if (hour >= 6 && hour < 12) {
      this.greeting = '早上好'
    } else if (hour >= 12 && hour < 18) {
      this.greeting = '下午好'
    } else {
      this.greeting = '晚上好'
    }
    const now: Date = new Date()
    const weekDays: string[] = ['周日', '周一', '周二', '周三', '周四', '周五', '周六']
    this.currentDate = `${now.getMonth() + 1}月${now.getDate()}日 ${weekDays[now.getDay()]}`
  }

  private loadHealthData(): void {
    const card1: HealthCardInfo = new HealthCardInfo()
    card1.type = '血压'; card1.value = '120/80'; card1.unit = 'mmHg'
    card1.color1 = '#1A56DB'; card1.color2 = '#5B8DEF'
    const card2: HealthCardInfo = new HealthCardInfo()
    card2.type = '血糖'; card2.value = '5.6'; card2.unit = 'mmol/L'
    card2.color1 = '#7B61FF'; card2.color2 = '#B8A9FF'
    const card3: HealthCardInfo = new HealthCardInfo()
    card3.type = '心率'; card3.value = '72'; card3.unit = '次/分'
    card3.color1 = '#E74C3C'; card3.color2 = '#F1948A'
    this.healthCards = [card1, card2, card3]
  }

  private loadMedicineReminders(): void {
    const r1: MedicineReminder = new MedicineReminder(1, '降压药', '1片', '08:00', [1, 2, 3, 4, 5, 6, 7], true, '饭后服用')
    const r2: MedicineReminder = new MedicineReminder(2, '钙片', '2片', '12:00', [1, 2, 3, 4, 5, 6, 7], true, '随餐服用')
    this.medicineReminders = [r1, r2]
  }

  private loadEmergencyContacts(): void {
    const json: string = PreferencesUtil.getInstance().getString(Constants.KEY_EMERGENCY_CONTACTS, '')
    if (json.length > 0) {
      try {
        const arr: Object[] = JSON.parse(json) as Object[]
        const loaded: ContactModel[] = []
        for (const item of arr) {
          const obj: Record<string, Object> = item as Record<string, Object>
          const c: ContactModel = new ContactModel(
            obj['id'] as number,
            obj['name'] as string,
            obj['phoneNumber'] as string,
            obj['relationship'] as string,
            obj['isPriority'] as boolean
          )
          loaded.push(c)
        }
        this.emergencyContacts = loaded
      } catch (e) {
        this.emergencyContacts = []
      }
    }
  }

  private makeCall(phone: string): void {
    const isSupport: boolean = call.hasVoiceCapability()
    if (isSupport) {
      call.makeCall(phone, (err: BusinessError) => {
        if (err) {
          console.error('makeCall failed: ' + JSON.stringify(err))
        }
      })
    }
  }

  private handleEmergencyCall(): void {
    let priorityContact: ContactModel | null = null
    for (const c of this.emergencyContacts) {
      if (c.isPriority) {
        priorityContact = c
        break
      }
    }
    if (priorityContact) {
      this.getUIContext().showAlertDialog({
        title: '紧急呼叫',
        message: `将拨打优先联系人 ${priorityContact.name} 的电话：${priorityContact.phoneNumber}`,
        autoCancel: true,
        alignment: DialogAlignment.Center,
        primaryButton: {
          value: '取消',
          action: () => {}
        },
        secondaryButton: {
          value: '确认拨打',
          fontColor: AppColors.DANGER,
          action: () => {
            this.makeCall(priorityContact!.phoneNumber)
          }
        }
      })
    } else if (this.emergencyContacts.length > 0) {
      const names: string[] = []
      for (const c of this.emergencyContacts) {
        names.push(c.name + '(' + c.phoneNumber + ')')
      }
      this.getUIContext().showAlertDialog({
        title: '选择联系人',
        message: '未设置优先联系人，请选择要拨打的联系人：\n' + names.join('\n'),
        autoCancel: true,
        alignment: DialogAlignment.Center,
        primaryButton: {
          value: '取消',
          action: () => {}
        },
        secondaryButton: {
          value: `拨打 ${this.emergencyContacts[0].name}`,
          fontColor: AppColors.DANGER,
          action: () => {
            this.makeCall(this.emergencyContacts[0].phoneNumber)
          }
        }
      })
    } else {
      this.getUIContext().showAlertDialog({
        title: '提示',
        message: '暂无紧急联系人，请先在紧急联系人页面添加',
        autoCancel: true,
        alignment: DialogAlignment.Center,
        primaryButton: {
          value: '去添加',
          action: () => {
            this.getUIContext().getRouter().pushUrl({ url: 'pages/EmergencyContact' })
          }
        },
        secondaryButton: {
          value: '关闭',
          action: () => {}
        }
      })
    }
  }

  @Builder
  TabBuilder(title: string, index: number) {
    Column() {
      Text(title)
        .fontSize(this.sz(13))
        .fontWeight(this.currentIndex === index ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(this.currentIndex === index ? '#1A56DB' : '#999999')
        .margin({ top: 4 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Column() {
      Row() {
        Text('银龄通')
          .fontSize(this.sz(20))
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A56DB')
          .layoutWeight(1)

        Text('设置')
          .fontSize(this.sz(16))
          .fontColor('#1A56DB')
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .borderRadius(20)
          .backgroundColor('#EBF0FF')
          .accessibilityText('设置按钮')
          .accessibilityLevel('yes')
          .onClick(() => {
            this.getUIContext().getRouter().pushUrl({ url: 'pages/Settings' })
          })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 12, bottom: 8 })
      .backgroundColor(Color.White)

      Tabs({ index: this.currentIndex }) {
        TabContent() {
          this.HomeContent()
        }
        .tabBar(this.TabBuilder('首页', 0))

        TabContent() {
          this.HealthTabContent()
        }
        .tabBar(this.TabBuilder('健康记录', 1))

        TabContent() {
          this.KnowledgeTabContent()
        }
        .tabBar(this.TabBuilder('养生知识', 2))
      }
      .scrollable(false)
      .barPosition(BarPosition.End)
      .barHeight(56)
      .barBackgroundColor(Color.White)
      .onChange((index: number) => {
        this.currentIndex = index
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
    .padding({ bottom: 34 })
  }

  @Builder
  HomeContent() {
    Scroll() {
      Column() {
        Row() {
          Column() {
            Text(`${this.greeting}，${this.userName}`)
              .fontSize(this.sz(26))
              .fontWeight(FontWeight.Bold)
              .fontColor('#1A1A1A')

            Text(this.currentDate)
              .fontSize(this.sz(16))
              .fontColor('#666666')
              .margin({ top: 4 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Button('一键呼叫')
            .height(44)
            .fontSize(this.sz(16))
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.White)
            .backgroundColor(AppColors.DANGER)
            .borderRadius(AppSizes.BUTTON_RADIUS)
            .shadow({ radius: 8, color: '#E8404040', offsetY: 4 })
            .padding({ left: 16, right: 16 })
            .accessibilityText('一键呼叫紧急联系人')
            .accessibilityLevel('yes')
            .onClick(() => {
              this.handleEmergencyCall()
            })
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 20, bottom: 16 })
        .alignItems(VerticalAlign.Center)

        Column() {
          Text('健康概览')
            .fontSize(this.sz(20))
            .fontWeight(FontWeight.Medium)
            .fontColor('#1A1A1A')
            .margin({ bottom: 12 })

          Swiper() {
            ForEach(this.healthCards, (card: HealthCardInfo, index?: number) => {
              Column() {
                Text(card.type)
                  .fontSize(this.sz(18))
                  .fontColor(Color.White)
                  .margin({ bottom: 8 })

                Row() {
                  Text(card.value)
                    .fontSize(this.sz(36))
                    .fontWeight(FontWeight.Bold)
                    .fontColor(Color.White)

                  Text(card.unit)
                    .fontSize(this.sz(14))
                    .fontColor('#D6E4FF')
                    .margin({ left: 8, bottom: 6 })
                }
              }
              .width('100%')
              .height(120)
              .justifyContent(FlexAlign.Center)
              .borderRadius(16)
              .padding({ left: 24, right: 24 })
              .linearGradient({
                angle: 135,
                colors: [[card.color1, 0.0], [card.color2, 1.0]]
              })
            }, (card: HealthCardInfo, index?: number) => `${index}_${card.type}`)
          }
          .autoPlay(true)
          .interval(3000)
          .duration(800)
          .indicator(new DotIndicator()
            .itemWidth(8)
            .itemHeight(8)
            .selectedItemWidth(16)
            .selectedItemHeight(8)
            .color('#CCCCCC')
            .selectedColor('#1A56DB'))
          .height(140)
        }
        .width('90%')
        .margin({ top: 8 })

        Column() {
          Row() {
            Text('今日用药提醒')
              .fontSize(this.sz(20))
              .fontWeight(FontWeight.Medium)
              .fontColor('#1A1A1A')
              .layoutWeight(1)

            Text('全部 >')
              .fontSize(this.sz(14))
              .fontColor('#1A56DB')
              .onClick(() => {
                this.getUIContext().getRouter().pushUrl({ url: 'pages/MedicationListPage' })
              })
          }
          .width('100%')
          .margin({ bottom: 12 })

          if (this.medicineReminders.length === 0) {
            Text('今日暂无用药提醒')
              .fontSize(this.sz(16))
              .fontColor('#999999')
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding(24)
          } else {
            ForEach(this.medicineReminders, (item: MedicineReminder, index?: number) => {
              Row() {
                Column() {
                  Text(item.medicineName)
                    .fontSize(this.sz(18))
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#1A1A1A')

                  Text(`${item.dosage} · ${item.note}`)
                    .fontSize(this.sz(14))
                    .fontColor('#666666')
                    .margin({ top: 4 })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                Column() {
                  Text(item.time)
                    .fontSize(this.sz(18))
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#1A56DB')
                }
                .alignItems(HorizontalAlign.End)
              }
              .width('100%')
              .padding(16)
              .backgroundColor(Color.White)
              .borderRadius(12)
              .margin({ bottom: 8 })
              .accessibilityText(`${item.medicineName}，剂量${item.dosage}，时间${item.time}，${item.note}`)
              .accessibilityLevel('yes')
            }, (item: MedicineReminder, index?: number) => `${item.id}`)
          }
        }
        .width('90%')
        .margin({ top: 24 })

        Column() {
          Text('快捷入口')
            .fontSize(this.sz(20))
            .fontWeight(FontWeight.Medium)
            .fontColor('#1A1A1A')
            .margin({ bottom: 8 })

          Row() {
            Column() {
              Column() {
                Text('健')
                  .fontSize(this.sz(24))
                  .fontColor(Color.White)
                  .fontWeight(FontWeight.Bold)
              }
              .width(48)
              .height(48)
              .borderRadius(24)
              .justifyContent(FlexAlign.Center)
              .linearGradient({ angle: 135, colors: [['#1A56DB', 0.0], ['#5B8DEF', 1.0]] })

              Text('健康记录')
                .fontSize(this.sz(14))
                .fontColor('#333333')
                .margin({ top: 8 })
            }
            .layoutWeight(1)
            .onClick(() => {
              this.getUIContext().getRouter().pushUrl({ url: 'pages/HealthRecord' })
            })

            Column() {
              Column() {
                Text('知')
                  .fontSize(this.sz(24))
                  .fontColor(Color.White)
                  .fontWeight(FontWeight.Bold)
              }
              .width(48)
              .height(48)
              .borderRadius(24)
              .justifyContent(FlexAlign.Center)
              .linearGradient({ angle: 135, colors: [['#7B61FF', 0.0], ['#B8A9FF', 1.0]] })

              Text('养生知识')
                .fontSize(this.sz(14))
                .fontColor('#333333')
                .margin({ top: 8 })
            }
            .layoutWeight(1)
            .onClick(() => {
              this.getUIContext().getRouter().pushUrl({ url: 'pages/Knowledge' })
            })

            Column() {
              Column() {
                Text('联')
                  .fontSize(this.sz(24))
                  .fontColor(Color.White)
                  .fontWeight(FontWeight.Bold)
              }
              .width(48)
              .height(48)
              .borderRadius(24)
              .justifyContent(FlexAlign.Center)
              .linearGradient({ angle: 135, colors: [['#E74C3C', 0.0], ['#F1948A', 1.0]] })

              Text('紧急联系')
                .fontSize(this.sz(14))
                .fontColor('#333333')
                .margin({ top: 8 })
            }
            .layoutWeight(1)
            .onClick(() => {
              this.getUIContext().getRouter().pushUrl({ url: 'pages/EmergencyContact' })
            })
          }
          .width('100%')
        }
        .width('90%')
        .margin({ top: 10 })
        Blank()
          .height(80)

      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .scrollBar(BarState.Off)
    .layoutWeight(1)

  }

  @Builder
  HealthTabContent() {
    Column() {
      Text('健康记录')
        .fontSize(this.sz(24))
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A1A1A')
        .margin({ top: 20, bottom: 16 })

      Text('暂无健康数据')
        .fontSize(this.sz(18))
        .fontColor('#999999')
        .margin({ top: 40 })

      Button('添加健康记录')
        .width('70%')
        .height(56)
        .fontSize(this.sz(20))
        .fontColor(Color.White)
        .backgroundColor('#1A56DB')
        .borderRadius(28)
        .margin({ top: 24 })
        .accessibilityText('添加健康记录')
        .accessibilityLevel('yes')
        .onClick(() => {
          this.getUIContext().getRouter().pushUrl({ url: 'pages/HealthRecord' })
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  KnowledgeTabContent() {
    Column() {
      Text('养生知识')
        .fontSize(this.sz(24))
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A1A1A')
        .margin({ top: 20, bottom: 16 })

      List({ space: 12 }) {
        ListItem() {
          Row() {
            Column() {
              Text('老年人冬季养生指南')
                .fontSize(this.sz(18))
                .fontWeight(FontWeight.Medium)
                .fontColor('#1A1A1A')
              Text('了解冬季如何保持身体健康')
                .fontSize(this.sz(14))
                .fontColor('#666666')
                .margin({ top: 4 })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Text('>')
              .fontSize(this.sz(18))
              .fontColor('#999999')
          }
          .padding(16)
          .backgroundColor(Color.White)
          .borderRadius(12)
        }
        .onClick(() => {
          this.getUIContext().getRouter().pushUrl({ url: 'pages/KnowledgeDetail', params: { articleId: 1 } })
        })

        ListItem() {
          Row() {
            Column() {
              Text('高血压日常管理方法')
                .fontSize(this.sz(18))
                .fontWeight(FontWeight.Medium)
                .fontColor('#1A1A1A')
              Text('科学控制血压，守护心脑健康')
                .fontSize(this.sz(14))
                .fontColor('#666666')
                .margin({ top: 4 })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Text('>')
              .fontSize(this.sz(18))
              .fontColor('#999999')
          }
          .padding(16)
          .backgroundColor(Color.White)
          .borderRadius(12)
        }
        .onClick(() => {
          this.getUIContext().getRouter().pushUrl({ url: 'pages/KnowledgeDetail', params: { articleId: 2 } })
        })
      }
      .width('90%')
      .margin({ top: 12 })

      Text('查看更多')
        .fontSize(this.sz(16))
        .fontColor('#1A56DB')
        .margin({ top: 16 })
        .onClick(() => {
          this.getUIContext().getRouter().pushUrl({ url: 'pages/Knowledge' })
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
    .alignItems(HorizontalAlign.Center)
  }
}
