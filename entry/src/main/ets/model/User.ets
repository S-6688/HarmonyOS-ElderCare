/**
 * User - 用户模型
 * 存储用户基本信息，age/gender/avatar 当前为预留字段
 * isLogin: 标记用户是否处于登录状态
 */
export class User {
  id: number = 0              // 用户唯一ID（使用时间戳生成）
  name: string = ''           // 用户姓名（如 "张爷爷"）
  age: number = 0             // 年龄（预留字段）
  gender: string = ''         // 性别（预留字段）
  avatar: string = ''         // 头像URL（预留字段）
  isLogin: boolean = false    // 是否已登录

  constructor(id: number, name: string, age: number, gender: string, avatar: string, isLogin: boolean) {
    this.id = id
    this.name = name
    this.age = age
    this.gender = gender
    this.avatar = avatar
    this.isLogin = isLogin
  }
}
