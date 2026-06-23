import { HealthData } from '../model/HealthData'
import { MedicineReminder } from '../model/MedicineReminder'
import { ReminderService } from '../common/service/ReminderService'

@Observed
export class HealthViewModel {
  @Track healthRecords: HealthData[] = []
  @Track medicineReminders: MedicineReminder[] = []
  private reminderService: ReminderService = ReminderService.getInstance()

  addHealthRecord(data: HealthData): void {
    this.healthRecords.push(data)
  }

  getHealthRecords(type?: string): HealthData[] {
    if (type) {
      return this.healthRecords.filter((item: HealthData) => item.type === type)
    }
    return this.healthRecords
  }

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

  deleteHealthRecord(id: number): void {
    this.healthRecords = this.healthRecords.filter((item: HealthData) => item.id !== id)
  }

  addReminder(reminder: MedicineReminder): void {
    this.medicineReminders.push(reminder)
    if (reminder.isEnabled) {
      this.reminderService.publishReminder(reminder)
    }
  }

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

  deleteReminder(id: number): void {
    this.reminderService.cancelReminderByMedicineId(id)
    this.medicineReminders = this.medicineReminders.filter((item: MedicineReminder) => item.id !== id)
  }

  toggleReminder(id: number): void {
    const reminder: MedicineReminder | undefined =
      this.medicineReminders.find((item: MedicineReminder) => item.id === id)
    if (reminder) {
      reminder.isEnabled = !reminder.isEnabled
      this.medicineReminders = [...this.medicineReminders]
      if (reminder.isEnabled) {
        this.reminderService.publishReminder(reminder)
      } else {
        this.reminderService.cancelReminderByMedicineId(id)
      }
    }
  }

  getEnabledReminders(): MedicineReminder[] {
    return this.medicineReminders.filter((item: MedicineReminder) => item.isEnabled)
  }

  async syncAllReminders(): Promise<void> {
    await this.reminderService.syncReminders(this.medicineReminders)
  }

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
