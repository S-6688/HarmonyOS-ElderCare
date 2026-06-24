/**
 * HealthData - 健康数据模型
 * 记录血压、血糖、心率、体温等健康指标
 * recordTime 使用毫秒时间戳，便于排序和时间格式化
 */
export class HealthData {
  id: number = 0             // 记录唯一ID
  type: string = ''          // 健康指标类型（血压/血糖/心率/体温）
  value: string = ''         // 测量值（血压如 "120/80"，其他如 "5.6"）
  unit: string = ''          // 单位（mmHg / mmol/L / 次/分 / °C）
  recordTime: number = 0     // 记录时间戳（毫秒）
  note: string = ''          // 备注信息（如 "饭后测量"、"略偏高"）

  constructor(id: number, type: string, value: string, unit: string, recordTime: number, note: string) {
    this.id = id
    this.type = type
    this.value = value
    this.unit = unit
    this.recordTime = recordTime
    this.note = note
  }
}
