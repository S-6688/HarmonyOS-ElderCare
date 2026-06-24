/**
 * Constants - 全局常量定义
 * 集中管理 Preferences 键名和应用级常量，避免硬编码
 * 与 PreferencesUtil 配合使用，所有键名在此统一定义
 */
import { AppColors } from './Styles'

export class Constants {
  static readonly APP_NAME: string = '银龄通'                     // 应用名称
  static readonly APP_BUNDLE_NAME: string = 'com.example.eldercare' // 应用包名
  static readonly THEME_COLOR: string = AppColors.PRIMARY         // 主题色
  static readonly DANGER_COLOR: string = AppColors.DANGER         // 危险色（紧急呼叫等）
  static readonly BG_COLOR: string = AppColors.BG_PAGE            // 页面背景色
  static readonly TEXT_PRIMARY: string = AppColors.TEXT_PRIMARY    // 主文字色
  static readonly TEXT_SECONDARY: string = AppColors.TEXT_HINT    // 辅助文字色
  static readonly PREFERENCES_NAME: string = 'eldercare_prefs'    // Preferences 存储文件名
  static readonly KEY_IS_LOGIN: string = 'isLogin'                // 登录状态键
  static readonly KEY_USER_NAME: string = 'userName'              // 用户姓名键
  static readonly KEY_FONT_SIZE_LEVEL: string = 'fontSizeLevel'   // 字体大小等级键（0/1/2）
  static readonly KEY_FAVORITE_IDS: string = 'favoriteArticleIds' // 收藏文章ID列表键（逗号分隔）
  static readonly KEY_IS_FIRST_LAUNCH: string = 'isFirstLaunch'   // 首次启动标记键
  static readonly KEY_GUIDE_VERSION: string = 'guideVersion'      // 已完成引导页版本键
  static readonly CURRENT_GUIDE_VERSION: number = 2               // 当前引导页版本，递增后旧模拟器会重新展示引导
  static readonly KEY_EMERGENCY_CONTACTS: string = 'emergencyContacts' // 紧急联系人JSON键
}
