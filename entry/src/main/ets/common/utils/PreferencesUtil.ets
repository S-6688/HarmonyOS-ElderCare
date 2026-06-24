/**
 * PreferencesUtil - 轻量级键值对存储工具类（单例模式）
 * 封装 HarmonyOS @kit.ArkData 的 preferences API，提供统一的读写接口
 * 存储内容包括：登录状态、用户名、字体大小等级、首次启动标记、紧急联系人JSON等
 * 使用方式：PreferencesUtil.getInstance().getBoolean('isLogin', false)
 * 初始化时机：必须在 EntryAbility.onCreate() 中调用 init() 完成初始化
 */
import { preferences } from '@kit.ArkData'
import { common } from '@kit.AbilityKit'
import { Constants } from '../constants/Constants'

export class PreferencesUtil {
  // 饿汉式单例，类加载时即创建实例，保证线程安全
  private static instance: PreferencesUtil = new PreferencesUtil()
  // preferences 实例，为 null 表示尚未初始化
  private prefs: preferences.Preferences | null = null
  // 缓存应用上下文，用于延迟初始化时重新获取 preferences 实例
  private appContext: common.Context | null = null

  /** 获取 PreferencesUtil 单例 */
  static getInstance(): PreferencesUtil {
    return PreferencesUtil.instance
  }

  /**
   * 初始化方法，在 EntryAbility.onCreate() 中调用
   * 同步获取 preferences 实例并缓存上下文
   */
  init(context: common.Context): void {
    try {
      this.appContext = context
      if (!this.prefs) {
        this.prefs = preferences.getPreferencesSync(context, { name: Constants.PREFERENCES_NAME })
      }
    } catch (e) {
      console.error('PreferencesUtil init failed: ' + JSON.stringify(e))
    }
  }

  /**
   * 确保初始化方法，在页面 aboutToAppear() 中调用
   * 与 init() 的区别：仅在 prefs 为 null 时才执行初始化，避免重复创建
   * 用于应对页面在 Ability 之外场景启动时 prefs 未初始化的情况
   */
  ensureInit(context: common.Context): void {
    try {
      if (!this.prefs) {
        this.appContext = context
        this.prefs = preferences.getPreferencesSync(context, { name: Constants.PREFERENCES_NAME })
      }
    } catch (e) {
      console.error('PreferencesUtil ensureInit failed: ' + JSON.stringify(e))
    }
  }

  /**
   * 内部方法：获取 preferences 实例
   * 若实例丢失但上下文存在，尝试重新获取；否则抛出异常
   */
  private getPrefs(): preferences.Preferences {
    try {
      if (!this.prefs && this.appContext) {
        this.prefs = preferences.getPreferencesSync(this.appContext, { name: Constants.PREFERENCES_NAME })
      }
    } catch (e) {
      console.error('PreferencesUtil getPrefs failed: ' + JSON.stringify(e))
    }
    if (!this.prefs) {
      throw new Error('PreferencesUtil not initialized. Call init() first in EntryAbility.onCreate.')
    }
    return this.prefs
  }

  /** 读取布尔值，如登录状态、是否首次启动等 */
  getBoolean(key: string, defValue: boolean): boolean {
    try {
      return this.getPrefs().getSync(key, defValue) as boolean
    } catch (e) {
      console.error('PreferencesUtil getBoolean failed: ' + JSON.stringify(e))
      return defValue
    }
  }

  /** 读取字符串，如用户名、紧急联系人JSON、收藏文章ID列表等 */
  getString(key: string, defValue: string): string {
    try {
      return this.getPrefs().getSync(key, defValue) as string
    } catch (e) {
      console.error('PreferencesUtil getString failed: ' + JSON.stringify(e))
      return defValue
    }
  }

  /** 读取数值，如字体大小等级、用户ID等 */
  getNumber(key: string, defValue: number): number {
    try {
      return this.getPrefs().getSync(key, defValue) as number
    } catch (e) {
      console.error('PreferencesUtil getNumber failed: ' + JSON.stringify(e))
      return defValue
    }
  }

  /**
   * 写入键值对并立即持久化（flush）
   * putSync 仅写入内存，flush 将数据刷写到磁盘，确保数据不丢失
   * 页面跳转依赖的状态（登录、引导页完成状态）必须立即 flush，避免重启后读到旧值。
   */
  put(key: string, value: preferences.ValueType): void {
    try {
      this.getPrefs().putSync(key, value)
      this.getPrefs().flush()
    } catch (e) {
      console.error('PreferencesUtil put failed: ' + JSON.stringify(e))
    }
  }

  /** 获取底层 preferences 实例，供需要直接操作的场景使用 */
  getPreferences(): preferences.Preferences {
    return this.getPrefs()
  }
}
