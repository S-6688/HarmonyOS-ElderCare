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
