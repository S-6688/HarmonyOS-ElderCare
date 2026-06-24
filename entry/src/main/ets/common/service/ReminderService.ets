/**
 * ReminderService - 用药提醒服务（懒汉式单例 + @Observed 可观察）
 * 核心职责：
 *   1. 管理通知权限和通知渠道
 *   2. 通过系统后台提醒代理（reminderAgentManager）发布定时闹钟类提醒
 *   3. 维护 reminderId ↔ medicineId 的映射关系，支持按药品取消提醒
 *   4. 支持即时通知发布（非定时，立即发送）
 * 依赖：@kit.BackgroundTasksKit（后台提醒代理）、@kit.NotificationKit（通知管理）
 */
import { reminderAgentManager } from '@kit.BackgroundTasksKit'
import { notificationManager } from '@kit.NotificationKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { wantAgent, common } from '@kit.AbilityKit'
import { MedicineReminder } from '../../model/MedicineReminder'

const BUNDLE_NAME: string = 'com.example.eldercare' // 应用包名，用于构建 WantAgent
const ABILITY_NAME: string = 'EntryAbility' // 主 Ability 名称，提醒触发时拉起此 Ability
const NOTIFICATION_SLOT_TYPE: notificationManager.SlotType = notificationManager.SlotType.SOCIAL_COMMUNICATION // 通知渠道类型：社交通信

/**
 * ReminderMap - 提醒ID映射关系
 * reminderId: 系统后台提醒代理返回的提醒ID，用于取消提醒
 * medicineId: 药品提醒的业务ID，与 MedicineReminder.id 对应
 */
class ReminderMap {
  reminderId: number = 0
  medicineId: number = 0
}

@Observed
export class ReminderService {
  // 懒汉式单例，首次调用 getInstance() 时创建
  private static instance: ReminderService | null = null
  // 提醒ID映射表，维护系统提醒ID与药品业务ID的对应关系
  @Track reminderMaps: ReminderMap[] = []
  private context: common.UIAbilityContext | null = null

  /** 获取 ReminderService 单例 */
  static getInstance(): ReminderService {
    if (!ReminderService.instance) {
      ReminderService.instance = new ReminderService()
    }
    return ReminderService.instance
  }

  /**
   * 初始化提醒服务
   * 流程：缓存上下文 → 申请通知权限 → 创建通知渠道
   * 必须在 EntryAbility.onCreate() 中调用
   */
  async init(context: common.UIAbilityContext): Promise<void> {
    this.context = context
    await this.requestNotificationPermission()
    await this.addNotificationSlot()
  }

  /**
   * 申请通知权限
   * 先检查是否已授权，未授权则弹窗请求用户授权
   * 通知权限是发布提醒的前置条件
   */
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

  /**
   * 添加通知渠道（Slot）
   * 通知渠道决定了通知的提示方式（声音、震动等），必须在发布通知前创建
   */
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

  /**
   * 发布单个用药提醒到系统后台提醒代理
   * 流程：检查启用状态 → 取消已有同类提醒 → 解析时间 → 构建闹钟提醒请求 → 发布 → 记录映射
   * @param reminder 药品提醒数据模型
   * @returns 系统提醒ID，-1 表示发布失败或未启用
   */
  async publishReminder(reminder: MedicineReminder): Promise<number> {
    // 未启用的提醒不发布
    if (!reminder.isEnabled) {
      return -1
    }
    // 若该药品已有提醒，先取消旧的再发布新的（避免重复提醒）
    const existingMap: ReminderMap | undefined = this.reminderMaps.find(
      (m: ReminderMap) => m.medicineId === reminder.id
    )
    if (existingMap) {
      await this.cancelReminderByMedicineId(reminder.id)
    }
    // 解析提醒时间字符串（如 "08:00" → hour=8, minute=0）
    const timeParts: string[] = reminder.time.split(':')
    const hour: number = timeParts.length > 0 ? parseInt(timeParts[0]) : 8
    const minute: number = timeParts.length > 1 ? parseInt(timeParts[1]) : 0
    // 转换重复日期格式（1-7 表示周一到周日）
    const daysOfWeek: number[] = this.convertRepeatDays(reminder.repeatDays)
    const title: string = `${reminder.medicineName} 用药提醒`
    const content: string = `请服用 ${reminder.dosage}${reminder.note.length > 0 ? '，' + reminder.note : ''}`
    // 构建闹钟类提醒请求，系统会在指定时间触发通知
    const alarmReminder: reminderAgentManager.ReminderRequestAlarm = {
      reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_ALARM, // 闹钟类型提醒
      hour: hour,
      minute: minute,
      daysOfWeek: daysOfWeek,
      actionButton: [
        {
          title: '已服用',
          type: reminderAgentManager.ActionButtonType.ACTION_BUTTON_TYPE_CLOSE // 点击后关闭提醒
        },
        {
          title: '稍后提醒',
          type: reminderAgentManager.ActionButtonType.ACTION_BUTTON_TYPE_SNOOZE // 点击后延迟再提醒
        }
      ],
      wantAgent: {
        pkgName: BUNDLE_NAME,
        abilityName: ABILITY_NAME
      },
      ringDuration: 10, // 响铃时长（秒）
      snoozeTimes: 2, // 稍后提醒最多触发次数
      timeInterval: 300, // 稍后提醒间隔（秒），300秒=5分钟
      title: title,
      content: content,
      expiredContent: '用药提醒已过期', // 提醒过期后的提示内容
      snoozeContent: `再次提醒：请服用 ${reminder.dosage}`, // 稍后提醒的提示内容
      notificationId: reminder.id, // 通知ID，同一ID的新通知会替换旧通知
      slotType: NOTIFICATION_SLOT_TYPE
    }
    try {
      const publishedId: number = await reminderAgentManager.publishReminder(alarmReminder)
      // 记录系统提醒ID与药品业务ID的映射关系，便于后续取消
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

  /**
   * 根据药品ID取消提醒
   * 通过映射表找到系统提醒ID，调用系统API取消
   */
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

  /** 批量发布所有启用的提醒 */
  async publishAllReminders(reminders: MedicineReminder[]): Promise<void> {
    for (const reminder of reminders) {
      if (reminder.isEnabled) {
        await this.publishReminder(reminder)
      }
    }
  }

  /** 取消所有已发布的提醒，并清空映射表 */
  async cancelAllReminders(): Promise<void> {
    try {
      await reminderAgentManager.cancelAllReminders()
      this.reminderMaps = []
      console.info('[ReminderService] All reminders cancelled')
    } catch (err) {
      console.error(`[ReminderService] cancelAllReminders failed: ${JSON.stringify(err)}`)
    }
  }

  /**
   * 全量同步提醒：先取消所有 → 再发布所有
   * 用于应用启动时确保系统提醒与应用数据一致
   */
  async syncReminders(reminders: MedicineReminder[]): Promise<void> {
    await this.cancelAllReminders()
    await this.publishAllReminders(reminders)
  }

  /**
   * 转换重复日期格式
   * 当重复日期为全部7天时，系统API要求传入 [1,2,3,4,5,6,7]
   */
  private convertRepeatDays(days: number[]): number[] {
    if (days.length === 7) {
      return [1, 2, 3, 4, 5, 6, 7]
    }
    return days
  }

  /**
   * 发布即时通知（非定时提醒，立即发送到通知栏）
   * 使用场景：用户手动触发提醒、测试通知功能等
   * 与 publishReminder 的区别：不通过后台提醒代理，直接发送通知
   */
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
