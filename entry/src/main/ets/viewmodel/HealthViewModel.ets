/**
 * HealthViewModel - 健康数据视图模型（@Observed 可观察）
 * 管理健康数据记录和用药提醒的增删改查操作
 * 与 ReminderService 联动，提醒的启用/禁用会同步到系统后台提醒代理
 * @Track 装饰器确保数组变化时触发 UI 精准刷新
 */
import { HealthData } from '../model/HealthData'
import { MedicineReminder } from '../model/MedicineReminder'
import { ReminderService } from '../common/service/ReminderService'

@Observed
export class HealthViewModel {
  @Track healthRecords: HealthData[] = [] // 健康数据记录列表
  @Track medicineReminders: MedicineReminder[] = [] // 用药提醒列表
  private reminderService: ReminderService = ReminderService.getInstance()

  /** 添加健康数据记录 */
  addHealthRecord(data: HealthData): void {
    this.healthRecords.push(data)
  }

  /**
   * 获取健康数据记录
   * @param type 可选，按类型筛选（血压/血糖/心率/体温），不传则返回全部
   */
  getHealthRecords(type?: string): HealthData[] {
    if (type) {
      return this.healthRecords.filter((item: HealthData) => item.type === type)
    }
    return this.healthRecords
  }

  /**
   * 获取指定类型的最新一条健康记录
   * 通过遍历比较 recordTime 找到时间最新的记录
   */
  getLatestRecord(type: string): HealthData | undefined {
    const filtered: HealthData[] = this.healthRecords.filter((item: HealthData) => item.type === type)
    if (filtered.length === 0) {
      return undefined
    }
    let latest: HealthData = filtered[0]
    for (let i = 1; i < filtered.length; i++) {
      if (filtered[i].recordTime > latest.recordTime) {
        latest = filtered[i]
      }
    }
    return latest
  }

  /** 根据ID删除健康数据记录，通过 filter 生成新数组触发 UI 刷新 */
  deleteHealthRecord(id: number): void {
    this.healthRecords = this.healthRecords.filter((item: HealthData) => item.id !== id)
  }

  /**
   * 添加用药提醒
   * 若提醒已启用，同步发布到系统后台提醒代理
   */
  addReminder(reminder: MedicineReminder): void {
    this.medicineReminders.push(reminder)
    if (reminder.isEnabled) {
      this.reminderService.publishReminder(reminder)
    }
  }

  /**
   * 更新用药提醒
   * 先在列表中查找并替换，若不存在则添加
   * 启用→发布提醒；禁用→取消提醒
   */
  updateReminder(reminder: MedicineReminder): void {
    const index: number = this.medicineReminders.findIndex((item: MedicineReminder) => item.id === reminder.id)
    if (index >= 0) {
      this.medicineReminders[index] = reminder
    } else {
      this.medicineReminders.push(reminder)
    }
    if (reminder.isEnabled) {
      this.reminderService.publishReminder(reminder)
    } else {
      this.reminderService.cancelReminderByMedicineId(reminder.id)
    }
  }

  /**
   * 删除用药提醒
   * 同时取消系统后台提醒代理中的对应提醒
   */
  deleteReminder(id: number): void {
    this.reminderService.cancelReminderByMedicineId(id)
    this.medicineReminders = this.medicineReminders.filter((item: MedicineReminder) => item.id !== id)
  }

  /**
   * 切换用药提醒的启用/禁用状态
   * 通过创建新数组 [...this.medicineReminders] 触发 UI 刷新
   * 启用→发布提醒；禁用→取消提醒
   */
  toggleReminder(id: number): void {
    const reminder: MedicineReminder | undefined =
      this.medicineReminders.find((item: MedicineReminder) => item.id === id)
    if (reminder) {
      reminder.isEnabled = !reminder.isEnabled
      this.medicineReminders = [...this.medicineReminders] // 创建新数组引用，触发 @Track 检测
      if (reminder.isEnabled) {
        this.reminderService.publishReminder(reminder)
      } else {
        this.reminderService.cancelReminderByMedicineId(id)
      }
    }
  }

  /** 获取所有已启用的用药提醒 */
  getEnabledReminders(): MedicineReminder[] {
    return this.medicineReminders.filter((item: MedicineReminder) => item.isEnabled)
  }

  /** 全量同步提醒到系统后台提醒代理（先取消所有再发布所有） */
  async syncAllReminders(): Promise<void> {
    await this.reminderService.syncReminders(this.medicineReminders)
  }

  /** 初始化示例用药提醒数据，用于演示和测试 */
  initSampleReminders(): void {
    this.medicineReminders = [
      new MedicineReminder(1, '降压药', '1片', '08:00', [1, 2, 3, 4, 5, 6, 7], true, '饭后服用'),
      new MedicineReminder(2, '钙片', '2片', '12:00', [1, 2, 3, 4, 5, 6, 7], true, '随餐服用'),
      new MedicineReminder(3, '降糖药', '1片', '07:30', [1, 2, 3, 4, 5, 6, 7], true, '饭前30分钟'),
      new MedicineReminder(4, '维生素D', '1粒', '09:00', [1, 3, 5], true, '早餐后'),
      new MedicineReminder(5, '阿司匹林', '1片', '20:00', [1, 2, 3, 4, 5, 6, 7], false, '睡前')
    ]
  }
}
