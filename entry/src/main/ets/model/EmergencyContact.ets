/**
 * EmergencyContact - 紧急联系人模型
 * isPriority: 优先联系人作为"一键呼叫"的首选对象，全局只能有一个
 * 优先联系人会在列表中置顶显示，并在首页一键呼叫时优先拨打
 */
export class EmergencyContact {
  id: number = 0                    // 联系人唯一ID
  name: string = ''                 // 联系人姓名
  phoneNumber: string = ''          // 电话号码
  relationship: string = ''         // 与用户的关系（如 儿子、家庭医生、邻居）
  isPriority: boolean = false       // 是否为优先联系人（全局唯一）

  constructor(id: number, name: string, phoneNumber: string, relationship: string, isPriority: boolean) {
    this.id = id
    this.name = name
    this.phoneNumber = phoneNumber
    this.relationship = relationship
    this.isPriority = isPriority
  }
}
