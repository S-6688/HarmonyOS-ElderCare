/**
 * Styles - 全局样式常量定义
 * AppColors: 颜色常量，统一管理应用色彩体系
 * AppSizes: 尺寸常量，定义按钮高度、圆角、间距等规范
 * scaledSize(): 字体自适应缩放函数，根据 fontSizeLevel 增大字号
 */
export class AppColors {
  static readonly PRIMARY: string = '#1A56DB'       // 主色（蓝色，用于标题、按钮、选中态）
  static readonly PRIMARY_LIGHT: string = '#EBF0FF'  // 主色浅色（用于背景高亮、标签背景）
  static readonly DANGER: string = '#E84040'         // 危险色（红色，用于紧急呼叫、删除、退出）
  static readonly DANGER_LIGHT: string = '#FEF0F0'   // 危险色浅色
  static readonly SUCCESS: string = '#10B981'        // 成功色（绿色，用于"已登录"状态）
  static readonly WARNING: string = '#F59E0B'        // 警告色（黄色，用于优先联系人标签）
  static readonly PURPLE: string = '#7B61FF'         // 紫色（用于血糖卡片、编辑按钮）
  static readonly BG_PAGE: string = '#F5F7FA'        // 页面背景色
  static readonly BG_CARD: string = '#FFFFFF'        // 卡片背景色（白色）
  static readonly BG_CARD_SOFT: string = '#F5F7FA'   // 卡片浅背景色
  static readonly TEXT_PRIMARY: string = '#333333'   // 主文字颜色
  static readonly TEXT_SECONDARY: string = '#666666' // 辅助文字颜色
  static readonly TEXT_HINT: string = '#999999'      // 提示文字颜色
  static readonly TEXT_WHITE: string = '#FFFFFF'     // 白色文字
  static readonly DIVIDER: string = '#EEEEEE'        // 分割线颜色
  static readonly ICON_BG: string = '#F0F0F0'        // 图标背景色
}

export class AppSizes {
  static readonly FONT_LEVEL_STANDARD: number = 0 // 字体等级：标准
  static readonly FONT_LEVEL_LARGE: number = 1    // 字体等级：较大
  static readonly FONT_LEVEL_MAX: number = 2      // 字体等级：最大
  static readonly FONT_SCALE_STEP: number = 4     // 每级字体增大像素值（base + level * 4）
  static readonly MIN_TOUCH: number = 48          // 最小触摸目标尺寸（dp），保证老年人可操作
  static readonly BUTTON_HEIGHT: number = 56      // 按钮标准高度
  static readonly BAR_HEIGHT: number = 56         // 顶部导航栏高度
  static readonly CARD_RADIUS: number = 12        // 卡片圆角半径
  static readonly BUTTON_RADIUS: number = 28      // 按钮圆角半径（半圆按钮）
  static readonly PAGE_PADDING: number = 16       // 页面内边距
  static readonly CARD_PADDING: number = 16       // 卡片内边距
  static readonly ITEM_SPACE: number = 8          // 列表项间距
  static readonly SECTION_SPACE: number = 12      // 区块间距
}

/**
 * 字体自适应缩放函数
 * 根据字体大小等级计算实际字号，等级越高字号越大
 * @param base 基础字号
 * @param fontSizeLevel 字体等级（0=标准，1=较大，2=最大）
 * @returns 缩放后的字号
 */
export function scaledSize(base: number, fontSizeLevel: number): number {
  return base + fontSizeLevel * AppSizes.FONT_SCALE_STEP
}
