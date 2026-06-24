/**
 * HealthRecord - 健康记录页面
 * 功能：
 *   - 按类型切换查看健康数据（血压/血糖/心率/体温）
 *   - Canvas 绘制近7日趋势折线图
 *   - 半模态弹窗（bindSheet）录入新健康数据
 *   - 左滑删除历史记录
 *   - 登录状态校验，未登录跳转登录页
 */
import { HealthData } from '../model/HealthData'
import { HealthViewModel } from '../viewmodel/HealthViewModel'
import { AppColors, AppSizes, scaledSize } from '../common/constants/Styles'
import { Constants } from '../common/constants/Constants'
import { PreferencesUtil } from '../common/utils/PreferencesUtil'

const HEALTH_TYPES: string[] = ['血压', '血糖', '心率', '体温'] // 健康指标类型列表
const TYPE_UNITS: Record<string, string> = { '血压': 'mmHg', '血糖': 'mmol/L', '心率': '次/分', '体温': '°C' }
const TYPE_ICONS: Record<string, string> = { '血压': '压', '血糖': '糖', '心率': '心', '体温': '温' }
const TYPE_COLORS: Record<string, string[]> = {
  '血压': ['#1A56DB', '#5B8DEF'],
  '血糖': ['#7B61FF', '#B8A9FF'],
  '心率': ['#E74C3C', '#F1948A'],
  '体温': ['#F59E0B', '#FCD34D']
}

/** 趋势图数据点 */
class TrendPoint {
  label: string = '' // X轴标签（如 "6/24"）
  value: number = 0  // Y轴数值
}

/** Canvas 绘图坐标点 */
class ChartPoint {
  x: number = 0
  y: number = 0
}

@Entry
@Component
struct HealthRecord {
  @State currentTypeIndex: number = 0                      // 当前选中的健康类型索引
  @StorageLink('fontSizeLevel') fontSizeLevel: number = 0  // 全局字体等级
  @StorageLink('isLogin') isLogin: boolean = false          // 全局登录状态
  @State showAddSheet: boolean = false                      // 是否显示录入弹窗
  @State addTypeIndex: number = 0                           // 录入弹窗中的类型索引
  @State addValue: string = ''                              // 录入数值
  @State addNote: string = ''                               // 录入备注
  @State addDate: Date = new Date()                         // 录入日期
  @State filteredRecords: HealthData[] = []                 // 当前类型的健康记录列表
  @State trendPoints: TrendPoint[] = []                     // 趋势图数据点
  @State sheetOpacity: number = 0                           // 弹窗透明度动画
  @State sheetTranslateY: number = 300                      // 弹窗平移动画
  private healthViewModel: HealthViewModel = new HealthViewModel()
  private listScroller: ListScroller = new ListScroller()   // 列表滚动控制器（用于关闭滑动操作）
  private settings: RenderingContextSettings = new RenderingContextSettings(true) // Canvas 抗锯齿设置
  private canvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings) // Canvas 绘图上下文

  private sz(base: number): number {
    return scaledSize(base, this.fontSizeLevel)
  }

  aboutToAppear(): void {
    const hostContext = this.getUIContext().getHostContext()
    if (hostContext) {
      PreferencesUtil.getInstance().ensureInit(hostContext)
    }
    this.checkLoginStatus()
    this.loadSampleData()
    this.updateFilteredData()
  }

  private checkLoginStatus(): void {
    const loginStatus: boolean = PreferencesUtil.getInstance().getBoolean(Constants.KEY_IS_LOGIN, false)
    if (!loginStatus) {
      try {
        this.getUIContext().getRouter().replaceUrl({ url: 'pages/LoginPage' })
      } catch (e) {
        console.error('replaceUrl failed: ' + JSON.stringify(e))
      }
    }
  }

  private loadSampleData(): void {
    const now: number = Date.now()
    const dayMs: number = 24 * 60 * 60 * 1000
    const samples: HealthData[] = [
      new HealthData(1, '血压', '125/82', 'mmHg', now - 6 * dayMs, ''),
      new HealthData(2, '血压', '130/85', 'mmHg', now - 5 * dayMs, '略高'),
      new HealthData(3, '血压', '122/80', 'mmHg', now - 4 * dayMs, ''),
      new HealthData(4, '血压', '128/83', 'mmHg', now - 3 * dayMs, ''),
      new HealthData(5, '血压', '118/78', 'mmHg', now - 2 * dayMs, '正常'),
      new HealthData(6, '血压', '120/80', 'mmHg', now - 1 * dayMs, ''),
      new HealthData(7, '血压', '126/81', 'mmHg', now, '今日'),
      new HealthData(8, '血糖', '5.8', 'mmol/L', now - 6 * dayMs, ''),
      new HealthData(9, '血糖', '6.2', 'mmol/L', now - 5 * dayMs, '偏高'),
      new HealthData(10, '血糖', '5.5', 'mmol/L', now - 4 * dayMs, ''),
      new HealthData(11, '血糖', '5.9', 'mmol/L', now - 3 * dayMs, ''),
      new HealthData(12, '血糖', '5.6', 'mmol/L', now - 2 * dayMs, '正常'),
      new HealthData(13, '血糖', '6.0', 'mmol/L', now - 1 * dayMs, ''),
      new HealthData(14, '血糖', '5.7', 'mmol/L', now, '今日'),
      new HealthData(15, '心率', '72', '次/分', now - 6 * dayMs, ''),
      new HealthData(16, '心率', '75', '次/分', now - 5 * dayMs, ''),
      new HealthData(17, '心率', '68', '次/分', now - 4 * dayMs, '偏低'),
      new HealthData(18, '心率', '70', '次/分', now - 3 * dayMs, ''),
      new HealthData(19, '心率', '74', '次/分', now - 2 * dayMs, ''),
      new HealthData(20, '心率', '71', '次/分', now - 1 * dayMs, ''),
      new HealthData(21, '心率', '73', '次/分', now, '今日'),
      new HealthData(22, '体温', '36.5', '°C', now - 6 * dayMs, ''),
      new HealthData(23, '体温', '36.6', '°C', now - 5 * dayMs, ''),
      new HealthData(24, '体温', '36.8', '°C', now - 4 * dayMs, ''),
      new HealthData(25, '体温', '36.4', '°C', now - 3 * dayMs, ''),
      new HealthData(26, '体温', '36.7', '°C', now - 2 * dayMs, ''),
      new HealthData(27, '体温', '36.5', '°C', now - 1 * dayMs, ''),
      new HealthData(28, '体温', '36.6', '°C', now, '今日'),
    ]
    for (const sample of samples) {
      this.healthViewModel.addHealthRecord(sample)
    }
  }

  /**
   * 更新当前类型的健康记录和趋势图数据
   * 在切换类型、添加/删除记录后调用
   */
  private updateFilteredData(): void {
    const currentType: string = HEALTH_TYPES[this.currentTypeIndex]
    const records: HealthData[] = this.healthViewModel.getHealthRecords(currentType)
    this.filteredRecords = records.sort((a: HealthData, b: HealthData) => b.recordTime - a.recordTime)
    this.buildTrendPoints()
  }

  /**
   * 构建趋势图数据点
   * 取最近7条记录，按时间升序排列
   * 血压取收缩压（斜线前的数值），其他类型直接取数值
   */
  private buildTrendPoints(): void {
    const currentType: string = HEALTH_TYPES[this.currentTypeIndex]
    const records: HealthData[] = this.healthViewModel.getHealthRecords(currentType)
      .sort((a: HealthData, b: HealthData) => a.recordTime - b.recordTime)
    const recentRecords: HealthData[] = records.slice(-7)
    const points: TrendPoint[] = []
    for (const record of recentRecords) {
      const date: Date = new Date(record.recordTime)
      const label: string = `${date.getMonth() + 1}/${date.getDate()}`
      let numericValue: number = 0
      if (record.type === '血压') {
        const parts: string[] = record.value.split('/')
        if (parts.length >= 1) {
          numericValue = parseFloat(parts[0])
        }
      } else {
        numericValue = parseFloat(record.value)
      }
      const point: TrendPoint = new TrendPoint()
      point.label = label
      point.value = numericValue
      points.push(point)
    }
    this.trendPoints = points
  }

  /** 提取健康记录的数值（血压取收缩压，其他直接取数值） */
  private extractNumericValue(record: HealthData): number {
    if (record.type === '血压') {
      const parts: string[] = record.value.split('/')
      if (parts.length >= 1) {
        return parseFloat(parts[0])
      }
      return 0
    }
    return parseFloat(record.value)
  }

  /** 格式化时间戳为中文日期时间（如 "6月24日 08:30"） */
  private formatRecordTime(timestamp: number): string {
    const date: Date = new Date(timestamp)
    const month: number = date.getMonth() + 1
    const day: number = date.getDate()
    const hour: number = date.getHours()
    const minute: number = date.getMinutes()
    const hourStr: string = hour < 10 ? `0${hour}` : `${hour}`
    const minuteStr: string = minute < 10 ? `0${minute}` : `${minute}`
    return `${month}月${day}日 ${hourStr}:${minuteStr}`
  }

  /**
   * 添加新的健康记录
   * 流程：构建 HealthData → 添加到 ViewModel → 关闭弹窗 → 刷新列表和趋势图
   */
  private addNewRecord(): void {
    const currentType: string = HEALTH_TYPES[this.addTypeIndex]
    const unit: string = TYPE_UNITS[currentType] || ''
    if (this.addValue.length === 0) {
      return
    }
    const newRecord: HealthData = new HealthData(
      Date.now(),
      currentType,
      this.addValue,
      unit,
      this.addDate.getTime(),
      this.addNote
    )
    this.healthViewModel.addHealthRecord(newRecord)
    this.showAddSheet = false
    this.addValue = ''
    this.addNote = ''
    this.addDate = new Date()
    this.addTypeIndex = this.currentTypeIndex
    this.updateFilteredData()
  }

  private deleteRecord(id: number): void {
    this.healthViewModel.deleteHealthRecord(id)
    this.updateFilteredData()
  }

  @Builder
  AddSheetBuilder() {
    Column() {
      Row() {
        Text('录入健康数据')
          .fontSize(this.sz(22))
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')
          .layoutWeight(1)

        Text('✕')
          .fontSize(this.sz(24))
          .fontColor('#999999')
          .padding(8)
          .onClick(() => {
            this.showAddSheet = false
          })
      }
      .width('100%')
      .padding({ left: 24, right: 24, top: 16, bottom: 8 })

      Scroll() {
        Column({ space: 20 }) {
          Column() {
            Text('类型')
              .fontSize(this.sz(16))
              .fontColor('#666666')
              .width('100%')
              .margin({ bottom: 8 })

            Row({ space: 8 }) {
              ForEach(HEALTH_TYPES, (type: string, index?: number) => {
                Text(type)
                  .fontSize(this.sz(16))
                  .fontColor(this.addTypeIndex === index ? Color.White : '#333333')
                  .padding({ left: 16, right: 16, top: 10, bottom: 10 })
                  .borderRadius(20)
                  .backgroundColor(this.addTypeIndex === index ? '#1A56DB' : '#F0F0F0')
                  .accessibilityText(`${type}类型选择`)
                  .accessibilityLevel('yes')
                  .onClick(() => {
                    this.addTypeIndex = index as number
                  })
              }, (type: string, index?: number) => `${index}_${type}`)
            }
            .width('100%')
          }
          .width('100%')

          Column() {
            Text('数值')
              .fontSize(this.sz(16))
              .fontColor('#666666')
              .width('100%')
              .margin({ bottom: 8 })

            Row() {
              TextInput({ text: this.addValue, placeholder: '请输入数值' })
                .type(InputType.Number)
                .fontSize(this.sz(20))
                .layoutWeight(1)
                .padding({ left: 16, right: 16 })
                .height(56)
                .borderRadius(12)
                .backgroundColor('#F5F5F5')
                .onChange((value: string) => {
                  this.addValue = value
                })

              Text(TYPE_UNITS[HEALTH_TYPES[this.addTypeIndex]] || '')
                .fontSize(this.sz(18))
                .fontColor('#666666')
                .margin({ left: 8 })
                .width(60)
          }
            .width('100%')
          }
          .width('100%')

          Column() {
            Text('日期')
              .fontSize(this.sz(16))
              .fontColor('#666666')
              .width('100%')
              .margin({ bottom: 8 })

            DatePicker({
              start: new Date('2020-01-01'),
              end: new Date('2030-12-31'),
              selected: this.addDate
            })
              .lunar(false)
              .onDateChange((value: Date) => {
                this.addDate = value
              })
          }
          .width('100%')

          Column() {
            Text('备注')
              .fontSize(this.sz(16))
              .fontColor('#666666')
              .width('100%')
              .margin({ bottom: 8 })

            TextInput({ text: this.addNote, placeholder: '选填，如：饭后测量' })
              .fontSize(this.sz(18))
              .padding({ left: 16, right: 16 })
              .height(56)
              .borderRadius(12)
              .backgroundColor('#F5F5F5')
              .onChange((value: string) => {
                this.addNote = value
              })
          }
          .width('100%')

          Button('保存记录')
            .width('100%')
            .height(56)
            .fontSize(this.sz(22))
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.White)
            .backgroundColor('#1A56DB')
            .borderRadius(28)
            .margin({ top: 8 })
            .accessibilityText('保存健康记录')
            .accessibilityLevel('yes')
            .onClick(() => {
              this.addNewRecord()
            })
        }
        .padding({ left: 24, right: 24, top: 8, bottom: 24 })
      }
      .scrollBar(BarState.Off)
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
  }

  @Builder
  SwipeDeleteBuilder(record: HealthData) {
    Row() {
      Button('删除')
        .width(70)
        .height('100%')
        .fontSize(this.sz(16))
        .fontColor(Color.White)
        .backgroundColor('#E74C3C')
        .borderRadius(0)
        .accessibilityText('删除此记录')
        .accessibilityLevel('yes')
        .onClick(() => {
            this.listScroller.closeAllSwipeActions()
            this.getUIContext().animateTo({ duration: 300, curve: Curve.EaseOut }, () => {
              this.deleteRecord(record.id)
            })
        })
    }
  }

  /**
   * Canvas 绘制趋势折线图
   * 包含：网格线 → Y轴刻度 → 折线 → 渐变填充区域 → 数据点圆点 → X轴标签
   * 数据不足2条时显示提示文字
   */
  private drawTrendChart(): void {
    const ctx: CanvasRenderingContext2D = this.canvasContext
    if (!ctx) {
      return
    }
    const width: number = ctx.width
    const height: number = ctx.height
    if (width <= 0 || height <= 0) {
      return
    }
    ctx.clearRect(0, 0, width, height)
    const data: TrendPoint[] = this.trendPoints
    if (data.length < 2) {
      ctx.fillStyle = '#999999'
      ctx.font = '16px sans-serif'
      ctx.textAlign = 'center'
      ctx.fillText('数据不足，至少需要2条记录', width / 2, height / 2)
      return
    }
    const padding: number = 36
    const chartWidth: number = width - padding * 2
    const chartHeight: number = height - padding * 2 - 20
    const chartTop: number = padding
    let minVal: number = data[0].value
    let maxVal: number = data[0].value
    for (let i = 1; i < data.length; i++) {
      if (data[i].value < minVal) {
        minVal = data[i].value
      }
      if (data[i].value > maxVal) {
        maxVal = data[i].value
      }
    }
    const rangePadding: number = Math.max((maxVal - minVal) * 0.15, 1)
    minVal = minVal - rangePadding
    maxVal = maxVal + rangePadding
    const range: number = maxVal - minVal
    const currentType: string = HEALTH_TYPES[this.currentTypeIndex]
    const lineColor: string = TYPE_COLORS[currentType] ? TYPE_COLORS[currentType][0] : '#1A56DB'
    const gradientColor: string = TYPE_COLORS[currentType] ? TYPE_COLORS[currentType][1] : '#5B8DEF'

    ctx.strokeStyle = '#E8E8E8'
    ctx.lineWidth = 0.5
    for (let i = 0; i <= 4; i++) {
      const y: number = chartTop + (chartHeight / 4) * i
      ctx.beginPath()
      ctx.moveTo(padding, y)
      ctx.lineTo(width - padding, y)
      ctx.stroke()
      const val: number = maxVal - (range / 4) * i
      ctx.fillStyle = '#999999'
      ctx.font = '11px sans-serif'
      ctx.textAlign = 'right'
      ctx.fillText(val.toFixed(0), padding - 6, y + 4)
    }

    const stepX: number = chartWidth / (data.length - 1)
    const points: ChartPoint[] = []
    for (let i = 0; i < data.length; i++) {
      const x: number = padding + i * stepX
      const y: number = chartTop + chartHeight - ((data[i].value - minVal) / range) * chartHeight
      const point: ChartPoint = new ChartPoint()
      point.x = x
      point.y = y
      points.push(point)
    }

    ctx.beginPath()
    ctx.moveTo(points[0].x, points[0].y)
    for (let i = 1; i < points.length; i++) {
      ctx.lineTo(points[i].x, points[i].y)
    }
    ctx.strokeStyle = lineColor
    ctx.lineWidth = 2.5
    ctx.stroke()

    ctx.beginPath()
    ctx.moveTo(points[0].x, chartTop + chartHeight)
    ctx.lineTo(points[0].x, points[0].y)
    for (let i = 0; i < points.length - 1; i++) {
      ctx.lineTo(points[i + 1].x, points[i + 1].y)
    }
    ctx.lineTo(points[points.length - 1].x, chartTop + chartHeight)
    ctx.closePath()
    const gradient: CanvasGradient = ctx.createLinearGradient(0, chartTop, 0, chartTop + chartHeight)
    gradient.addColorStop(0, gradientColor + '40')
    gradient.addColorStop(1, gradientColor + '05')
    ctx.fillStyle = gradient
    ctx.fill()

    for (let i = 0; i < points.length; i++) {
      ctx.beginPath()
      ctx.arc(points[i].x, points[i].y, 5, 0, 2 * Math.PI)
      ctx.fillStyle = lineColor
      ctx.fill()
      ctx.beginPath()
      ctx.arc(points[i].x, points[i].y, 3, 0, 2 * Math.PI)
      ctx.fillStyle = Color.White
      ctx.fill()

      ctx.fillStyle = '#666666'
      ctx.font = '11px sans-serif'
      ctx.textAlign = 'center'
      ctx.fillText(data[i].label, points[i].x, chartTop + chartHeight + 16)
    }
  }

  build() {
    Column() {
      Row() {
        Text('<')
          .fontSize(this.sz(22))
          .fontColor('#333333')
          .padding({ right: 8 })
          .accessibilityText('返回')
          .accessibilityLevel('yes')
          .onClick(() => {
            this.getUIContext().getRouter().back()
          })

        Text('健康记录')
          .fontSize(this.sz(20))
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Text('+')
          .fontSize(this.sz(28))
          .fontColor('#1A56DB')
          .fontWeight(FontWeight.Bold)
          .padding({ left: 12, right: 12 })
          .accessibilityText('添加健康记录')
          .accessibilityLevel('yes')
          .onClick(() => {
             this.addTypeIndex = this.currentTypeIndex
             this.getUIContext().animateTo({ duration: 300, curve: Curve.EaseOut }, () => {
               this.showAddSheet = true
             })
          })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor(Color.White)

      Row() {
        ForEach(HEALTH_TYPES, (type: string, index?: number) => {
          Column() {
            Text(type)
              .fontSize(this.sz(16))
              .fontWeight(this.currentTypeIndex === index ? FontWeight.Medium : FontWeight.Normal)
              .fontColor(this.currentTypeIndex === index ? '#1A56DB' : '#666666')

            Row()
              .width(24)
              .height(3)
              .borderRadius(2)
              .backgroundColor(this.currentTypeIndex === index ? '#1A56DB' : 'transparent')
              .margin({ top: 6 })
          }
          .layoutWeight(1)
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .accessibilityText(`${type}分类`)
          .accessibilityLevel('yes')
          .onClick(() => {
            this.currentTypeIndex = index as number
            this.updateFilteredData()
          })
        }, (type: string, index?: number) => `${index}_${type}`)
      }
      .width('100%')
      .height(48)
      .backgroundColor(Color.White)
      .margin({ bottom: 12 })

      Scroll() {
        Column() {
          Column() {
            Row() {
              Text('近7日趋势')
                .fontSize(this.sz(18))
                .fontWeight(FontWeight.Medium)
                .fontColor('#1A1A1A')
                .layoutWeight(1)

              Text(HEALTH_TYPES[this.currentTypeIndex])
                .fontSize(this.sz(14))
                .fontColor('#1A56DB')
            }
            .width('100%')
            .margin({ bottom: 8 })

            if (this.trendPoints.length >= 2) {
              Canvas(this.canvasContext)
                .width('100%')
                .height(180)
                .onReady(() => {
                  this.drawTrendChart()
                })
            } else {
              Column() {
                Text('暂无足够数据绘制趋势图')
                  .fontSize(this.sz(16))
                  .fontColor('#999999')
              }
              .width('100%')
              .height(180)
              .justifyContent(FlexAlign.Center)
            }
          }
          .width('92%')
          .padding(16)
          .backgroundColor(Color.White)
          .borderRadius(16)

          Column() {
            Row() {
              Text('历史记录')
                .fontSize(this.sz(18))
                .fontWeight(FontWeight.Medium)
                .fontColor('#1A1A1A')
                .layoutWeight(1)

              Text(`${this.filteredRecords.length}条`)
                .fontSize(this.sz(14))
                .fontColor('#999999')
            }
            .width('100%')
            .margin({ bottom: 8 })

            if (this.filteredRecords.length === 0) {
              Column() {
                Text('暂无记录')
                  .fontSize(this.sz(18))
                  .fontColor('#999999')

                Text('点击右上角"+"添加')
                  .fontSize(this.sz(14))
                  .fontColor('#CCCCCC')
                  .margin({ top: 4 })
              }
              .width('100%')
              .padding(40)
              .alignItems(HorizontalAlign.Center)
            } else {
              List({ space: 8, scroller: this.listScroller }) {
                ForEach(this.filteredRecords, (record: HealthData, index?: number) => {
                  ListItem() {
                    Row() {
                      Column() {
                        Text(TYPE_ICONS[record.type] || '健')
                          .fontSize(this.sz(20))
                          .fontColor(Color.White)
                          .fontWeight(FontWeight.Bold)
                      }
                      .width(44)
                      .height(44)
                      .borderRadius(22)
                      .justifyContent(FlexAlign.Center)
                      .linearGradient({
                        angle: 135,
                        colors: TYPE_COLORS[record.type]
                          ? [[TYPE_COLORS[record.type][0], 0.0], [TYPE_COLORS[record.type][1], 1.0]]
                          : [['#1A56DB', 0.0], ['#5B8DEF', 1.0]]
                      })
                      .margin({ right: 12 })

                      Column() {
                        Row() {
                          Text(record.value)
                            .fontSize(this.sz(20))
                            .fontWeight(FontWeight.Medium)
                            .fontColor('#1A1A1A')

                          Text(record.unit)
                            .fontSize(this.sz(14))
                            .fontColor('#999999')
                            .margin({ left: 6 })
                        }

                        Text(this.formatRecordTime(record.recordTime))
                          .fontSize(this.sz(13))
                          .fontColor('#999999')
                          .margin({ top: 4 })
                      }
                      .alignItems(HorizontalAlign.Start)
                      .layoutWeight(1)

                      if (record.note.length > 0) {
                        Text(record.note)
                          .fontSize(this.sz(13))
                          .fontColor('#1A56DB')
                          .backgroundColor('#EBF0FF')
                          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                          .borderRadius(10)
                          .maxLines(1)
                      }
                    }
                    .width('100%')
                    .padding(16)
                    .backgroundColor(Color.White)
                    .borderRadius(12)
                    .alignItems(VerticalAlign.Center)
                  }
                  .swipeAction({
                    end: {
                      builder: () => {
                        this.SwipeDeleteBuilder(record)
                      }
                    }
                  })
                }, (record: HealthData, index?: number) => `${record.id}`)
              }
              .width('100%')
              .scrollBar(BarState.Off)
            }
          }
          .width('92%')
          .margin({ top: 12 })
          .padding(16)
          .backgroundColor(Color.White)
          .borderRadius(16)

          Blank()
            .height(24)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      }
      .scrollBar(BarState.Off)
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
    .bindSheet($$this.showAddSheet, this.AddSheetBuilder(), {
      detents: [SheetSize.LARGE],
      backgroundColor: Color.White,
      dragBar: true,
      showClose: false,
      onDisappear: () => {
        this.showAddSheet = false
      }
    })
  }
}
