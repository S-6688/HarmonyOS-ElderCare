import { User } from '../model/User'
import { PreferencesUtil } from '../common/utils/PreferencesUtil'
import { Constants } from '../common/constants/Constants'

@Observed
export class UserViewModel {
  @Track currentUser: User | null = null
  @Track isLogin: boolean = false

  init(): void {
    this.loadUserFromPrefs()
  }

  login(name: string): void {
    const userId: number = Date.now()
    const user: User = new User(userId, name, 0, '', '', true)
    this.currentUser = user
    this.isLogin = true
    PreferencesUtil.getInstance().put(Constants.KEY_IS_LOGIN, true)
    PreferencesUtil.getInstance().put('userId', userId)
    PreferencesUtil.getInstance().put(Constants.KEY_USER_NAME, name)
  }

  logout(): void {
    this.currentUser = null
    this.isLogin = false
    const prefsUtil: PreferencesUtil = PreferencesUtil.getInstance()
    prefsUtil.put(Constants.KEY_IS_LOGIN, false)
  }

  getUserInfo(): User | null {
    return this.currentUser
  }

  isUserLoggedIn(): boolean {
    return this.isLogin
  }

  isFirstLaunch(): boolean {
    return PreferencesUtil.getInstance().getBoolean(Constants.KEY_IS_FIRST_LAUNCH, true)
  }

  setFirstLaunchDone(): void {
    PreferencesUtil.getInstance().put(Constants.KEY_IS_FIRST_LAUNCH, false)
  }

  getFontSizeLevel(): number {
    return PreferencesUtil.getInstance().getNumber(Constants.KEY_FONT_SIZE_LEVEL, 0)
  }

  setFontSizeLevel(level: number): void {
    PreferencesUtil.getInstance().put(Constants.KEY_FONT_SIZE_LEVEL, level)
  }

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
