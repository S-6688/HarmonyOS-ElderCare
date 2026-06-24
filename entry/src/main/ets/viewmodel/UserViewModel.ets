/**
 * UserViewModel - 用户视图模型（@Observed 可观察）
 * 管理用户登录/登出状态、首次启动标记、字体大小等级等用户相关数据
 * 数据持久化通过 PreferencesUtil 实现，UI 状态通过 @Track 精确追踪变化
 */
import { User } from '../model/User'
import { PreferencesUtil } from '../common/utils/PreferencesUtil'
import { Constants } from '../common/constants/Constants'

@Observed
export class UserViewModel {
  @Track currentUser: User | null = null // 当前登录用户，null 表示未登录
  @Track isLogin: boolean = false // 登录状态标记

  /** 初始化：从 Preferences 加载用户信息 */
  init(): void {
    this.loadUserFromPrefs()
  }

  /**
   * 用户登录
   * 创建 User 对象 → 更新内存状态 → 持久化登录信息到 Preferences
   * @param name 用户输入的姓名（或默认的"张爷爷"）
   */
  login(name: string): void {
    const userId: number = Date.now() // 使用时间戳作为临时用户ID
    const user: User = new User(userId, name, 0, '', '', true)
    this.currentUser = user
    this.isLogin = true
    PreferencesUtil.getInstance().put(Constants.KEY_IS_LOGIN, true)
    PreferencesUtil.getInstance().put('userId', userId)
    PreferencesUtil.getInstance().put(Constants.KEY_USER_NAME, name)
  }

  /**
   * 用户登出
   * 清除内存中的用户信息 → 持久化登录状态为 false
   * 注意：未清除 userName，下次打开仍显示上次登录用户名
   */
  logout(): void {
    this.currentUser = null
    this.isLogin = false
    const prefsUtil: PreferencesUtil = PreferencesUtil.getInstance()
    prefsUtil.put(Constants.KEY_IS_LOGIN, false)
  }

  /** 获取当前用户信息 */
  getUserInfo(): User | null {
    return this.currentUser
  }

  /** 判断用户是否已登录 */
  isUserLoggedIn(): boolean {
    return this.isLogin
  }

  /** 判断是否首次启动应用 */
  isFirstLaunch(): boolean {
    return PreferencesUtil.getInstance().getBoolean(Constants.KEY_IS_FIRST_LAUNCH, true)
  }

  /** 标记非首次启动（引导页完成后调用） */
  setFirstLaunchDone(): void {
    PreferencesUtil.getInstance().put(Constants.KEY_IS_FIRST_LAUNCH, false)
  }

  /** 获取字体大小等级（0=标准，1=较大，2=最大） */
  getFontSizeLevel(): number {
    return PreferencesUtil.getInstance().getNumber(Constants.KEY_FONT_SIZE_LEVEL, 0)
  }

  /** 设置字体大小等级 */
  setFontSizeLevel(level: number): void {
    PreferencesUtil.getInstance().put(Constants.KEY_FONT_SIZE_LEVEL, level)
  }

  /**
   * 从 Preferences 加载用户信息
   * 若 Preferences 中标记为已登录，则重建 User 对象恢复登录状态
   */
  private loadUserFromPrefs(): void {
    const loginStatus: boolean = PreferencesUtil.getInstance().getBoolean(Constants.KEY_IS_LOGIN, false)
    if (loginStatus) {
      const userId: number = PreferencesUtil.getInstance().getNumber('userId', 0)
      const userName: string = PreferencesUtil.getInstance().getString(Constants.KEY_USER_NAME, '')
      this.currentUser = new User(userId, userName, 0, '', '', true)
      this.isLogin = true
    }
  }
}
