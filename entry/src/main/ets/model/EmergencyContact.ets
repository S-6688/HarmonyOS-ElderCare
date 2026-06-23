export class EmergencyContact {
  id: number = 0
  name: string = ''
  phoneNumber: string = ''
  relationship: string = ''
  isPriority: boolean = false

  constructor(id: number, name: string, phoneNumber: string, relationship: string, isPriority: boolean) {
    this.id = id
    this.name = name
    this.phoneNumber = phoneNumber
    this.relationship = relationship
    this.isPriority = isPriority
  }
}
