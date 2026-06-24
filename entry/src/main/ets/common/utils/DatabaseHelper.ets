/**
 * DatabaseHelper - 关系型数据库辅助类
 * 封装 HarmonyOS @kit.ArkData 的 relationalStore API，提供四张表的 CRUD 操作
 * 数据表：
 *   1. health_data - 健康数据记录（血压、血糖、心率、体温）
 *   2. medicine_reminder - 用药提醒配置
 *   3. emergency_contact - 紧急联系人信息
 *   4. knowledge_favorite - 养生文章收藏
 *
 * 使用方式：先调用 init(context) 初始化，再调用各 CRUD 方法
 * 安全级别：S1（低级别，适用于普通健康数据）
 *
 * 注意：当前应用主要使用内存数据 + Preferences 存储，此 DatabaseHelper 为持久化扩展预留
 */
import { relationalStore } from '@kit.ArkData'
import { HealthData } from '../model/HealthData'
import { MedicineReminder } from '../model/MedicineReminder'
import { EmergencyContact } from '../model/EmergencyContact'
import { KnowledgeArticle } from '../model/KnowledgeArticle'

const DB_NAME = 'eldercare.db' // 数据库文件名
const STORE_VERSION = 1 // 数据库版本号，用于版本升级管理

// 健康数据表建表SQL：记录血压、血糖、心率、体温等健康指标
const SQL_CREATE_HEALTH = `CREATE TABLE IF NOT EXISTS health_data (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  type TEXT NOT NULL,        -- 健康指标类型（血压/血糖/心率/体温）
  value TEXT NOT NULL,       -- 测量值（如 "120/80"、"5.6"）
  unit TEXT NOT NULL,        -- 单位（如 mmHg、mmol/L）
  record_time INTEGER NOT NULL, -- 记录时间戳（毫秒）
  note TEXT                  -- 备注
)`

// 用药提醒表建表SQL：存储提醒时间、重复日期、启用状态等
const SQL_CREATE_MEDICINE = `CREATE TABLE IF NOT EXISTS medicine_reminder (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  medicine_name TEXT NOT NULL, -- 药品名称
  dosage TEXT NOT NULL,       -- 用量（如 "1片"）
  time TEXT NOT NULL,         -- 提醒时间（HH:mm 格式）
  repeat_days TEXT NOT NULL,  -- 重复日期（逗号分隔，如 "1,2,3,4,5,6,7"）
  is_enabled INTEGER NOT NULL DEFAULT 1, -- 是否启用（1=启用，0=禁用）
  note TEXT                   -- 用药备注（如 "饭后服用"）
)`

// 紧急联系人表建表SQL：优先联系人置顶，作为一键呼叫的首选对象
const SQL_CREATE_CONTACT = `CREATE TABLE IF NOT EXISTS emergency_contact (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,         -- 联系人姓名
  phone_number TEXT NOT NULL, -- 电话号码
  relationship TEXT NOT NULL, -- 关系（如 儿子、家庭医生）
  is_priority INTEGER NOT NULL DEFAULT 0 -- 是否为优先联系人（1=是，0=否）
)`

// 文章收藏表建表SQL：缓存收藏文章的完整信息，支持离线查看
const SQL_CREATE_FAVORITE = `CREATE TABLE IF NOT EXISTS knowledge_favorite (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  article_id INTEGER NOT NULL, -- 文章ID
  title TEXT NOT NULL,         -- 文章标题
  summary TEXT,                -- 文章摘要
  category TEXT,               -- 分类（饮食养生/运动保健等）
  content TEXT,                -- 文章正文
  image_url TEXT,              -- 封面图URL
  is_favorite INTEGER NOT NULL DEFAULT 1 -- 是否收藏（1=已收藏）
)`

export class DatabaseHelper {
  private rdbStore: relationalStore.RdbStore | null = null

  /**
   * 初始化数据库
   * 创建/打开数据库，版本为0时执行全部建表SQL
   * @param context 应用上下文，用于确定数据库文件存储路径
   */
  async init(context: Context): Promise<void> {
    const storeConfig: relationalStore.StoreConfig = {
      name: DB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1 // S1 安全级别：适合低敏感数据
    }
    this.rdbStore = await relationalStore.getRdbStore(context, storeConfig)
    // version 为 0 表示新数据库，需要执行建表语句
    if (this.rdbStore.version === 0) {
      this.rdbStore.executeSql(SQL_CREATE_HEALTH)
      this.rdbStore.executeSql(SQL_CREATE_MEDICINE)
      this.rdbStore.executeSql(SQL_CREATE_CONTACT)
      this.rdbStore.executeSql(SQL_CREATE_FAVORITE)
      this.rdbStore.version = STORE_VERSION
    }
  }

  /** 确保数据库已初始化，未初始化则抛出异常 */
  private ensureStore(): relationalStore.RdbStore {
    if (!this.rdbStore) {
      throw new Error('DatabaseHelper not initialized. Call init() first.')
    }
    return this.rdbStore
  }

  // ===================== HealthData CRUD =====================

  /** 插入健康数据记录 */
  async insertHealthRecord(data: HealthData): Promise<number> {
    const store = this.ensureStore()
    const valueBucket: relationalStore.ValuesBucket = {
      type: data.type,
      value: data.value,
      unit: data.unit,
      record_time: data.recordTime,
      note: data.note
    }
    return await store.insert('health_data', valueBucket)
  }

  /**
   * 查询健康数据记录
   * @param type 可选，按类型筛选（血压/血糖/心率/体温），不传则查询全部
   * @returns 按记录时间降序排列的健康数据列表
   */
  async queryHealthRecords(type?: string): Promise<HealthData[]> {
    const store = this.ensureStore()
    const predicates = new relationalStore.RdbPredicates('health_data')
    if (type) {
      predicates.equalTo('type', type)
    }
    predicates.orderByDesc('record_time')
    const resultSet = await store.query(predicates)
    const records: HealthData[] = []
    while (resultSet.goToNextRow()) {
      const record = new HealthData(
        resultSet.getLong(resultSet.getColumnIndex('id')),
        resultSet.getString(resultSet.getColumnIndex('type')),
        resultSet.getString(resultSet.getColumnIndex('value')),
        resultSet.getString(resultSet.getColumnIndex('unit')),
        resultSet.getLong(resultSet.getColumnIndex('record_time')),
        resultSet.getString(resultSet.getColumnIndex('note'))
      )
      records.push(record)
    }
    resultSet.close()
    return records
  }

  /** 根据ID删除健康数据记录 */
  async deleteHealthRecord(id: number): Promise<number> {
    const store = this.ensureStore()
    const predicates = new relationalStore.RdbPredicates('health_data')
    predicates.equalTo('id', id)
    return await store.delete(predicates)
  }

  // ===================== MedicineReminder CRUD =====================

  /**
   * 插入用药提醒
   * repeatDays 数组转为逗号分隔字符串存储，isEnabled 布尔值转为 0/1 整数
   */
  async insertMedicineReminder(data: MedicineReminder): Promise<number> {
    const store = this.ensureStore()
    const valueBucket: relationalStore.ValuesBucket = {
      medicine_name: data.medicineName,
      dosage: data.dosage,
      time: data.time,
      repeat_days: data.repeatDays.join(','), // 数组转字符串存储
      is_enabled: data.isEnabled ? 1 : 0,     // 布尔值转整数存储
      note: data.note
    }
    return await store.insert('medicine_reminder', valueBucket)
  }

  /** 查询全部用药提醒，将 repeat_days 字符串还原为 number[] 数组 */
  async queryMedicineReminders(): Promise<MedicineReminder[]> {
    const store = this.ensureStore()
    const predicates = new relationalStore.RdbPredicates('medicine_reminder')
    const resultSet = await store.query(predicates)
    const reminders: MedicineReminder[] = []
    while (resultSet.goToNextRow()) {
      // 将逗号分隔的字符串还原为数字数组（如 "1,2,3" → [1,2,3]）
      const repeatDaysStr: string = resultSet.getString(resultSet.getColumnIndex('repeat_days'))
      const repeatDays: number[] = repeatDaysStr.split(',').filter((s: string) => s.length > 0).map((s: string) => Number(s))
      const reminder = new MedicineReminder(
        resultSet.getLong(resultSet.getColumnIndex('id')),
        resultSet.getString(resultSet.getColumnIndex('medicine_name')),
        resultSet.getString(resultSet.getColumnIndex('dosage')),
        resultSet.getString(resultSet.getColumnIndex('time')),
        repeatDays,
        resultSet.getLong(resultSet.getColumnIndex('is_enabled')) === 1, // 整数转布尔值
        resultSet.getString(resultSet.getColumnIndex('note'))
      )
      reminders.push(reminder)
    }
    resultSet.close()
    return reminders
  }

  /** 更新用药提醒，根据 ID 匹配更新 */
  async updateMedicineReminder(data: MedicineReminder): Promise<number> {
    const store = this.ensureStore()
    const valueBucket: relationalStore.ValuesBucket = {
      medicine_name: data.medicineName,
      dosage: data.dosage,
      time: data.time,
      repeat_days: data.repeatDays.join(','),
      is_enabled: data.isEnabled ? 1 : 0,
      note: data.note
    }
    const predicates = new relationalStore.RdbPredicates('medicine_reminder')
    predicates.equalTo('id', data.id)
    return await store.update(valueBucket, predicates)
  }

  /** 根据ID删除用药提醒 */
  async deleteMedicineReminder(id: number): Promise<number> {
    const store = this.ensureStore()
    const predicates = new relationalStore.RdbPredicates('medicine_reminder')
    predicates.equalTo('id', id)
    return await store.delete(predicates)
  }

  // ===================== EmergencyContact CRUD =====================

  /** 插入紧急联系人 */
  async insertEmergencyContact(data: EmergencyContact): Promise<number> {
    const store = this.ensureStore()
    const valueBucket: relationalStore.ValuesBucket = {
      name: data.name,
      phone_number: data.phoneNumber,
      relationship: data.relationship,
      is_priority: data.isPriority ? 1 : 0
    }
    return await store.insert('emergency_contact', valueBucket)
  }

  /**
   * 查询全部紧急联系人
   * 按优先联系人降序排列，确保优先联系人在列表顶部
   */
  async queryEmergencyContacts(): Promise<EmergencyContact[]> {
    const store = this.ensureStore()
    const predicates = new relationalStore.RdbPredicates('emergency_contact')
    predicates.orderByDesc('is_priority') // 优先联系人排在前面
    const resultSet = await store.query(predicates)
    const contacts: EmergencyContact[] = []
    while (resultSet.goToNextRow()) {
      const contact = new EmergencyContact(
        resultSet.getLong(resultSet.getColumnIndex('id')),
        resultSet.getString(resultSet.getColumnIndex('name')),
        resultSet.getString(resultSet.getColumnIndex('phone_number')),
        resultSet.getString(resultSet.getColumnIndex('relationship')),
        resultSet.getLong(resultSet.getColumnIndex('is_priority')) === 1
      )
      contacts.push(contact)
    }
    resultSet.close()
    return contacts
  }

  /** 更新紧急联系人信息 */
  async updateEmergencyContact(data: EmergencyContact): Promise<number> {
    const store = this.ensureStore()
    const valueBucket: relationalStore.ValuesBucket = {
      name: data.name,
      phone_number: data.phoneNumber,
      relationship: data.relationship,
      is_priority: data.isPriority ? 1 : 0
    }
    const predicates = new relationalStore.RdbPredicates('emergency_contact')
    predicates.equalTo('id', data.id)
    return await store.update(valueBucket, predicates)
  }

  /** 根据ID删除紧急联系人 */
  async deleteEmergencyContact(id: number): Promise<number> {
    const store = this.ensureStore()
    const predicates = new relationalStore.RdbPredicates('emergency_contact')
    predicates.equalTo('id', id)
    return await store.delete(predicates)
  }

  // ===================== KnowledgeArticle Favorite =====================

  /** 收藏文章，同时缓存文章的完整信息以支持离线查看 */
  async insertFavoriteArticle(data: KnowledgeArticle): Promise<number> {
    const store = this.ensureStore()
    const valueBucket: relationalStore.ValuesBucket = {
      article_id: data.id,
      title: data.title,
      summary: data.summary,
      category: data.category,
      content: data.content,
      image_url: data.imageUrl,
      is_favorite: 1
    }
    return await store.insert('knowledge_favorite', valueBucket)
  }

  /** 查询全部已收藏的文章 */
  async queryFavoriteArticles(): Promise<KnowledgeArticle[]> {
    const store = this.ensureStore()
    const predicates = new relationalStore.RdbPredicates('knowledge_favorite')
    predicates.equalTo('is_favorite', 1)
    const resultSet = await store.query(predicates)
    const articles: KnowledgeArticle[] = []
    while (resultSet.goToNextRow()) {
      const article = new KnowledgeArticle(
        resultSet.getLong(resultSet.getColumnIndex('article_id')),
        resultSet.getString(resultSet.getColumnIndex('title')),
        resultSet.getString(resultSet.getColumnIndex('summary')),
        resultSet.getString(resultSet.getColumnIndex('category')),
        resultSet.getString(resultSet.getColumnIndex('content')),
        resultSet.getString(resultSet.getColumnIndex('image_url')),
        true
      )
      articles.push(article)
    }
    resultSet.close()
    return articles
  }

  /** 更新文章收藏状态（收藏/取消收藏） */
  async updateFavoriteStatus(articleId: number, isFavorite: boolean): Promise<number> {
    const store = this.ensureStore()
    const valueBucket: relationalStore.ValuesBucket = {
      is_favorite: isFavorite ? 1 : 0
    }
    const predicates = new relationalStore.RdbPredicates('knowledge_favorite')
    predicates.equalTo('article_id', articleId)
    return await store.update(valueBucket, predicates)
  }

  /** 根据文章ID删除收藏记录 */
  async deleteFavoriteArticle(articleId: number): Promise<number> {
    const store = this.ensureStore()
    const predicates = new relationalStore.RdbPredicates('knowledge_favorite')
    predicates.equalTo('article_id', articleId)
    return await store.delete(predicates)
  }

  /**
   * 判断文章是否已收藏
   * 通过查询 is_favorite=1 的记录数判断，rowCount > 0 即为已收藏
   */
  async isArticleFavorited(articleId: number): Promise<boolean> {
    const store = this.ensureStore()
    const predicates = new relationalStore.RdbPredicates('knowledge_favorite')
    predicates.equalTo('article_id', articleId).and().equalTo('is_favorite', 1)
    const resultSet = await store.query(predicates)
    const count: number = resultSet.rowCount
    resultSet.close()
    return count > 0
  }
}
