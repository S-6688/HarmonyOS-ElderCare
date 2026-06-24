/**
 * MedicineReminder - 用药提醒模型
 * repeatDays: 1-7 表示周一到周日（如 [1,2,3,4,5] 表示工作日）
 * isEnabled: 控制提醒是否生效，禁用时系统后台不会触发通知
 */
export class MedicineReminder {
  id: number = 0                    // 提醒唯一ID
  medicineName: string = ''         // 药品名称（如 "降压药"、"钙片"）
  dosage: string = ''               // 用量（如 "1片"、"2片"）
  time: string = ''                 // 提醒时间（HH:mm 格式，如 "08:00"）
  repeatDays: number[] = []         // 重复日期（1=周一 ... 7=周日，[1,2,3,4,5,6,7]表示每天）
  isEnabled: boolean = true         // 是否启用提醒
  note: string = ''                 // 用药备注（如 "饭后服用"、"随餐服用"）

  constructor(id: number, medicineName: string, dosage: string, time: string, repeatDays: number[],
    isEnabled: boolean, note: string) {
    this.id = id
    this.medicineName = medicineName
    this.dosage = dosage
    this.time = time
    this.repeatDays = repeatDays
    this.isEnabled = isEnabled
    this.note = note
  }
}
