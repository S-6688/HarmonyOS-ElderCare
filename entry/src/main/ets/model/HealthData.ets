export class HealthData {
  id: number = 0
  type: string = ''
  value: string = ''
  unit: string = ''
  recordTime: number = 0
  note: string = ''

  constructor(id: number, type: string, value: string, unit: string, recordTime: number, note: string) {
    this.id = id
    this.type = type
    this.value = value
    this.unit = unit
    this.recordTime = recordTime
    this.note = note
  }
}
