/**
 * TitleBar - 通用顶部导航栏组件
 * 包含：返回按钮（<）、居中标题、右侧占位
 * 使用方式：在页面中引入 <TitleBar title="页面标题" />
 * 点击返回按钮调用 router.back()
 */
@Component
export struct TitleBar {
  @Prop title: string = ''

  build() {
    Row() {
      Text('<')
        .fontSize(22)
        .fontColor('#333333')

      Text(this.title)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      Blank()
        .width(22)
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor(Color.White)
  }
}
