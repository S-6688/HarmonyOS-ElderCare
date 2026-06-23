import { router } from '@kit.ArkUI'

export class RouterUtil {
  static push(url: string): void {
    router.pushUrl({ url: url })
  }

  static replace(url: string): void {
    router.replaceUrl({ url: url })
  }

  static back(): void {
    router.back()
  }
}
