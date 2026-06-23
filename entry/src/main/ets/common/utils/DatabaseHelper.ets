import { relationalStore } from '@kit.ArkData'
import { HealthData } from '../model/HealthData'
import { MedicineReminder } from '../model/MedicineReminder'
import { EmergencyContact } from '../model/EmergencyContact'
import { KnowledgeArticle } from '../model/KnowledgeArticle'

const DB_NAME = 'eldercare.db'
const STORE_VERSION = 1

const SQL_CREATE_HEALTH = `CREATE TABLE IF NOT EXISTS health_data (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  type TEXT NOT NULL,
  value TEXT NOT NULL,
  unit TEXT NOT NULL,
  record_time INTEGER NOT NULL,
  note TEXT
)`

const SQL_CREATE_MEDICINE = `CREATE TABLE IF NOT EXISTS medicine_reminder (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  medicine_name TEXT NOT NULL,
  dosage TEXT NOT NULL,
  time TEXT NOT NULL,
  repeat_days TEXT NOT NULL,
  is_enabled INTEGER NOT NULL DEFAULT 1,
  note TEXT
)`

const SQL_CREATE_CONTACT = `CREATE TABLE IF NOT EXISTS emergency_contact (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  phone_number TEXT NOT NULL,
  relationship TEXT NOT NULL,
  is_priority INTEGER NOT NULL DEFAULT 0
)`

const SQL_CREATE_FAVORITE = `CREATE TABLE IF NOT EXISTS knowledge_favorite (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  article_id INTEGER NOT NULL,
  title TEXT NOT NULL,
  summary TEXT,
  category TEXT,
  content TEXT,
  image_url TEXT,
  is_favorite INTEGER NOT NULL DEFAULT 1
)`

export class DatabaseHelper {
  private rdbStore: relationalStore.RdbStore | null = null

  async init(context: Context): Promise<void> {
    const storeConfig: relationalStore.StoreConfig = {
      name: DB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1
    }
    this.rdbStore = await relationalStore.getRdbStore(context, storeConfig)
    if (this.rdbStore.version === 0) {
      this.rdbStore.executeSql(SQL_CREATE_HEALTH)
      this.rdbStore.executeSql(SQL_CREATE_MEDICINE)
      this.rdbStore.executeSql(SQL_CREATE_CONTACT)
      this.rdbStore.executeSql(SQL_CREATE_FAVORITE)
      this.rdbStore.version = STORE_VERSION
    }
  }

  private ensureStore(): relationalStore.RdbStore {
    if (!this.rdbStore) {
      throw new Error('DatabaseHelper not initialized. Call init() first.')
    }
    return this.rdbStore
  }

  // ===================== HealthData CRUD =====================

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

  async deleteHealthRecord(id: number): Promise<number> {
    const store = this.ensureStore()
    const predicates = new relationalStore.RdbPredicates('health_data')
    predicates.equalTo('id', id)
    return await store.delete(predicates)
  }

  // ===================== MedicineReminder CRUD =====================

  async insertMedicineReminder(data: MedicineReminder): Promise<number> {
    const store = this.ensureStore()
    const valueBucket: relationalStore.ValuesBucket = {
      medicine_name: data.medicineName,
      dosage: data.dosage,
      time: data.time,
      repeat_days: data.repeatDays.join(','),
      is_enabled: data.isEnabled ? 1 : 0,
      note: data.note
    }
    return await store.insert('medicine_reminder', valueBucket)
  }

  async queryMedicineReminders(): Promise<MedicineReminder[]> {
    const store = this.ensureStore()
    const predicates = new relationalStore.RdbPredicates('medicine_reminder')
    const resultSet = await store.query(predicates)
    const reminders: MedicineReminder[] = []
    while (resultSet.goToNextRow()) {
      const repeatDaysStr: string = resultSet.getString(resultSet.getColumnIndex('repeat_days'))
      const repeatDays: number[] = repeatDaysStr.split(',').filter((s: string) => s.length > 0).map((s: string) => Number(s))
      const reminder = new MedicineReminder(
        resultSet.getLong(resultSet.getColumnIndex('id')),
        resultSet.getString(resultSet.getColumnIndex('medicine_name')),
        resultSet.getString(resultSet.getColumnIndex('dosage')),
        resultSet.getString(resultSet.getColumnIndex('time')),
        repeatDays,
        resultSet.getLong(resultSet.getColumnIndex('is_enabled')) === 1,
        resultSet.getString(resultSet.getColumnIndex('note'))
      )
      reminders.push(reminder)
    }
    resultSet.close()
    return reminders
  }

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

  async deleteMedicineReminder(id: number): Promise<number> {
    const store = this.ensureStore()
    const predicates = new relationalStore.RdbPredicates('medicine_reminder')
    predicates.equalTo('id', id)
    return await store.delete(predicates)
  }

  // ===================== EmergencyContact CRUD =====================

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

  async queryEmergencyContacts(): Promise<EmergencyContact[]> {
    const store = this.ensureStore()
    const predicates = new relationalStore.RdbPredicates('emergency_contact')
    predicates.orderByDesc('is_priority')
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

  async deleteEmergencyContact(id: number): Promise<number> {
    const store = this.ensureStore()
    const predicates = new relationalStore.RdbPredicates('emergency_contact')
    predicates.equalTo('id', id)
    return await store.delete(predicates)
  }

  // ===================== KnowledgeArticle Favorite =====================

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

  async updateFavoriteStatus(articleId: number, isFavorite: boolean): Promise<number> {
    const store = this.ensureStore()
    const valueBucket: relationalStore.ValuesBucket = {
      is_favorite: isFavorite ? 1 : 0
    }
    const predicates = new relationalStore.RdbPredicates('knowledge_favorite')
    predicates.equalTo('article_id', articleId)
    return await store.update(valueBucket, predicates)
  }

  async deleteFavoriteArticle(articleId: number): Promise<number> {
    const store = this.ensureStore()
    const predicates = new relationalStore.RdbPredicates('knowledge_favorite')
    predicates.equalTo('article_id', articleId)
    return await store.delete(predicates)
  }

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
