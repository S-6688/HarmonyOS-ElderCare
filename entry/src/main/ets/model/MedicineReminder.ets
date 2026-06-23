export class MedicineReminder {
  id: number = 0
  medicineName: string = ''
  dosage: string = ''
  time: string = ''
  repeatDays: number[] = []
  isEnabled: boolean = true
  note: string = ''

  constructor(id: number, medicineName: string, dosage: string, time: string, repeatDays: number[], isEnabled: boolean, note: string) {
    this.id = id
    this.medicineName = medicineName
    this.dosage = dosage
    this.time = time
    this.repeatDays = repeatDays
    this.isEnabled = isEnabled
    this.note = note
  }
}
