import { MedicineReminder } from '../model/MedicineReminder'
import { AppColors, AppSizes } from '../common/constants/Styles'

@CustomDialog
struct AddReminderDialog {
  controller?: CustomDialogController
  @State newMedName: string = ''
  @State newDosage: string = ''
  @State newTime: string = '08:00'
  confirm: (name: string, dosage: string, time: string) => void = () => {}

  private formatTime(hour: number, minute: number): string {
    const h: string = hour < 10 ? '0' + hour.toString() : hour.toString()
    const m: string = minute < 10 ? '0' + minute.toString() : minute.toString()
    return h + ':' + m
  }

  build() {
    Column({ space: 16 }) {
      Text('添加用药提醒')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY)

      TextInput({ placeholder: '药名', text: this.newMedName })
        .height(48)
        .fontSize(16)
        .borderRadius(8)
        .padding({ left: 12, right: 12 })
        .onChange((value: string) => {
          this.newMedName = value
        })

      TextInput({ placeholder: '用量/说明（如：1片·饭后服用）', text: this.newDosage })
        .height(48)
        .fontSize(16)
        .borderRadius(8)
        .padding({ left: 12, right: 12 })
        .onChange((value: string) => {
          this.newDosage = value
        })

      Row() {
        Text('时间：')
          .fontSize(16)
          .fontColor(AppColors.TEXT_PRIMARY)
        Text(this.newTime)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.PRIMARY)
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .borderRadius(8)
          .backgroundColor(AppColors.PRIMARY_LIGHT)
          .onClick(() => {
            const parts: string[] = this.newTime.split(':')
            const d: Date = new Date()
            d.setHours(parseInt(parts[0], 10), parseInt(parts[1], 10), 0, 0)
            this.getUIContext().showTimePickerDialog({
              selected: d,
              useMilitaryTime: true,
              onAccept: (value: TimePickerResult) => {
                this.newTime = this.formatTime(value.hour as number, value.minute as number)
              },
              onCancel: () => {}
            })
          })
      }
      .width('100%')

      Row({ space: 12 }) {
        Button('取消')
          .layoutWeight(1)
          .height(44)
          .fontSize(16)
          .fontColor(AppColors.TEXT_SECONDARY)
          .backgroundColor(Color.White)
          .borderRadius(22)
          .border({ width: 1, color: AppColors.DIVIDER })
          .onClick(() => {
            this.controller?.close()
          })

        Button('确认添加')
          .layoutWeight(1)
          .height(44)
          .fontSize(16)
          .fontColor(Color.White)
          .backgroundColor(AppColors.PRIMARY)
          .borderRadius(22)
          .onClick(() => {
            if (this.newMedName.length > 0) {
              this.confirm(this.newMedName, this.newDosage, this.newTime)
              this.controller?.close()
            }
          })
      }
      .width('100%')
    }
    .padding(24)
    .backgroundColor(Color.White)
    .borderRadius(16)
  }
}

@Entry
@Component
struct MedicationListPage {
  @State reminderList: MedicineReminder[] = [
    new MedicineReminder(0, '降压药', '1片·饭后服用', '08:00', [1, 2, 3, 4, 5, 6, 7], true, '饭后服用'),
    new MedicineReminder(1, '钙片', '2片·随餐服用', '12:00', [1, 2, 3, 4, 5, 6, 7], true, '随餐服用'),
    new MedicineReminder(2, '维生素', '1片·睡前服用', '20:00', [1, 2, 3, 4, 5, 6, 7], true, '睡前服用')
  ]
  private nextId: number = 3
  private addDialogController: CustomDialogController = new CustomDialogController({
    builder: AddReminderDialog({
      confirm: (name: string, dosage: string, time: string) => {
        this.addReminder(name, dosage, time)
      }
    }),
    alignment: DialogAlignment.Center,
    autoCancel: true,
    cornerRadius: 16,
    customStyle: true
  })

  private parseTime(timeStr: string): Date {
    const parts: string[] = timeStr.split(':')
    const d: Date = new Date()
    d.setHours(parseInt(parts[0], 10), parseInt(parts[1], 10), 0, 0)
    return d
  }

  private formatTime(hour: number, minute: number): string {
    const h: string = hour < 10 ? '0' + hour.toString() : hour.toString()
    const m: string = minute < 10 ? '0' + minute.toString() : minute.toString()
    return h + ':' + m
  }

  private showTimePicker(item: MedicineReminder, index: number): void {
    const selectedDate: Date = this.parseTime(item.time)
    this.getUIContext().showTimePickerDialog({
      selected: selectedDate,
      useMilitaryTime: true,
      onAccept: (value: TimePickerResult) => {
        const newTime: string = this.formatTime(value.hour as number, value.minute as number)
        this.reminderList[index] = new MedicineReminder(
          item.id, item.medicineName, item.dosage, newTime,
          item.repeatDays, item.isEnabled, item.note
        )
      },
      onCancel: () => {}
    })
  }

  private addReminder(name: string, dosage: string, time: string): void {
    const newItem: MedicineReminder = new MedicineReminder(
      this.nextId, name, dosage, time, [1, 2, 3, 4, 5, 6, 7], true, dosage
    )
    this.nextId++
    this.reminderList.push(newItem)
  }

  private deleteReminder(index: number): void {
    this.reminderList.splice(index, 1)
  }

  private toggleReminder(item: MedicineReminder, index: number): void {
    this.reminderList[index] = new MedicineReminder(
      item.id, item.medicineName, item.dosage, item.time,
      item.repeatDays, !item.isEnabled, item.note
    )
  }



  build() {
    Column() {
      Row() {
        Text('< 返回')
          .fontSize(16)
          .fontColor(AppColors.PRIMARY)
          .padding(10)
          .onClick(() => {
            this.getUIContext().getRouter().back()
          })
        Text('用药提醒')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Text('  ')
          .fontSize(16)
          .padding(10)
      }
      .width('100%')
      .height(56)
      .padding({ left: 4, right: 4 })
      .backgroundColor(Color.White)

      if (this.reminderList.length === 0) {
        Column() {
          Text('暂无用药提醒')
            .fontSize(18)
            .fontColor(AppColors.TEXT_HINT)
            .margin({ top: 120 })
        }
        .width('100%')
        .layoutWeight(1)
      } else {
        List({ space: 10 }) {
          ForEach(this.reminderList, (item: MedicineReminder, index?: number) => {
            ListItem() {
              Row() {
                Column() {
                  Text(item.medicineName)
                    .fontSize(18)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(item.isEnabled ? AppColors.TEXT_PRIMARY : AppColors.TEXT_HINT)
                  Text(item.dosage)
                    .fontSize(14)
                    .fontColor(item.isEnabled ? AppColors.TEXT_SECONDARY : AppColors.TEXT_HINT)
                    .margin({ top: 4 })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                Column({ space: 8 }) {
                  Text(item.time)
                    .fontSize(18)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(AppColors.PRIMARY)
                    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                    .borderRadius(8)
                    .backgroundColor(AppColors.PRIMARY_LIGHT)
                    .onClick(() => {
                      if (index !== undefined) {
                        this.showTimePicker(item, index)
                      }
                    })

                  Toggle({ type: ToggleType.Switch, isOn: item.isEnabled })
                    .width(48)
                    .height(28)
                    .selectedColor(AppColors.PRIMARY)
                    .onChange((_isOn: boolean) => {
                      if (index !== undefined) {
                        this.toggleReminder(item, index)
                      }
                    })
                }
                .alignItems(HorizontalAlign.End)

                Text('✕')
                  .fontSize(18)
                  .fontColor(AppColors.TEXT_HINT)
                  .padding({ left: 12, right: 4, top: 8, bottom: 8 })
                  .onClick(() => {
                    if (index !== undefined) {
                      this.getUIContext().showAlertDialog({
                        title: '删除提醒',
                        message: `确定删除「${item.medicineName}」的用药提醒吗？`,
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
                            this.deleteReminder(index)
                          }
                        }
                      })
                    }
                  })
              }
              .width('100%')
              .padding({ left: 16, right: 8, top: 14, bottom: 14 })
              .backgroundColor(Color.White)
              .borderRadius(AppSizes.CARD_RADIUS)
            }
          }, (item: MedicineReminder) => `${item.id}_${item.isEnabled}`)
        }
        .width('100%')
        .height('100%')
        .padding({ left: 16, right: 16, top: 10, bottom: 10 })
        .layoutWeight(1)
      }

      Button('添加用药提醒')
        .width('90%')
        .height(AppSizes.BUTTON_HEIGHT)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(Color.White)
        .backgroundColor(AppColors.PRIMARY)
        .borderRadius(AppSizes.BUTTON_RADIUS)
        .margin({ top: 10, bottom: 24 })
        .shadow({ radius: 12, color: '#1A56DB40', offsetY: 4 })
        .onClick(() => {
          this.addDialogController.open()
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_PAGE)
  }
}
