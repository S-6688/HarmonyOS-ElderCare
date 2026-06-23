import { reminderAgentManager } from '@kit.BackgroundTasksKit'
import { notificationManager } from '@kit.NotificationKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { wantAgent, common } from '@kit.AbilityKit'
import { MedicineReminder } from '../../model/MedicineReminder'

const BUNDLE_NAME: string = 'com.example.eldercare'
const ABILITY_NAME: string = 'EntryAbility'
const NOTIFICATION_SLOT_TYPE: notificationManager.SlotType = notificationManager.SlotType.SOCIAL_COMMUNICATION

class ReminderMap {
  reminderId: number = 0
  medicineId: number = 0
}

@Observed
export class ReminderService {
  private static instance: ReminderService | null = null
  @Track reminderMaps: ReminderMap[] = []
  private context: common.UIAbilityContext | null = null

  static getInstance(): ReminderService {
    if (!ReminderService.instance) {
      ReminderService.instance = new ReminderService()
    }
    return ReminderService.instance
  }

  async init(context: common.UIAbilityContext): Promise<void> {
    this.context = context
    await this.requestNotificationPermission()
    await this.addNotificationSlot()
  }

  private async requestNotificationPermission(): Promise<void> {
    try {
      const enabled: boolean = notificationManager.isNotificationEnabledSync()
      if (!enabled && this.context) {
        notificationManager.requestEnableNotification(this.context, (err: BusinessError) => {
          if (err) {
            console.error(`[ReminderService] requestEnableNotification failed: ${err.message}`)
          } else {
            console.info('[ReminderService] Notification permission granted')
          }
        })
      }
    } catch (err) {
      console.error(`[ReminderService] isNotificationEnabled error: ${JSON.stringify(err)}`)
    }
  }

  private async addNotificationSlot(): Promise<void> {
    try {
      notificationManager.addSlot(NOTIFICATION_SLOT_TYPE, (err: BusinessError) => {
        if (err) {
          console.error(`[ReminderService] addSlot failed: ${err.message}`)
        } else {
          console.info('[ReminderService] Notification slot added')
        }
      })
    } catch (err) {
      console.error(`[ReminderService] addSlot error: ${JSON.stringify(err)}`)
    }
  }

  async publishReminder(reminder: MedicineReminder): Promise<number> {
    if (!reminder.isEnabled) {
      return -1
    }
    const existingMap: ReminderMap | undefined = this.reminderMaps.find(
      (m: ReminderMap) => m.medicineId === reminder.id
    )
    if (existingMap) {
      await this.cancelReminderByMedicineId(reminder.id)
    }
    const timeParts: string[] = reminder.time.split(':')
    const hour: number = timeParts.length > 0 ? parseInt(timeParts[0]) : 8
    const minute: number = timeParts.length > 1 ? parseInt(timeParts[1]) : 0
    const daysOfWeek: number[] = this.convertRepeatDays(reminder.repeatDays)
    const title: string = `${reminder.medicineName} 用药提醒`
    const content: string = `请服用 ${reminder.dosage}${reminder.note.length > 0 ? '，' + reminder.note : ''}`
    const alarmReminder: reminderAgentManager.ReminderRequestAlarm = {
      reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_ALARM,
      hour: hour,
      minute: minute,
      daysOfWeek: daysOfWeek,
      actionButton: [
        {
          title: '已服用',
          type: reminderAgentManager.ActionButtonType.ACTION_BUTTON_TYPE_CLOSE
        },
        {
          title: '稍后提醒',
          type: reminderAgentManager.ActionButtonType.ACTION_BUTTON_TYPE_SNOOZE
        }
      ],
      wantAgent: {
        pkgName: BUNDLE_NAME,
        abilityName: ABILITY_NAME
      },
      ringDuration: 10,
      snoozeTimes: 2,
      timeInterval: 300,
      title: title,
      content: content,
      expiredContent: '用药提醒已过期',
      snoozeContent: `再次提醒：请服用 ${reminder.dosage}`,
      notificationId: reminder.id,
      slotType: NOTIFICATION_SLOT_TYPE
    }
    try {
      const publishedId: number = await reminderAgentManager.publishReminder(alarmReminder)
      const map: ReminderMap = new ReminderMap()
      map.reminderId = publishedId
      map.medicineId = reminder.id
      this.reminderMaps.push(map)
      console.info(`[ReminderService] Published reminder for ${reminder.medicineName}, id=${publishedId}`)
      return publishedId
    } catch (err) {
      console.error(`[ReminderService] publishReminder failed: ${JSON.stringify(err)}`)
      return -1
    }
  }

  async cancelReminderByMedicineId(medicineId: number): Promise<void> {
    const index: number = this.reminderMaps.findIndex((m: ReminderMap) => m.medicineId === medicineId)
    if (index < 0) {
      return
    }
    const reminderId: number = this.reminderMaps[index].reminderId
    try {
      await reminderAgentManager.cancelReminder(reminderId)
      this.reminderMaps.splice(index, 1)
      console.info(`[ReminderService] Cancelled reminder id=${reminderId}`)
    } catch (err) {
      console.error(`[ReminderService] cancelReminder failed: ${JSON.stringify(err)}`)
    }
  }

  async publishAllReminders(reminders: MedicineReminder[]): Promise<void> {
    for (const reminder of reminders) {
      if (reminder.isEnabled) {
        await this.publishReminder(reminder)
      }
    }
  }

  async cancelAllReminders(): Promise<void> {
    try {
      await reminderAgentManager.cancelAllReminders()
      this.reminderMaps = []
      console.info('[ReminderService] All reminders cancelled')
    } catch (err) {
      console.error(`[ReminderService] cancelAllReminders failed: ${JSON.stringify(err)}`)
    }
  }

  async syncReminders(reminders: MedicineReminder[]): Promise<void> {
    await this.cancelAllReminders()
    await this.publishAllReminders(reminders)
  }

  private convertRepeatDays(days: number[]): number[] {
    if (days.length === 7) {
      return [1, 2, 3, 4, 5, 6, 7]
    }
    return days
  }

  async publishImmediateNotification(reminder: MedicineReminder): Promise<void> {
    const title: string = `${reminder.medicineName} 用药提醒`
    const content: string = `请服用 ${reminder.dosage}${reminder.note.length > 0 ? '，' + reminder.note : ''}`
    const wantAgentInfo: wantAgent.WantAgentInfo = {
      wants: [
        {
          bundleName: BUNDLE_NAME,
          abilityName: ABILITY_NAME
        }
      ],
      operationType: wantAgent.OperationType.START_ABILITIES,
      requestCode: 0,
      wantAgentFlags: [wantAgent.WantAgentFlags.CONSTANT_FLAG]
    }
    try {
      const wantAgentObj: Object = await wantAgent.getWantAgent(wantAgentInfo)
      const request: notificationManager.NotificationRequest = {
        id: reminder.id + 10000,
        notificationSlotType: NOTIFICATION_SLOT_TYPE,
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title: title,
            text: content,
            additionalText: reminder.time
          }
        },
        wantAgent: wantAgentObj
      }
      notificationManager.publish(request, (err: BusinessError) => {
        if (err) {
          console.error(`[ReminderService] publish notification failed: ${err.message}`)
        } else {
          console.info(`[ReminderService] Immediate notification sent for ${reminder.medicineName}`)
        }
      })
    } catch (err) {
      console.error(`[ReminderService] publish notification error: ${JSON.stringify(err)}`)
    }
  }
}
