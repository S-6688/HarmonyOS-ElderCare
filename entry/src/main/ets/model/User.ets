export class User {
  id: number = 0
  name: string = ''
  age: number = 0
  gender: string = ''
  avatar: string = ''
  isLogin: boolean = false

  constructor(id: number, name: string, age: number, gender: string, avatar: string, isLogin: boolean) {
    this.id = id
    this.name = name
    this.age = age
    this.gender = gender
    this.avatar = avatar
    this.isLogin = isLogin
  }
}
