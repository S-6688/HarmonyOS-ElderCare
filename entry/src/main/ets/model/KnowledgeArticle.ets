/**
 * KnowledgeArticle - 养生知识文章模型
 * 包含文章的基本信息和收藏状态
 * coverIcon: 使用汉字作为分类图标（食/动/心/病/季），无需图片资源
 */
export class KnowledgeArticle {
  id: number = 0              // 文章唯一ID
  title: string = ''          // 文章标题
  summary: string = ''        // 文章摘要（列表页展示）
  category: string = ''       // 分类（饮食养生/运动保健/心理健康/慢病管理/季节养生）
  content: string = ''        // 文章正文（详情页展示）
  coverIcon: string = ''      // 封面图标汉字（食/动/心/病/季）
  isFavorite: boolean = false // 是否已收藏
}
