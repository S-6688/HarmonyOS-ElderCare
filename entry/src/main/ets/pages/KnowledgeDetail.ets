/**
 * KnowledgeDetail - 文章详情页面
 * 功能：
 *   - 从路由参数获取 articleId，加载对应文章内容
 *   - 收藏/取消收藏文章（星标按钮 + 底部收藏按钮）
 *   - 收藏状态持久化到 Preferences
 * 注意：当前文章数据为硬编码示例数据，未使用数据库持久化
 */
import { KnowledgeArticle } from '../model/KnowledgeArticle'
import { AppColors, AppSizes, scaledSize } from '../common/constants/Styles'
import { Constants } from '../common/constants/Constants'
import { PreferencesUtil } from '../common/utils/PreferencesUtil'

const CATEGORY_COLORS: Record<string, string> = {
  '饮食养生': '#F59E0B', '运动保健': '#10B981', '心理健康': '#7B61FF',
  '慢病管理': '#E74C3C', '季节养生': '#1A56DB'
}

@Entry
@Component
struct KnowledgeDetail {
  @StorageLink('fontSizeLevel') fontSizeLevel: number = 0
  @State article: KnowledgeArticle = new KnowledgeArticle() // 当前文章
  @State articleLoaded: boolean = false                     // 文章是否加载完成
  @State isFavorite: boolean = false                        // 当前文章是否已收藏
  private favoriteIds: number[] = []                        // 收藏文章ID列表

  private sz(base: number): number {
    return scaledSize(base, this.fontSizeLevel)
  }

  /**
   * 页面初始化
   * 加载收藏ID列表 → 从路由参数获取 articleId → 加载文章详情
   */
  aboutToAppear(): void {
    const hostContext = this.getUIContext().getHostContext()
    if (hostContext) {
      PreferencesUtil.getInstance().ensureInit(hostContext)
    }
    this.loadFavoriteIds()
    // 从路由参数中获取文章ID
    const params: Record<string, Object> = this.getUIContext().getRouter().getParams() as Record<string, Object>
    if (params && params['articleId']) {
      const articleId: number = params['articleId'] as number
      this.loadArticle(articleId)
    }
  }

  private loadFavoriteIds(): void {
    const idsStr: string = PreferencesUtil.getInstance().getString(Constants.KEY_FAVORITE_IDS, '')
    const ids: number[] = []
    if (idsStr.length > 0) {
      const parts: string[] = idsStr.split(',')
      for (const part of parts) {
        ids.push(parseInt(part))
      }
    }
    this.favoriteIds = ids
  }

  private loadArticle(articleId: number): void {
    const articles: KnowledgeArticle[] = this.getSampleArticles()
    for (const item of articles) {
      if (item.id === articleId) {
        this.article = item
        this.articleLoaded = true
        this.isFavorite = this.favoriteIds.indexOf(articleId) >= 0
        break
      }
    }
  }

  private getSampleArticles(): KnowledgeArticle[] {
    const data: string[][] = [
      ['1', '老年人冬季养生指南', '冬季是老年人养生的重要时期，注意保暖、合理饮食、适度运动，才能健康度过寒冬。', '季节养生',
        '冬季是老年人养生的重要时期。随着气温下降，人体新陈代谢减慢，老年人的身体更容易受到寒冷的侵袭。\n\n一、注意保暖\n冬季保暖是老年人养生的首要任务。外出时要戴好帽子、围巾和手套，特别注意头部、颈部和四肢的保暖。室内温度应保持在18-22℃之间，避免温差过大。\n\n二、合理饮食\n冬季饮食应以温补为主，多食用羊肉、牛肉、鸡肉等温性食物，同时搭配红枣、桂圆、核桃等补品。每天喝一杯温热的牛奶或豆浆，有助于补充蛋白质和钙质。\n\n三、适度运动\n冬季运动不宜过于剧烈，推荐散步、太极拳、八段锦等温和运动方式。运动时间选择在上午10点至下午3点之间，避免早晚气温过低时外出。\n\n四、预防感冒\n冬季是感冒高发季节，老年人应勤洗手、常通风，避免去人多拥挤的场所。可适当补充维生素C，增强免疫力。\n\n五、充足睡眠\n冬季应早睡晚起，保证每天7-8小时的睡眠时间。睡前可用温水泡脚15-20分钟，有助于改善睡眠质量。'],
      ['2', '高血压日常管理方法', '科学控制血压，守护心脑健康。了解高血压的日常管理方法，让您的生活更安心。', '慢病管理',
        '高血压是老年人最常见的慢性病之一，长期高血压会增加心脑血管疾病的风险。\n\n一、定期监测血压\n建议每天至少测量一次血压，最好在早晨起床后和晚上睡前各测一次。记录血压变化，便于医生调整治疗方案。\n\n二、合理用药\n严格按照医生处方服药，不可自行增减药量或停药。降压药通常需要长期服用，即使血压恢复正常也不可擅自停药。\n\n三、低盐饮食\n每日食盐摄入量控制在5克以内。减少腌制食品、酱油、味精等高钠调味品的使用。多食用新鲜蔬果，补充钾元素。\n\n四、控制体重\n超重和肥胖是高血压的重要危险因素。通过合理饮食和适度运动，将体重控制在正常范围内。\n\n五、戒烟限酒\n吸烟和过量饮酒都会导致血压升高。建议彻底戒烟，男性每日饮酒量不超过25克酒精。\n\n六、心理调节\n保持心情舒畅，避免情绪波动过大。可通过听音乐、练习书法、园艺等方式放松身心。'],
      ['3', '合理膳食与营养搭配', '老年人合理膳食是维持健康的基础，科学搭配营养，吃出健康好身体。', '饮食养生',
        '老年人合理膳食是维持健康的基础，随着年龄增长，消化吸收能力下降，更需要注意营养搭配。\n\n一、主食选择\n以粗细搭配为原则，每天摄入200-300克谷物，其中粗粮占三分之一。推荐糙米、燕麦、小米等全谷物。\n\n二、蛋白质补充\n每天摄入适量优质蛋白：一个鸡蛋、一杯牛奶（300ml）、一两瘦肉、一两鱼虾。豆制品也是优质蛋白来源。\n\n三、蔬果摄入\n每天至少摄入300克蔬菜和200克水果，深色蔬菜占一半以上。注意水果不宜过多，尤其是糖尿病患者。\n\n四、钙质补充\n老年人每日钙需求量为1000毫克。除牛奶外，可多食用豆制品、虾皮、芝麻酱等含钙丰富的食物。\n\n五、饮水建议\n每天饮水1500-1700毫升，以白开水和淡茶为主。避免浓茶、咖啡和含糖饮料。\n\n六、饮食原则\n少食多餐，细嚼慢咽；清淡为主，少油少盐；食物多样，搭配合理。'],
      ['4', '适合老年人的运动方式', '运动是最好的养生良药，选择适合自己的运动方式，让身体更健康。', '运动保健',
        '适度运动对老年人健康至关重要，但运动方式的选择需要根据个人身体状况来决定。\n\n一、散步\n散步是最适合老年人的运动方式，每天步行30-60分钟，可分为早晚两次。步速以微微出汗为宜。\n\n二、太极拳\n太极拳动作缓慢柔和，非常适合老年人练习。每周练习3-5次，每次30-45分钟，可改善平衡能力和关节灵活性。\n\n三、八段锦\n八段锦是一套简单易学的传统养生功法，每个动作针对不同脏腑，长期练习可强身健体。\n\n四、游泳\n游泳是对关节压力最小的有氧运动，特别适合关节不好的老年人。每周2-3次，每次30分钟左右。\n\n五、广场舞\n广场舞不仅能锻炼身体，还能增加社交活动。选择节奏舒缓的曲目，避免动作过于激烈。\n\n六、注意事项\n运动前做好热身；运动中如有不适应立即停止；避免空腹运动；运动后注意补充水分；不宜在极端天气下户外运动。'],
      ['5', '老年人心理健康维护', '保持积极乐观的心态，是健康长寿的重要秘诀。关注心理健康，享受幸福晚年。', '心理健康',
        '老年人的心理健康同样重要，良好的心理状态有助于提高生活质量和免疫力。\n\n一、保持社交活跃\n与家人朋友保持经常联系，参加社区活动和兴趣小组。社交能有效预防孤独感和抑郁情绪。\n\n二、培养兴趣爱好\n书法、绘画、园艺、摄影、棋牌等都是很好的选择。兴趣爱好能让生活更加充实，带来成就感和满足感。\n\n三、学会情绪管理\n遇到烦恼时，可通过深呼吸、冥想、散步等方式调节情绪。不要把负面情绪积压在心里。\n\n四、保持学习心态\n活到老学到老，学习新知识新技能可以保持大脑活跃。可以学习使用智能手机、上网浏览资讯等。\n\n五、积极面对衰老\n衰老是自然规律，以平和心态接受身体的变化。关注自己还能做到的事，而不是纠结于做不到的事。\n\n六、寻求专业帮助\n如果持续感到焦虑、抑郁或失眠，应及时寻求心理咨询师或精神科医生的帮助。'],
      ['6', '糖尿病饮食管理指南', '糖尿病患者科学饮食是控制血糖的关键，掌握这些饮食原则，让血糖更稳定。', '慢病管理',
        '糖尿病饮食管理是控制血糖的基础，合理的饮食可以有效减少并发症的发生。\n\n一、控制总热量\n根据体重和活动量确定每日所需热量，一般老年糖尿病患者每日1500-1800千卡即可。\n\n二、主食定量\n每餐主食控制在2两（100克）以内，选择低GI食物如糙米、全麦面包、燕麦等。\n\n三、蛋白质适量\n每天蛋白质摄入约1克/公斤体重。选择鱼、禽、蛋、瘦肉、豆制品等优质蛋白来源。\n\n四、限制脂肪\n减少动物脂肪摄入，烹饪以蒸、煮、炖为主。可用橄榄油代替猪油、黄油。\n\n五、增加膳食纤维\n每天摄入25-30克膳食纤维，多食用绿叶蔬菜、豆类、全谷物等。\n\n六、水果选择\n在血糖控制稳定的前提下，可在两餐之间适量食用低糖水果如苹果、梨、柚子等。'],
      ['7', '春季养肝护肝方法', '春季万物复苏，正是养肝好时节。掌握春季养肝方法，为一年的健康打下基础。', '季节养生',
        '中医认为春季属木，与肝脏相应，春季养肝正当时。\n\n一、调节情志\n春季应保持心情舒畅，避免暴怒和抑郁。肝主疏泄，情志不畅会影响肝的疏泄功能。\n\n二、合理作息\n春季应"夜卧早起"，晚上11点前入睡，早晨6-7点起床。\n\n三、饮食调养\n春季饮食宜清淡，多食用绿色蔬菜如菠菜、芹菜、韭菜等。\n\n四、适度运动\n春季适合户外运动，踏青、散步、放风筝都是不错的选择。\n\n五、茶饮养生\n可饮用菊花茶、枸杞茶、决明子茶等养肝明目的茶饮。\n\n六、防风保暖\n春季风大，老年人外出注意防风。遵循"春捂秋冻"原则。'],
      ['8', '老年人防跌倒指南', '跌倒是老年人意外伤害的首要原因，了解防跌倒知识，保护自己和家人。', '运动保健',
        '跌倒是65岁以上老年人意外伤害的主要原因，预防跌倒至关重要。\n\n一、环境改造\n家中保持通道畅通，移除地面杂物和绊脚物。卫生间安装扶手和防滑垫。\n\n二、穿着合适\n选择合脚防滑的鞋子，避免穿拖鞋或袜子在光滑地面行走。\n\n三、增强体质\n通过适当锻炼增强肌肉力量和平衡能力。\n\n四、合理用药\n某些药物可能引起头晕或嗜睡，服用后应注意休息。\n\n五、定期检查\n每年进行视力和听力检查，必要时配戴眼镜和助听器。\n\n六、紧急应对\n随身携带手机或紧急呼叫装置。'],
      ['9', '夏季防暑降温小贴士', '夏季高温天气对老年人影响较大，掌握防暑降温方法，安全度夏。', '季节养生',
        '夏季高温对老年人健康构成威胁，需做好防暑降温工作。\n\n一、避免高温时段外出\n上午10点至下午4点是一天中最热的时段，应尽量留在室内。\n\n二、充分补水\n每天饮水不少于2000毫升，不要等口渴再喝。\n\n三、清淡饮食\n夏季饮食宜清淡，多食用西瓜、黄瓜、苦瓜等消暑食物。\n\n四、合理使用空调\n室内温度设置在26-28℃为宜，注意定时通风。\n\n五、穿着透气衣物\n选择棉质、亚麻等透气性好的衣物，颜色以浅色为主。\n\n六、注意中暑信号\n如出现头晕、恶心、乏力等症状，应立即转移到阴凉处休息。'],
      ['10', '老年失眠的调理方法', '良好的睡眠是健康的基石，了解失眠原因和调理方法，重获安然好眠。', '心理健康',
        '失眠是老年人常见的健康问题，长期失眠会影响身体健康和生活质量。\n\n一、建立规律作息\n每天固定时间上床和起床，包括周末。\n\n二、创造良好睡眠环境\n卧室保持安静、黑暗和凉爽。\n\n三、睡前放松\n睡前1小时避免使用手机和看电视。\n\n四、饮食调节\n晚餐不宜过饱，睡前3小时避免进食。\n\n五、适度运动\n白天进行适度运动有助于改善夜间睡眠。\n\n六、心理调适\n不要因睡不着而焦虑，焦虑反而会加重失眠。'],
      ['11', '骨质疏松预防与保健', '骨质疏松是老年人的隐形杀手，及早预防，守护骨骼健康。', '慢病管理',
        '骨质疏松是老年人常见疾病，尤其是绝经后女性更易发生。\n\n一、补充钙质\n50岁以上人群每日钙需求量为1000-1200毫克。\n\n二、维生素D\n维生素D促进钙吸收，每天晒太阳15-20分钟即可满足需求。\n\n三、负重运动\n散步、慢跑、跳舞等负重运动有助于增加骨密度。\n\n四、戒烟限酒\n吸烟和过量饮酒都会加速骨质流失。\n\n五、防跌倒\n骨质疏松患者最怕跌倒导致骨折。\n\n六、定期检查\n65岁以上女性和70岁以上男性建议定期进行骨密度检查。'],
      ['12', '秋季润肺养生法', '秋季干燥易伤肺，润肺养肺正当时，学习秋季养生要点。', '季节养生',
        '秋季气候干燥，中医认为秋季与肺相应，润肺养肺是秋季养生的重点。\n\n一、润燥饮食\n多食用梨、百合、银耳、蜂蜜、莲藕等润肺食物。\n\n二、补充水分\n秋季干燥更需补水，每天饮水不少于1700毫升。\n\n三、适度运动\n秋高气爽适合户外运动，登山、慢跑、太极拳都是不错的选择。\n\n四、早睡早起\n秋季应"早卧早起，与鸡俱兴"。\n\n五、情志调养\n秋季万物萧瑟，容易产生悲秋情绪。应保持乐观心态。\n\n六、预防感冒\n秋季昼夜温差大，注意适时增减衣物。'],
      ['13', '心脏保健日常指南', '心脏是人体的发动机，日常保健不可忽视，从生活细节呵护心脏健康。', '慢病管理',
        '心脏健康对老年人尤为重要，良好的生活习惯是心脏保健的基础。\n\n一、健康饮食\n遵循"低盐、低脂、低糖"原则。\n\n二、规律运动\n每周至少150分钟中等强度有氧运动。\n\n三、控制三高\n高血压、高血脂、高血糖是心脏病的主要危险因素。\n\n四、戒烟限酒\n吸烟是冠心病的主要危险因素，必须戒烟。\n\n五、情绪管理\n大怒、大悲等强烈情绪会诱发心脏事件。\n\n六、定期体检\n每年进行心电图、心脏彩超等检查。'],
      ['14', '老年人腰腿痛的缓解方法', '腰腿痛困扰着许多老年人，了解正确的缓解方法，改善生活质量。', '运动保健',
        '腰腿痛是老年人常见的健康问题，多由骨质增生、腰椎间盘突出等引起。\n\n一、正确姿势\n站立时挺胸收腹，坐姿端正，避免长时间保持同一姿势。\n\n二、适度锻炼\n推荐游泳、瑜伽、太极拳等低冲击运动。\n\n三、热敷按摩\n疼痛发作时可用热水袋热敷患处15-20分钟。\n\n四、控制体重\n过重会增加腰椎和膝关节负担。\n\n五、中医调理\n针灸、推拿、拔罐等中医疗法对缓解腰腿痛有良好效果。\n\n六、注意事项\n避免搬抬重物；弯腰时先屈膝；穿舒适的平底鞋。'],
      ['15', '记忆力的保持与提升', '记忆力下降是老年人常见的困扰，通过科学方法可以延缓衰退、提升记忆力。', '心理健康',
        '记忆力下降是衰老的正常表现，但通过科学方法可以延缓衰退。\n\n一、脑力锻炼\n经常进行益智活动如下棋、做数独、学习新技能等。\n\n二、规律运动\n有氧运动可改善大脑血液循环，促进神经细胞生长。\n\n三、充足睡眠\n睡眠是记忆巩固的重要时期。保证每晚7-8小时高质量睡眠。\n\n四、社交互动\n与人交流可以锻炼语言能力和思维反应。\n\n五、营养补充\n适量补充Omega-3脂肪酸、维生素B12、叶酸等。\n\n六、记忆技巧\n使用备忘录、日历提醒等辅助工具。']
    ]
    const articles: KnowledgeArticle[] = []
    for (const item of data) {
      const article: KnowledgeArticle = new KnowledgeArticle()
      article.id = parseInt(item[0])
      article.title = item[1]
      article.summary = item[2]
      article.category = item[3]
      article.content = item[4]
      articles.push(article)
    }
    return articles
  }

  private toggleFavorite(): void {
    if (!this.article) {
      return
    }
    const articleId: number = this.article.id
    const index: number = this.favoriteIds.indexOf(articleId)
    if (index >= 0) {
      this.favoriteIds.splice(index, 1)
      this.isFavorite = false
    } else {
      this.favoriteIds.push(articleId)
      this.isFavorite = true
    }
    this.saveFavorites()
  }

  private saveFavorites(): void {
    const idsStr: string = this.favoriteIds.join(',')
    PreferencesUtil.getInstance().put(Constants.KEY_FAVORITE_IDS, idsStr)
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

        Text('文章详情')
          .fontSize(this.sz(20))
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Text(this.isFavorite ? '★' : '☆')
          .fontSize(this.sz(28))
          .fontColor(this.isFavorite ? '#F59E0B' : '#CCCCCC')
          .padding({ left: 12, right: 12 })
          .accessibilityText(this.isFavorite ? '取消收藏' : '收藏文章')
          .accessibilityLevel('yes')
          .onClick(() => {
            this.toggleFavorite()
          })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor(Color.White)

      if (this.articleLoaded) {
        Scroll() {
          Column() {
            Column() {
              Text(this.article.title)
                .fontSize(this.sz(24))
                .fontWeight(FontWeight.Bold)
                .fontColor('#1A1A1A')
                .width('100%')

              Row() {
                Text(this.article.category)
                  .fontSize(this.sz(13))
                  .fontColor(CATEGORY_COLORS[this.article.category] || '#1A56DB')
                  .backgroundColor((CATEGORY_COLORS[this.article.category] || '#1A56DB') + '15')
                  .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                  .borderRadius(12)

                Blank()

                Text(this.isFavorite ? '已收藏' : '未收藏')
                  .fontSize(this.sz(13))
                  .fontColor(this.isFavorite ? '#F59E0B' : '#999999')
              }
              .width('100%')
              .margin({ top: 12 })
            }
            .width('100%')
            .padding(20)
            .backgroundColor(Color.White)
            .borderRadius(16)

            Column() {
              Text(this.article.content)
                .fontSize(this.sz(16))
                .fontColor('#333333')
                .lineHeight(28)
                .width('100%')
            }
            .width('100%')
            .padding(20)
            .backgroundColor(Color.White)
            .borderRadius(16)
            .margin({ top: 12 })

            Row() {
              Button(this.isFavorite ? '取消收藏' : '收藏文章')
                .width('90%')
                .height(56)
                .fontSize(this.sz(20))
                .fontWeight(FontWeight.Medium)
                .fontColor(this.isFavorite ? '#666666' : Color.White)
                .backgroundColor(this.isFavorite ? '#F0F0F0' : '#1A56DB')
                .borderRadius(28)
                .accessibilityText(this.isFavorite ? '取消收藏此文章' : '收藏此文章')
                .accessibilityLevel('yes')
                .onClick(() => {
                  this.toggleFavorite()
                })
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .padding({ top: 20, bottom: 40 })
          }
          .width('92%')
          .padding({ top: 12 })
        }
        .scrollBar(BarState.Off)
        .layoutWeight(1)
      } else {
        Column() {
          Text('文章加载中...')
            .fontSize(this.sz(18))
            .fontColor('#999999')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
    .alignItems(HorizontalAlign.Center)
  }
}
