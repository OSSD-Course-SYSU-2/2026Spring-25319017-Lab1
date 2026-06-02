import router from '@ohos.router'
import { DeviceAdapter, DeviceType, DeviceConfig } from '../common/DeviceAdapter'

// 最高分数据模型
class HighScore {
  score: number = 0

  constructor(score: number) {
    this.score = score
  }
}

// 排行榜管理类
class HighScoreManager {
  private static KEY: string = 'plane_game_high_scores'
  // 获取排行榜
  static getHighScores(): HighScore[] {
    // 从AppStorage获取
    const stored = AppStorage.Get<string>(HighScoreManager.KEY)
    if (stored) {
      try {
        const parsed: number[] = JSON.parse(stored)
        return parsed.map((s: number) => new HighScore(s))
      } catch (e) {
        console.error('Failed to parse high scores')
      }
    }
    // 初始化为空排行榜
    return [
      new HighScore(0),
      new HighScore(0),
      new HighScore(0),
      new HighScore(0),
      new HighScore(0)
    ]
  }
  // 更新排行榜
  static updateHighScores(newScore: number): HighScore[] {
    const scores = HighScoreManager.getHighScores()

    // 添加新分数
    scores.push(new HighScore(newScore))

    // 按分数降序排序
    scores.sort((a: HighScore, b: HighScore) => b.score - a.score)

    // 只保留前5名
    const top5 = scores.slice(0, 5)

    // 保存到AppStorage
    const scoresArray = top5.map((s: HighScore) => s.score)
    AppStorage.SetOrCreate<string>(HighScoreManager.KEY, JSON.stringify(scoresArray))

    return top5
  }
}

@Entry
@Component
struct Index {
  @State message: string = '打飞机游戏';
  @State difficulty: number = 1 // 1:简单 2:普通 3:困难
  @State showHighScores: boolean = false
  @StorageLink('plane_game_high_scores') @Watch('onHighScoresChange') highScoresData: string = '[]'
  @State highScores: HighScore[] = []
  @State deviceConfig: DeviceConfig = DeviceAdapter.getDeviceConfig()

  aboutToAppear() {
    this.deviceConfig = DeviceAdapter.getDeviceConfig()
    this.loadHighScores()
  }

  // 监听排行榜数据变化
  onHighScoresChange() {
    this.loadHighScores()
  }

  // 加载最高分记录
  loadHighScores() {
    this.highScores = HighScoreManager.getHighScores()
  }

  // 获取难度名称
  getDifficultyName(level: number): string {
    switch (level) {
      case 1: return '简单'
      case 2: return '普通'
      case 3: return '困难'
      default: return '普通'
    }
  }

  // 获取难度颜色
  getDifficultyColor(level: number): string {
    switch (level) {
      case 1: return '#4ade80' // 绿色
      case 2: return '#fbbf24' // 黄色
      case 3: return '#ef4444' // 红色
      default: return '#fbbf24'
    }
  }

  build() {
    Stack() {
      Column() {
        // 标题
        Column() {
          Text(this.message)
            .fontSize(48 * this.deviceConfig.fontSizeScale)
            .fontWeight(FontWeight.Bold)
            .fontColor('#00d4ff')
            .textShadow({ radius: 10, color: '#00d4ff', offsetX: 0, offsetY: 0 })

          // 手表设备隐藏副标题
          if (this.deviceConfig.deviceType !== DeviceType.WATCH) {
            Text('PLANE SHOOTER')
              .fontSize(16 * this.deviceConfig.fontSizeScale)
              .fontColor('#4a90e2')
              .letterSpacing(8)
              .margin({ top: 5 })
          }
        }
        .margin({ bottom: 30 * this.deviceConfig.scaleRatio })

        // 游戏图标
        Column() {
          Text('✈')
            .fontSize(120 * this.deviceConfig.scaleRatio)
            .fontColor('#ff4757')
            .rotate({ angle: 180 })
            .textShadow({ radius: 20, color: '#ff4757', offsetX: 0, offsetY: 0 })
        }
        .margin({ bottom: 40 * this.deviceConfig.scaleRatio })

        // 难度选择 - 手表设备简化显示
        if (this.deviceConfig.deviceType !== DeviceType.WATCH) {
          Column() {
            Text('游戏难度')
              .fontSize(18 * this.deviceConfig.fontSizeScale)
              .fontColor('#ffffff')
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 15 })

            Row() {
              ForEach([1, 2, 3], (level: number) => {
                Button(this.getDifficultyName(level))
                  .width(80 * this.deviceConfig.scaleRatio)
                  .height(40 * this.deviceConfig.scaleRatio)
                  .fontSize(16 * this.deviceConfig.fontSizeScale)
                  .fontWeight(FontWeight.Bold)
                  .backgroundColor(this.difficulty === level ? this.getDifficultyColor(level) : '#3a3a5a')
                  .borderRadius(20)
                  .border({ width: 2, color: this.difficulty === level ? this.getDifficultyColor(level) : '#5a5a7a' })
                  .onClick(() => {
                    this.difficulty = level
                  })
                  .margin({ left: 5, right: 5 })
              })
            }
            .margin({ bottom: 10 })

            Text(`当前难度: ${this.getDifficultyName(this.difficulty)}`)
              .fontSize(14 * this.deviceConfig.fontSizeScale)
              .fontColor(this.getDifficultyColor(this.difficulty))
          }
          .margin({ bottom: 30 * this.deviceConfig.scaleRatio })
        }

        // 开始游戏按钮
        Button('开始游戏')
          .width(220 * this.deviceConfig.scaleRatio)
          .height(65 * this.deviceConfig.scaleRatio)
          .fontSize(26 * this.deviceConfig.fontSizeScale)
          .fontWeight(FontWeight.Bold)
          .backgroundColor('#00d4ff')
          .borderRadius(32)
          .shadow({ radius: 15, color: '#00d4ff', offsetX: 0, offsetY: 5 })
          .onClick(() => {
            router.pushUrl({
              url: 'pages/GamePage',
              params: {
                difficulty: this.difficulty
              }
            })
          })
          .margin({ bottom: 15 * this.deviceConfig.scaleRatio })

        // 查看最高分按钮 - 手表设备隐藏
        if (this.deviceConfig.deviceType !== DeviceType.WATCH) {
          Button('排行榜')
            .width(220 * this.deviceConfig.scaleRatio)
            .height(50 * this.deviceConfig.scaleRatio)
            .fontSize(20 * this.deviceConfig.fontSizeScale)
            .fontWeight(FontWeight.Bold)
            .backgroundColor('#6c5ce7')
            .borderRadius(25)
            .onClick(() => {
              this.showHighScores = true
            })
            .margin({ bottom: 30 * this.deviceConfig.scaleRatio })
        }

        // 游戏说明 - 手表设备隐藏
        if (this.deviceConfig.deviceType !== DeviceType.WATCH) {
          Column() {
            Text('游戏说明')
              .fontSize(20 * this.deviceConfig.fontSizeScale)
              .fontColor('#ffffff')
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 15 })

            Column() {
              Row() {
                Text('✦')
                  .fontSize(16 * this.deviceConfig.fontSizeScale)
                  .fontColor('#00d4ff')
                  .margin({ right: 8 })
                Text('移动鼠标控制飞机')
                  .fontSize(16 * this.deviceConfig.fontSizeScale)
                  .fontColor('#aaaaaa')
              }
              .margin({ bottom: 8 })

              Row() {
                Text('✦')
                  .fontSize(16 * this.deviceConfig.fontSizeScale)
                  .fontColor('#00d4ff')
                  .margin({ right: 8 })
                Text('自动发射子弹')
                  .fontSize(16 * this.deviceConfig.fontSizeScale)
                  .fontColor('#aaaaaa')
              }
              .margin({ bottom: 8 })

              Row() {
                Text('✦')
                  .fontSize(16 * this.deviceConfig.fontSizeScale)
                  .fontColor('#00d4ff')
                  .margin({ right: 8 })
                Text('击落敌机得分')
                  .fontSize(16 * this.deviceConfig.fontSizeScale)
                  .fontColor('#aaaaaa')
              }
              .margin({ bottom: 8 })

              Row() {
                Text('✦')
                  .fontSize(16 * this.deviceConfig.fontSizeScale)
                  .fontColor('#00d4ff')
                  .margin({ right: 8 })
                Text('避免被敌机撞到')
                  .fontSize(16 * this.deviceConfig.fontSizeScale)
                  .fontColor('#aaaaaa')
              }
            }
          }
          .padding(20)
          .backgroundColor('rgba(255, 255, 255, 0.05)')
          .borderRadius(15)
          .border({ width: 1, color: 'rgba(255, 255, 255, 0.1)' })
        }
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)

      // 最高分排行榜弹窗
      if (this.showHighScores) {
        Column() {
          Column() {
            Text('🏆 排行榜')
              .fontSize(28)
              .fontColor('#ffd700')
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 25 })

            ForEach(this.highScores, (item: HighScore, index: number) => {
              Row() {
                Text(`${index + 1}`)
                  .fontSize(20)
                  .fontColor('#ffffff')
                  .fontWeight(FontWeight.Bold)
                  .width(30)

                Text(index === 0 ? '🥇' : index === 1 ? '🥈' : index === 2 ? '🥉' : '  ')
                  .fontSize(20)
                  .width(30)

                Text(`${item.score} 分`)
                  .fontSize(20)
                  .fontColor(item.score > 0 ? '#00d4ff' : '#666666')
                  .fontWeight(FontWeight.Bold)
                  .layoutWeight(1)
              }
              .width('100%')
              .padding({ top: 10, bottom: 10 })
              .border({ width: { bottom: 1 }, color: 'rgba(255, 255, 255, 0.1)' })
            })

            Button('关闭')
              .width(150)
              .height(45)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .backgroundColor('#6c5ce7')
              .borderRadius(22)
              .margin({ top: 25 })
              .onClick(() => {
                this.showHighScores = false
              })
          }
          .width(300)
          .padding(25)
          .backgroundColor('#2a2a4a')
          .borderRadius(20)
          .border({ width: 2, color: '#6c5ce7' })
          .shadow({ radius: 30, color: 'rgba(0, 0, 0, 0.5)', offsetX: 0, offsetY: 10 })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.7)')
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#1a1a2e')
  }
}