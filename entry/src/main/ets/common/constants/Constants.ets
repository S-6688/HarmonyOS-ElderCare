import { AppColors } from './Styles'

export class Constants {
  static readonly APP_NAME: string = '银龄通'
  static readonly APP_BUNDLE_NAME: string = 'com.example.eldercare'
  static readonly THEME_COLOR: string = AppColors.PRIMARY
  static readonly DANGER_COLOR: string = AppColors.DANGER
  static readonly BG_COLOR: string = AppColors.BG_PAGE
  static readonly TEXT_PRIMARY: string = AppColors.TEXT_PRIMARY
  static readonly TEXT_SECONDARY: string = AppColors.TEXT_HINT
  static readonly PREFERENCES_NAME: string = 'eldercare_prefs'
  static readonly KEY_IS_LOGIN: string = 'isLogin'
  static readonly KEY_USER_NAME: string = 'userName'
  static readonly KEY_FONT_SIZE_LEVEL: string = 'fontSizeLevel'
  static readonly KEY_FAVORITE_IDS: string = 'favoriteArticleIds'
  static readonly KEY_IS_FIRST_LAUNCH: string = 'isFirstLaunch'
  static readonly KEY_EMERGENCY_CONTACTS: string = 'emergencyContacts'
}
