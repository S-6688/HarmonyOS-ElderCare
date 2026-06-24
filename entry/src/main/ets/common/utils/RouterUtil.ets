/**
 * RouterUtil - 路由工具类
 * 封装 @kit.ArkUI 的 router API，提供简洁的页面跳转方法
 * push: 压入新页面（可返回）
 * replace: 替换当前页面（不可返回，用于登录/闪屏等场景）
 * back: 返回上一页
 * 注意：当前页面已改用 getUIContext().getRouter() 方式，此工具类为旧版兼容保留
 */
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
