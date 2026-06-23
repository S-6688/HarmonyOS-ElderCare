import { preferences } from '@kit.ArkData'
import { common } from '@kit.AbilityKit'
import { Constants } from '../constants/Constants'

export class PreferencesUtil {
  private static instance: PreferencesUtil = new PreferencesUtil()
  private prefs: preferences.Preferences | null = null
  private appContext: common.Context | null = null

  static getInstance(): PreferencesUtil {
    return PreferencesUtil.instance
  }

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

  getBoolean(key: string, defValue: boolean): boolean {
    try {
      return this.getPrefs().getSync(key, defValue) as boolean
    } catch (e) {
      console.error('PreferencesUtil getBoolean failed: ' + JSON.stringify(e))
      return defValue
    }
  }

  getString(key: string, defValue: string): string {
    try {
      return this.getPrefs().getSync(key, defValue) as string
    } catch (e) {
      console.error('PreferencesUtil getString failed: ' + JSON.stringify(e))
      return defValue
    }
  }

  getNumber(key: string, defValue: number): number {
    try {
      return this.getPrefs().getSync(key, defValue) as number
    } catch (e) {
      console.error('PreferencesUtil getNumber failed: ' + JSON.stringify(e))
      return defValue
    }
  }

  put(key: string, value: preferences.ValueType): void {
    try {
      this.getPrefs().putSync(key, value)
      this.getPrefs().flush()
    } catch (e) {
      console.error('PreferencesUtil put failed: ' + JSON.stringify(e))
    }
  }

  getPreferences(): preferences.Preferences {
    return this.getPrefs()
  }
}
