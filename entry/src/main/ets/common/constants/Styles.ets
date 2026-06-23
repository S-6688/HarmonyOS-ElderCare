export class AppColors {
  static readonly PRIMARY: string = '#1A56DB'
  static readonly PRIMARY_LIGHT: string = '#EBF0FF'
  static readonly DANGER: string = '#E84040'
  static readonly DANGER_LIGHT: string = '#FEF0F0'
  static readonly SUCCESS: string = '#10B981'
  static readonly WARNING: string = '#F59E0B'
  static readonly PURPLE: string = '#7B61FF'
  static readonly BG_PAGE: string = '#F5F7FA'
  static readonly BG_CARD: string = '#FFFFFF'
  static readonly BG_CARD_SOFT: string = '#F5F7FA'
  static readonly TEXT_PRIMARY: string = '#333333'
  static readonly TEXT_SECONDARY: string = '#666666'
  static readonly TEXT_HINT: string = '#999999'
  static readonly TEXT_WHITE: string = '#FFFFFF'
  static readonly DIVIDER: string = '#EEEEEE'
  static readonly ICON_BG: string = '#F0F0F0'
}

export class AppSizes {
  static readonly FONT_LEVEL_STANDARD: number = 0
  static readonly FONT_LEVEL_LARGE: number = 1
  static readonly FONT_LEVEL_MAX: number = 2
  static readonly FONT_SCALE_STEP: number = 4
  static readonly MIN_TOUCH: number = 48
  static readonly BUTTON_HEIGHT: number = 56
  static readonly BAR_HEIGHT: number = 56
  static readonly CARD_RADIUS: number = 12
  static readonly BUTTON_RADIUS: number = 28
  static readonly PAGE_PADDING: number = 16
  static readonly CARD_PADDING: number = 16
  static readonly ITEM_SPACE: number = 8
  static readonly SECTION_SPACE: number = 12
}

export function scaledSize(base: number, fontSizeLevel: number): number {
  return base + fontSizeLevel * AppSizes.FONT_SCALE_STEP
}

export function setAccessibility(text: string): void {
}
