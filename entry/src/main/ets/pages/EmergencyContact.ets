/**
 * EmergencyContact - 紧急联系人管理页面
 * 功能：
 *   - 展示紧急联系人列表，优先联系人置顶并高亮
 *   - 添加/编辑联系人（半模态弹窗 Sheet）
 *   - 拨打电话（确认对话框防误触）
 *   - 一键紧急呼叫（优先联系人 > 首个联系人 > 提示添加）
 *   - 左滑快捷操作：切换优先/删除
 *   - 联系人数据持久化到 Preferences（JSON 格式）
 * 优先联系人规则：全局唯一，设置新优先时自动取消旧的
 */
import { call } from '@kit.TelephonyKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { AppColors, AppSizes, scaledSize } from '../common/constants/Styles'
import { Constants } from '../common/constants/Constants'
import { EmergencyContact as ContactModel } from '../model/EmergencyContact'
import { PreferencesUtil } from '../common/utils/PreferencesUtil'

@Entry
@Component
struct EmergencyContact {
  @StorageLink('fontSizeLevel') fontSizeLevel: number = 0
  @StorageLink('isLogin') isLogin: boolean = false
  @State contacts: ContactModel[] = []     // 联系人列表（优先联系人排在前面）
  @State showSheet: boolean = false        // 是否显示添加/编辑弹窗
  @State isEditMode: boolean = false       // 弹窗模式：false=添加，true=编辑
  @State editingId: number = 0             // 正在编辑的联系人ID
  @State editName: string = ''             // 编辑中的姓名
  @State editPhone: string = ''            // 编辑中的电话
  @State editRelation: string = ''         // 编辑中的关系
  @State editPriority: boolean = false     // 编辑中的优先状态
  private nextId: number = 1               // 下一个新联系人的ID

  private sz(base: number): number {
    return scaledSize(base, this.fontSizeLevel)
  }

  aboutToAppear(): void {
    const hostContext = this.getUIContext().getHostContext()
    if (hostContext) {
      PreferencesUtil.getInstance().ensureInit(hostContext)
    }
    this.checkLoginStatus()
    this.loadContacts()
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

  /**
   * 从 Preferences 加载联系人数据
   * 流程：读取JSON字符串 → 解析为对象数组 → 重建 ContactModel → 排序（优先在前）
   * 若无数据或解析失败，加载示例联系人
   */
  private loadContacts(): void {
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
          if (c.id >= this.nextId) {
            this.nextId = c.id + 1
          }
        }
        this.sortContacts(loaded)
        this.contacts = loaded
      } catch (e) {
        this.loadSampleContacts()
      }
    } else {
      this.loadSampleContacts()
    }
  }

  /** 加载示例联系人（首次使用时），并持久化到 Preferences */
  private loadSampleContacts(): void {
    const c1: ContactModel = new ContactModel(1, '张医生', '13800138000', '家庭医生', true)
    const c2: ContactModel = new ContactModel(2, '李护士', '13900139000', '社区护士', false)
    const c3: ContactModel = new ContactModel(3, '王阿姨', '13700137000', '邻居', false)
    this.contacts = [c1, c2, c3]
    this.nextId = 4
    this.saveContacts()
  }

  /** 保存联系人到 Preferences（JSON格式）并同步到 AppStorage */
  private saveContacts(): void {
    const json: string = JSON.stringify(this.contacts)
    PreferencesUtil.getInstance().put(Constants.KEY_EMERGENCY_CONTACTS, json)
    AppStorage.setOrCreate('emergencyContacts', json)
  }

  /** 按优先联系人排序（优先的排前面） */
  private sortContacts(list: ContactModel[]): void {
    list.sort((a: ContactModel, b: ContactModel) => {
      if (a.isPriority && !b.isPriority) {
        return -1
      }
      if (!a.isPriority && b.isPriority) {
        return 1
      }
      return 0
    })
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

  private showCallConfirm(name: string, phone: string): void {
    this.getUIContext().showAlertDialog({
      title: '确认拨打',
      message: `即将拨打 ${name} 的电话：${phone}`,
      autoCancel: true,
      alignment: DialogAlignment.Center,
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '拨打',
        fontColor: AppColors.DANGER,
        action: () => {
          this.makeCall(phone)
        }
      }
    })
  }

  private openAddSheet(): void {
    this.isEditMode = false
    this.editingId = 0
    this.editName = ''
    this.editPhone = ''
    this.editRelation = ''
    this.editPriority = false
    this.getUIContext().animateTo({ duration: 300, curve: Curve.EaseOut }, () => {
      this.showSheet = true
    })
  }

  private openEditSheet(contact: ContactModel): void {
    this.isEditMode = true
    this.editingId = contact.id
    this.editName = contact.name
    this.editPhone = contact.phoneNumber
    this.editRelation = contact.relationship
    this.editPriority = contact.isPriority
    this.getUIContext().animateTo({ duration: 300, curve: Curve.EaseOut }, () => {
      this.showSheet = true
    })
  }

  /**
   * 保存联系人（添加或编辑）
   * 优先联系人规则：设为优先时，自动取消其他联系人的优先状态（全局唯一）
   */
  private saveContact(): void {
    if (this.editName.trim().length === 0 || this.editPhone.trim().length === 0) {
      return
    }
    if (this.isEditMode) {
      for (const c of this.contacts) {
        if (c.id === this.editingId) {
          c.name = this.editName.trim()
          c.phoneNumber = this.editPhone.trim()
          c.relationship = this.editRelation.trim()
          if (this.editPriority) {
            for (const other of this.contacts) {
              if (other.id !== this.editingId) {
                other.isPriority = false
              }
            }
          }
          c.isPriority = this.editPriority
          break
        }
      }
    } else {
      if (this.editPriority) {
        for (const c of this.contacts) {
          c.isPriority = false
        }
      }
      const newContact: ContactModel = new ContactModel(
        this.nextId,
        this.editName.trim(),
        this.editPhone.trim(),
        this.editRelation.trim(),
        this.editPriority
      )
      this.nextId++
      this.contacts.push(newContact)
    }
    this.sortContacts(this.contacts)
    this.contacts = [...this.contacts]
    this.saveContacts()
    this.showSheet = false
  }

  private deleteContact(id: number): void {
    this.contacts = this.contacts.filter((c: ContactModel) => c.id !== id)
    this.saveContacts()
  }

  /**
   * 切换联系人的优先状态
   * 设为优先时，自动取消其他联系人的优先状态（保证全局唯一优先联系人）
   */
  private togglePriority(id: number): void {
    let target: ContactModel | null = null
    for (const c of this.contacts) {
      if (c.id === id) {
        target = c
      }
    }
    if (target) {
      if (!target.isPriority) {
        for (const c of this.contacts) {
          c.isPriority = false
        }
      }
      target.isPriority = !target.isPriority
      this.sortContacts(this.contacts)
      this.contacts = [...this.contacts]
      this.saveContacts()
    }
  }

  @Builder
  SheetBuilder() {
    Column() {
      Row() {
        Text(this.isEditMode ? '编辑联系人' : '添加联系人')
          .fontSize(this.sz(22))
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
          .layoutWeight(1)

        Text('X')
          .fontSize(this.sz(24))
          .fontColor(AppColors.TEXT_HINT)
          .padding(8)
          .onClick(() => {
            this.showSheet = false
          })
      }
      .width('100%')
      .padding({ left: 24, right: 24, top: 16, bottom: 8 })

      Scroll() {
        Column({ space: 16 }) {
          Column() {
            Text('姓名')
              .fontSize(this.sz(15))
              .fontColor(AppColors.TEXT_SECONDARY)
              .width('100%')
              .margin({ bottom: 8 })
            TextInput({ text: this.editName, placeholder: '请输入姓名' })
              .type(InputType.Normal)
              .fontSize(this.sz(18))
              .height(AppSizes.MIN_TOUCH)
              .enableKeyboardOnFocus(true)
              .borderRadius(12)
              .backgroundColor(AppColors.BG_CARD_SOFT)
              .onChange((value: string) => {
                this.editName = value
              })
          }

          Column() {
            Text('电话')
              .fontSize(this.sz(15))
              .fontColor(AppColors.TEXT_SECONDARY)
              .width('100%')
              .margin({ bottom: 8 })
            TextInput({ text: this.editPhone, placeholder: '请输入电话号码' })
              .type(InputType.PhoneNumber)
              .fontSize(this.sz(18))
              .height(AppSizes.MIN_TOUCH)
              .borderRadius(12)
              .backgroundColor(AppColors.BG_CARD_SOFT)
              .onChange((value: string) => {
                this.editPhone = value
              })
          }

          Column() {
            Text('关系')
              .fontSize(this.sz(15))
              .fontColor(AppColors.TEXT_SECONDARY)
              .width('100%')
              .margin({ bottom: 8 })
            TextInput({ text: this.editRelation, placeholder: '如：家庭医生、子女、配偶' })
              .fontSize(this.sz(18))
              .height(AppSizes.MIN_TOUCH)
              .borderRadius(12)
              .backgroundColor(AppColors.BG_CARD_SOFT)
              .onChange((value: string) => {
                this.editRelation = value
              })
          }

          Row() {
            Text('设为优先联系人')
              .fontSize(this.sz(16))
              .fontColor(AppColors.TEXT_PRIMARY)
              .layoutWeight(1)

            Toggle({ type: ToggleType.Switch, isOn: this.editPriority })
              .width(48)
              .height(28)
              .selectedColor(AppColors.PRIMARY)
              .onChange((isOn: boolean) => {
                this.editPriority = isOn
              })
          }
          .width('100%')
          .padding({ top: 4, bottom: 4 })

          Text('优先联系人将置顶显示，并作为"一键呼叫"的首选联系人')
            .fontSize(this.sz(12))
            .fontColor(AppColors.TEXT_HINT)
            .width('100%')

          Button(this.isEditMode ? '保存修改' : '保存')
            .width('100%')
            .height(AppSizes.BUTTON_HEIGHT)
            .fontSize(this.sz(20))
            .fontColor(AppColors.TEXT_WHITE)
            .backgroundColor(AppColors.PRIMARY)
            .borderRadius(AppSizes.BUTTON_RADIUS)
            .margin({ top: 8 })
            .accessibilityText(this.isEditMode ? '保存修改' : '保存联系人')
            .accessibilityLevel('yes')
            .onClick(() => {
              this.saveContact()
            })
        }
        .padding({ left: 24, right: 24, top: 8, bottom: 24 })
      }
      .scrollBar(BarState.Off)
      .layoutWeight(1)
    }
    .width('100%')
    .backgroundColor(AppColors.BG_CARD)
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

        Text('紧急联系人')
          .fontSize(this.sz(22))
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Text('+')
          .fontSize(this.sz(28))
          .fontColor(AppColors.PRIMARY)
          .fontWeight(FontWeight.Bold)
          .padding({ left: 12, right: 12 })
          .accessibilityText('添加联系人')
          .accessibilityLevel('yes')
          .onClick(() => {
            this.openAddSheet()
          })
      }
      .width('100%')
      .height(AppSizes.BAR_HEIGHT)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor(AppColors.BG_CARD)

      if (this.contacts.length === 0) {
        Column() {
          Text('暂无紧急联系人')
            .fontSize(this.sz(18))
            .fontColor(AppColors.TEXT_HINT)
          Text('点击右上角"+"添加')
            .fontSize(this.sz(14))
            .fontColor(AppColors.TEXT_HINT)
            .margin({ top: 4 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        List({ space: AppSizes.ITEM_SPACE }) {
          ForEach(this.contacts, (contact: ContactModel, index?: number) => {
            ListItem() {
              Row() {
                Column() {
                  Text(contact.name)
                    .fontSize(this.sz(20))
                    .fontWeight(FontWeight.Medium)
                    .fontColor(AppColors.TEXT_PRIMARY)

                  Text(`${contact.relationship} · ${contact.phoneNumber}`)
                    .fontSize(this.sz(14))
                    .fontColor(AppColors.TEXT_SECONDARY)
                    .margin({ top: 4 })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                if (contact.isPriority) {
                  Text('优先')
                    .fontSize(this.sz(12))
                    .fontColor(AppColors.TEXT_WHITE)
                    .backgroundColor(AppColors.WARNING)
                    .borderRadius(10)
                    .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                    .margin({ right: 8 })
                }

                Row({ space: 8 }) {
                  Text('拨')
                    .fontSize(this.sz(16))
                    .fontColor(AppColors.TEXT_WHITE)
                    .backgroundColor(AppColors.PRIMARY)
                    .borderRadius(16)
                    .width(AppSizes.MIN_TOUCH)
                    .height(AppSizes.MIN_TOUCH)
                    .textAlign(TextAlign.Center)
                    .accessibilityText(`拨打${contact.name}电话${contact.phoneNumber}`)
                    .accessibilityLevel('yes')
                    .onClick(() => {
                      this.showCallConfirm(contact.name, contact.phoneNumber)
                    })

                  Text('改')
                    .fontSize(this.sz(16))
                    .fontColor(AppColors.TEXT_WHITE)
                    .backgroundColor(AppColors.PURPLE)
                    .borderRadius(16)
                    .width(AppSizes.MIN_TOUCH)
                    .height(AppSizes.MIN_TOUCH)
                    .textAlign(TextAlign.Center)
                    .accessibilityText(`编辑${contact.name}`)
                    .accessibilityLevel('yes')
                    .onClick(() => {
                      this.openEditSheet(contact)
                    })

                  Text('删')
                    .fontSize(this.sz(16))
                    .fontColor(AppColors.TEXT_WHITE)
                    .backgroundColor(AppColors.DANGER)
                    .borderRadius(16)
                    .width(AppSizes.MIN_TOUCH)
                    .height(AppSizes.MIN_TOUCH)
                    .textAlign(TextAlign.Center)
                    .accessibilityText(`删除${contact.name}`)
                    .accessibilityLevel('yes')
                    .onClick(() => {
                      this.getUIContext().showAlertDialog({
                        title: '确认删除',
                        message: `确定删除联系人 ${contact.name} 吗？`,
                        autoCancel: true,
                        alignment: DialogAlignment.Center,
                        primaryButton: {
                          value: '取消',
                          action: () => {}
                        },
                        secondaryButton: {
                          value: '删除',
                          fontColor: AppColors.DANGER,
                          action: () => {
                            this.deleteContact(contact.id)
                          }
                        }
                      })
                    })
                }
              }
              .width('100%')
              .padding(AppSizes.CARD_PADDING)
              .backgroundColor(contact.isPriority ? AppColors.PRIMARY_LIGHT : AppColors.BG_CARD)
              .borderRadius(AppSizes.CARD_RADIUS)
              .alignItems(VerticalAlign.Center)
            }
            .swipeAction({
              end: {
                builder: () => {
                  this.SwipeActionBuilder(contact)
                }
              }
            })
          }, (contact: ContactModel, index?: number) => `${contact.id}_${contact.isPriority}`)
        }
        .width('92%')
        .margin({ top: 12 })
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }

      Column() {
        Row() {
          Text('提示：左滑联系人可快速切换优先或删除')
            .fontSize(this.sz(12))
            .fontColor(AppColors.TEXT_HINT)
        }
        .width('92%')
        .margin({ top: 4, bottom: 4 })

        Button('一键紧急呼叫')
          .width('90%')
          .height(AppSizes.BUTTON_HEIGHT)
          .fontSize(this.sz(22))
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_WHITE)
          .backgroundColor(AppColors.DANGER)
          .borderRadius(AppSizes.BUTTON_RADIUS)
          .shadow({ radius: 8, color: '#E8404040', offsetY: 4 })
          .accessibilityText('一键紧急呼叫')
          .accessibilityLevel('yes')
          .onClick(() => {
            this.handleEmergencyCall()
          })
      }
      .width('100%')
      .padding({ top: 8, bottom: 12 })
      .backgroundColor(AppColors.BG_CARD)
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_PAGE)
    .alignItems(HorizontalAlign.Center)
    .bindSheet($$this.showSheet, this.SheetBuilder(), {
      detents: [SheetSize.LARGE],
      backgroundColor: AppColors.BG_CARD,
      dragBar: true,
      showClose: false,
      onDisappear: () => {
        this.showSheet = false
      }
    })
  }

  private handleEmergencyCall(): void {
    let priorityContact: ContactModel | null = null
    for (const c of this.contacts) {
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
    } else if (this.contacts.length > 0) {
      const names: string[] = []
      for (const c of this.contacts) {
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
          value: `拨打 ${this.contacts[0].name}`,
          fontColor: AppColors.DANGER,
          action: () => {
            this.makeCall(this.contacts[0].phoneNumber)
          }
        }
      })
    } else {
      this.getUIContext().showAlertDialog({
        title: '提示',
        message: '暂无紧急联系人，请先添加联系人',
        autoCancel: true,
        alignment: DialogAlignment.Center,
        primaryButton: {
          value: '去添加',
          action: () => {
            this.openAddSheet()
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
  SwipeActionBuilder(contact: ContactModel) {
    Row() {
      Button(contact.isPriority ? '取消优先' : '设为优先')
        .height('100%')
        .fontSize(this.sz(14))
        .fontColor(AppColors.TEXT_WHITE)
        .backgroundColor(AppColors.WARNING)
        .borderRadius(0)
        .accessibilityText(contact.isPriority ? '取消优先联系人' : '设为优先联系人')
        .accessibilityLevel('yes')
        .onClick(() => {
          this.togglePriority(contact.id)
        })

      Button('删除')
        .height('100%')
        .fontSize(this.sz(14))
        .fontColor(AppColors.TEXT_WHITE)
        .backgroundColor(AppColors.DANGER)
        .borderRadius(0)
        .accessibilityText('删除此联系人')
        .accessibilityLevel('yes')
        .onClick(() => {
          this.deleteContact(contact.id)
        })
    }
  }
}
