/**
 * 打飞机游戏页面
 * 使用鼠标/触摸控制飞机移动，自动发射子弹，击落敌机得分
 */

import router from '@ohos.router'

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

// 游戏配置常量（基于设计尺寸360x640，会根据屏幕动态缩放）
const DESIGN_WIDTH: number = 360
const DESIGN_HEIGHT: number = 640
const PLAYER_SIZE: number = 50
const BULLET_WIDTH: number = 6
const BULLET_HEIGHT: number = 15
const ENEMY_SIZE: number = 40
const BULLET_SPEED: number = 8
const ENEMY_SPEED_EASY: number = 2
const ENEMY_SPEED_NORMAL: number = 3
const ENEMY_SPEED_HARD: number = 5
const ENEMY_SPAWN_INTERVAL_EASY: number = 1500
const ENEMY_SPAWN_INTERVAL_NORMAL: number = 1000
const ENEMY_SPAWN_INTERVAL_HARD: number = 600
const BULLET_SPAWN_INTERVAL: number = 200 // 子弹发射间隔（毫秒）

// 子弹数据模型
class Bullet {
  x: number = 0
  y: number = 0
  id: number = 0

  constructor(x: number, y: number, id: number) {
    this.x = x
    this.y = y
    this.id = id
  }
}

// 敌机数据模型
class Enemy {
  x: number = 0
  y: number = 0
  id: number = 0
  isElite: boolean = false // 是否为精英敌机
  hp: number = 1 // 生命值

  constructor(x: number, y: number, id: number, isElite: boolean = false) {
    this.x = x
    this.y = y
    this.id = id
    this.isElite = isElite
    this.hp = isElite ? 3 : 1 // 精英敌机需要3颗子弹
  }
}

@Entry
@Component
struct GamePage {
  // 屏幕适配相关
  @State gameWidth: number = DESIGN_WIDTH
  @State gameHeight: number = DESIGN_HEIGHT
  @State scaleRatio: number = 1

  // 玩家飞机位置
  @State playerX: number = DESIGN_WIDTH / 2 - PLAYER_SIZE / 2
  @State playerY: number = DESIGN_HEIGHT - PLAYER_SIZE - 20

  // 子弹列表
  @State bullets: Bullet[] = []
  @State bulletId: number = 0

  // 敌机列表
  @State enemies: Enemy[] = []
  @State enemyId: number = 0

  // 游戏状态
  @State score: number = 0
  @State isGameOver: boolean = false
  @State isGamePaused: boolean = false
  @State showPauseMenu: boolean = false

  // 战败线位置（玩家飞机后方）
  @State defeatLineY: number = 0

  // 精英敌机计数器（用于间隔控制）
  private eliteEnemyCounter: number = 0

  // 难度设置
  @State difficulty: number = 1 // 1:简单 2:普通 3:困难
  private enemySpeed: number = ENEMY_SPEED_NORMAL
  private enemySpawnInterval: number = ENEMY_SPAWN_INTERVAL_NORMAL

  // 定时器ID
  private enemySpawnTimer: number = -1
  private bulletSpawnTimer: number = -1
  private gameLoopTimer: number = -1

  aboutToAppear() {
    // 获取屏幕尺寸并计算缩放比例
    this.initScreenSize()
    // 获取难度参数
    this.loadDifficulty()
    this.startGame()
  }

  // 加载难度设置
  loadDifficulty() {
    try {
      const params = router.getParams() as Record<string, number>
      if (params && params['difficulty']) {
        this.difficulty = params['difficulty']
      }
      // 根据难度设置敌机速度和生成间隔
      switch (this.difficulty) {
        case 1: // 简单
          this.enemySpeed = ENEMY_SPEED_EASY
          this.enemySpawnInterval = ENEMY_SPAWN_INTERVAL_EASY
          break
        case 2: // 普通
          this.enemySpeed = ENEMY_SPEED_NORMAL
          this.enemySpawnInterval = ENEMY_SPAWN_INTERVAL_NORMAL
          break
        case 3: // 困难
          this.enemySpeed = ENEMY_SPEED_HARD
          this.enemySpawnInterval = ENEMY_SPAWN_INTERVAL_HARD
          break
        default:
          this.enemySpeed = ENEMY_SPEED_NORMAL
          this.enemySpawnInterval = ENEMY_SPAWN_INTERVAL_NORMAL
      }
    } catch (e) {
      console.warn('Failed to load difficulty, using default')
    }
  }
  // 初始化屏幕尺寸
  initScreenSize() {
    try {
      // 获取设备屏幕宽度（使用系统API）
      const screenWidth: number = 360  // 默认值，实际项目中应使用系统API
      const screenHeight: number = 640  // 默认值，实际项目中应使用系统API

      // 计算缩放比例，保持设计比例
      const widthScale: number = screenWidth / DESIGN_WIDTH
      const heightScale: number = screenHeight / DESIGN_HEIGHT
      this.scaleRatio = Math.min(widthScale, heightScale)

      // 设置实际游戏区域大小
      this.gameWidth = Math.floor(DESIGN_WIDTH * this.scaleRatio)
      this.gameHeight = Math.floor(DESIGN_HEIGHT * this.scaleRatio)

      // 重新计算玩家初始位置
      this.playerX = this.gameWidth / 2 - PLAYER_SIZE * this.scaleRatio / 2
      this.playerY = this.gameHeight - PLAYER_SIZE * this.scaleRatio - 20 * this.scaleRatio
    } catch (e) {
      // 如果获取屏幕尺寸失败，使用默认值
      console.warn('Failed to get screen size, using default values')
    }
  }

  aboutToDisappear() {
    this.stopGame()
  }

  // 开始游戏
  startGame() {
    this.isGameOver = false
    this.isGamePaused = false
    this.score = 0
    this.bullets = []
    this.enemies = []
    this.bulletId = 0
    this.enemyId = 0
    this.eliteEnemyCounter = 0 // 重置精英敌机计数器
    this.playerX = this.gameWidth / 2 - PLAYER_SIZE * this.scaleRatio / 2

    // 设置战败线位置（玩家飞机后方50像素）
    this.defeatLineY = this.playerY + PLAYER_SIZE * this.scaleRatio + 50 * this.scaleRatio

    // 启动敌机生成定时器
    this.enemySpawnTimer = setInterval(() => {
      if (!this.isGameOver && !this.isGamePaused) {
        this.spawnEnemy()
      }
    }, this.enemySpawnInterval)

    // 启动子弹发射定时器
    this.bulletSpawnTimer = setInterval(() => {
      if (!this.isGameOver && !this.isGamePaused) {
        this.spawnBullet()
      }
    }, BULLET_SPAWN_INTERVAL)

    // 启动游戏循环
    this.gameLoopTimer = setInterval(() => {
      if (!this.isGameOver && !this.isGamePaused) {
        this.gameLoop()
      }
    }, 16) // 约60FPS
  }

  // 停止游戏
  stopGame() {
    if (this.enemySpawnTimer !== -1) {
      clearInterval(this.enemySpawnTimer)
    }
    if (this.bulletSpawnTimer !== -1) {
      clearInterval(this.bulletSpawnTimer)
    }
    if (this.gameLoopTimer !== -1) {
      clearInterval(this.gameLoopTimer)
    }
  }

  // 生成敌机
  spawnEnemy() {
    const scaledEnemySize = ENEMY_SIZE * this.scaleRatio
    const x = Math.random() * (this.gameWidth - scaledEnemySize)
    this.enemyId++

    // 精英敌机生成逻辑：至少间隔5架普通敌机
    let isElite = false
    if (this.eliteEnemyCounter >= 5) {
      // 15%概率生成精英敌机
      isElite = Math.random() < 0.15
      if (isElite) {
        this.eliteEnemyCounter = 0 // 重置计数器
      }
    }

    // 如果不是精英敌机，增加计数器
    if (!isElite) {
      this.eliteEnemyCounter++
    }

    // 使用数组展开运算符创建新数组以触发UI更新
    this.enemies = [...this.enemies, new Enemy(x, -scaledEnemySize, this.enemyId, isElite)]
  }

  // 生成子弹
  spawnBullet() {
    const scaledPlayerSize = PLAYER_SIZE * this.scaleRatio
    const scaledBulletWidth = BULLET_WIDTH * this.scaleRatio
    const scaledBulletHeight = BULLET_HEIGHT * this.scaleRatio
    const x = this.playerX + scaledPlayerSize / 2 - scaledBulletWidth / 2
    const y = this.playerY - scaledBulletHeight
    this.bulletId++
    // 使用数组展开运算符创建新数组以触发UI更新
    this.bullets = [...this.bullets, new Bullet(x, y, this.bulletId)]
  }

  // 游戏主循环
  gameLoop() {
    const scaledBulletHeight = BULLET_HEIGHT * this.scaleRatio
    const scaledEnemySize = ENEMY_SIZE * this.scaleRatio

    // 更新子弹位置 - 每次生成新id以强制UI更新
    this.bullets = this.bullets
      .map(bullet => {
        this.bulletId++
        return new Bullet(bullet.x, bullet.y - BULLET_SPEED * this.scaleRatio, this.bulletId)
      })
      .filter(bullet => bullet.y > -scaledBulletHeight)

    // 更新敌机位置 - 每次生成新id以强制UI更新
    this.enemies = this.enemies
      .map(enemy => {
        this.enemyId++
        const newEnemy = new Enemy(enemy.x, enemy.y + this.enemySpeed * this.scaleRatio, this.enemyId, enemy.isElite)
        newEnemy.hp = enemy.hp
        return newEnemy
      })
      .filter(enemy => enemy.y < this.gameHeight + scaledEnemySize)

    // 碰撞检测
    this.checkCollisions()

    // 检查战败线
    this.checkDefeatLine()
  }

  // 碰撞检测
  checkCollisions() {
    const scaledBulletWidth = BULLET_WIDTH * this.scaleRatio
    const scaledBulletHeight = BULLET_HEIGHT * this.scaleRatio
    const scaledPlayerSize = PLAYER_SIZE * this.scaleRatio

    // 子弹与敌机碰撞
    const bulletsToRemove: Set<number> = new Set()
    const enemiesToRemove: Set<number> = new Set()

    for (const bullet of this.bullets) {
      for (const enemy of this.enemies) {
        const scaledEnemySize = (enemy.isElite ? ENEMY_SIZE * 1.5 : ENEMY_SIZE) * this.scaleRatio

        if (this.isColliding(bullet.x, bullet.y, scaledBulletWidth, scaledBulletHeight,
          enemy.x, enemy.y, scaledEnemySize, scaledEnemySize)) {
          bulletsToRemove.add(bullet.id)

          // 减少敌机生命值
          enemy.hp--

          // 如果敌机生命值为0，则移除
          if (enemy.hp <= 0) {
            enemiesToRemove.add(enemy.id)
            // 精英敌机得分更高
            this.score += enemy.isElite ? 40 : 10
          }
        }
      }
    }

    this.bullets = this.bullets.filter(b => !bulletsToRemove.has(b.id))
    this.enemies = this.enemies.filter(e => !enemiesToRemove.has(e.id))

    // 玩家与敌机碰撞
    for (const enemy of this.enemies) {
      const scaledEnemySize = (enemy.isElite ? ENEMY_SIZE * 1.5 : ENEMY_SIZE) * this.scaleRatio

      if (this.isColliding(this.playerX, this.playerY, scaledPlayerSize, scaledPlayerSize,
        enemy.x, enemy.y, scaledEnemySize, scaledEnemySize)) {
        this.gameOver()
        break
      }
    }
  }

  // 检查战败线
  checkDefeatLine() {
    // 检查是否有敌机越过战败线
    for (const enemy of this.enemies) {
      const scaledEnemySize = (enemy.isElite ? ENEMY_SIZE * 1.5 : ENEMY_SIZE) * this.scaleRatio

      if (enemy.y + scaledEnemySize > this.defeatLineY) {
        this.gameOver()
        break
      }
    }
  }

  // 矩形碰撞检测
  isColliding(x1: number, y1: number, w1: number, h1: number,
    x2: number, y2: number, w2: number, h2: number): boolean {
    return x1 < x2 + w2 && x1 + w1 > x2 && y1 < y2 + h2 && y1 + h1 > y2
  }

  // 游戏结束
  gameOver() {
    this.isGameOver = true
    this.stopGame()
    // 保存分数到排行榜
    this.saveScore()
  }

  // 保存分数
  saveScore() {
    // 更新排行榜
    HighScoreManager.updateHighScores(this.score)
    console.info(`Game Over! Final Score: ${this.score}`)
  }

  // 重新开始
  restartGame() {
    this.stopGame()
    this.startGame()
  }

  // 暂停游戏
  pauseGame() {
    this.isGamePaused = true
    this.showPauseMenu = true
  }

  // 继续游戏
  resumeGame() {
    this.isGamePaused = false
    this.showPauseMenu = false
  }

  // 返回首页
  goToHome() {
    this.stopGame()
    router.back()
  }

  // 获取难度名称
  getDifficultyName(): string {
    switch (this.difficulty) {
      case 1: return '简单'
      case 2: return '普通'
      case 3: return '困难'
      default: return '普通'
    }
  }

  // 鼠标移动处理
  onMouseMove(event: MouseEvent) {
    if (this.isGameOver) return

    const scaledPlayerSize = PLAYER_SIZE * this.scaleRatio
    // 限制飞机在游戏区域内
    let newX = event.x - scaledPlayerSize / 2
    newX = Math.max(0, Math.min(this.gameWidth - scaledPlayerSize, newX))
    this.playerX = newX
  }

  // 触摸移动处理（支持手机端）
  onTouchMove(event: TouchEvent) {
    if (this.isGameOver) return

    const scaledPlayerSize = PLAYER_SIZE * this.scaleRatio
    // 限制飞机在游戏区域内
    let newX = event.touches[0].x - scaledPlayerSize / 2
    newX = Math.max(0, Math.min(this.gameWidth - scaledPlayerSize, newX))
    this.playerX = newX
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      // 游戏背景
      Column() {
      }
      .width(this.gameWidth)
      .height(this.gameHeight)
      .backgroundColor('#1a1a2e')
      .border({ width: 2, color: '#4a4a6a' })

      // 玩家飞机
      Row() {
        Text('✈')
          .fontSize(PLAYER_SIZE * this.scaleRatio * 0.8)
          .fontColor('#00d4ff')
          .textShadow({ radius: 8, color: '#00d4ff', offsetX: 0, offsetY: 0 })
      }
      .width(PLAYER_SIZE * this.scaleRatio)
      .height(PLAYER_SIZE * this.scaleRatio)
      .position({ x: this.playerX, y: this.playerY })
      .justifyContent(FlexAlign.Center)

      // 子弹
      ForEach(this.bullets, (bullet: Bullet) => {
        Row() {
        }
        .width(BULLET_WIDTH * this.scaleRatio)
        .height(BULLET_HEIGHT * this.scaleRatio)
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: [['#ffff00', 0], ['#ff8800', 1]]
        })
        .borderRadius(3)
        .shadow({ radius: 5, color: '#ffff00', offsetX: 0, offsetY: 0 })
        .position({ x: bullet.x, y: bullet.y })
      }, (bullet: Bullet) => bullet.id.toString())

      // 敌机
      ForEach(this.enemies, (enemy: Enemy) => {
        Row() {
          Text('✈')
            .fontSize((enemy.isElite ? ENEMY_SIZE * 1.5 : ENEMY_SIZE) * this.scaleRatio * 0.7) // 精英敌机大1.5倍
            .fontColor(enemy.isElite ? '#9b59b6' : '#ff4757') // 精英敌机为紫色
            .rotate({ angle: 180 })
            .textShadow({ radius: 8, color: enemy.isElite ? '#9b59b6' : '#ff4757', offsetX: 0, offsetY: 0 })
        }
        .width((enemy.isElite ? ENEMY_SIZE * 1.5 : ENEMY_SIZE) * this.scaleRatio)
        .height((enemy.isElite ? ENEMY_SIZE * 1.5 : ENEMY_SIZE) * this.scaleRatio)
        .position({ x: enemy.x, y: enemy.y })
        .justifyContent(FlexAlign.Center)
      }, (enemy: Enemy) => enemy.id.toString())

      // 战败线
      Row() {
        Row()
          .width(this.gameWidth)
          .height(3)
          .linearGradient({
            direction: GradientDirection.Right,
            colors: [['#ff0000', 0], ['#ff6600', 0.5], ['#ff0000', 1]]
          })
      }
      .position({ x: 0, y: this.defeatLineY })
      .justifyContent(FlexAlign.Center)

      // 顶部信息栏
      Column() {
        Row() {
          Text(`分数: ${this.score}`)
            .fontSize(20 * this.scaleRatio)
            .fontColor('#ffffff')
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)

          Text(`难度: ${this.getDifficultyName()}`)
            .fontSize(16 * this.scaleRatio)
            .fontColor('#fbbf24')
            .margin({ right: 15 * this.scaleRatio })

          // 暂停按钮
          Button() {
            Text('⏸')
              .fontSize(20 * this.scaleRatio)
              .fontColor('#ffffff')
          }
          .width(40 * this.scaleRatio)
          .height(40 * this.scaleRatio)
          .backgroundColor('rgba(255, 255, 255, 0.2)')
          .borderRadius(20 * this.scaleRatio)
          .onClick(() => {
            this.pauseGame()
          })
        }
        .width('100%')
        .padding(10 * this.scaleRatio)
      }
      .width(this.gameWidth)

      // 暂停菜单
      if (this.showPauseMenu && !this.isGameOver) {
        Column() {
          Column() {
            Text('游戏暂停')
              .fontSize(32 * this.scaleRatio)
              .fontColor('#00d4ff')
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 30 * this.scaleRatio })

            Button('继续游戏')
              .width(180 * this.scaleRatio)
              .height(50 * this.scaleRatio)
              .fontSize(20 * this.scaleRatio)
              .fontWeight(FontWeight.Bold)
              .backgroundColor('#4ade80')
              .borderRadius(25 * this.scaleRatio)
              .margin({ bottom: 15 * this.scaleRatio })
              .onClick(() => {
                this.resumeGame()
              })

            Button('重新开始')
              .width(180 * this.scaleRatio)
              .height(50 * this.scaleRatio)
              .fontSize(20 * this.scaleRatio)
              .fontWeight(FontWeight.Bold)
              .backgroundColor('#fbbf24')
              .borderRadius(25 * this.scaleRatio)
              .margin({ bottom: 15 * this.scaleRatio })
              .onClick(() => {
                this.showPauseMenu = false
                this.restartGame()
              })

            Button('返回首页')
              .width(180 * this.scaleRatio)
              .height(50 * this.scaleRatio)
              .fontSize(20 * this.scaleRatio)
              .fontWeight(FontWeight.Bold)
              .backgroundColor('#ef4444')
              .borderRadius(25 * this.scaleRatio)
              .onClick(() => {
                this.goToHome()
              })
          }
          .padding(30 * this.scaleRatio)
          .backgroundColor('#2a2a4a')
          .borderRadius(20 * this.scaleRatio)
          .border({ width: 2, color: '#00d4ff' })
          .shadow({ radius: 30, color: 'rgba(0, 0, 0, 0.5)', offsetX: 0, offsetY: 10 })
        }
        .width(this.gameWidth)
        .height(this.gameHeight)
        .backgroundColor('rgba(0, 0, 0, 0.7)')
        .justifyContent(FlexAlign.Center)
      }

      // 游戏结束界面
      if (this.isGameOver) {
        Column() {
          Column() {
            Text('游戏结束')
              .fontSize(36 * this.scaleRatio)
              .fontColor('#ff4757')
              .fontWeight(FontWeight.Bold)
              .textShadow({ radius: 10, color: '#ff4757', offsetX: 0, offsetY: 0 })
              .margin({ bottom: 20 * this.scaleRatio })

            Text(`最终分数: ${this.score}`)
              .fontSize(24 * this.scaleRatio)
              .fontColor('#ffffff')
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 10 * this.scaleRatio })

            Text(`难度: ${this.getDifficultyName()}`)
              .fontSize(18 * this.scaleRatio)
              .fontColor('#fbbf24')
              .margin({ bottom: 30 * this.scaleRatio })

            Button('重新开始')
              .width(180 * this.scaleRatio)
              .height(50 * this.scaleRatio)
              .fontSize(20 * this.scaleRatio)
              .fontWeight(FontWeight.Bold)
              .backgroundColor('#00d4ff')
              .borderRadius(25 * this.scaleRatio)
              .margin({ bottom: 15 * this.scaleRatio })
              .onClick(() => {
                this.restartGame()
              })

            Button('返回首页')
              .width(180 * this.scaleRatio)
              .height(50 * this.scaleRatio)
              .fontSize(20 * this.scaleRatio)
              .fontWeight(FontWeight.Bold)
              .backgroundColor('#6c5ce7')
              .borderRadius(25 * this.scaleRatio)
              .onClick(() => {
                this.goToHome()
              })
          }
          .padding(30 * this.scaleRatio)
          .backgroundColor('#2a2a4a')
          .borderRadius(20 * this.scaleRatio)
          .border({ width: 2, color: '#ff4757' })
          .shadow({ radius: 30, color: 'rgba(0, 0, 0, 0.5)', offsetX: 0, offsetY: 10 })
        }
        .width(this.gameWidth)
        .height(this.gameHeight)
        .backgroundColor('rgba(0, 0, 0, 0.7)')
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0f0f1a')
    .alignContent(Alignment.Center)
    .onMouse((event: MouseEvent) => {
      if (event.action === MouseAction.Move) {
        this.onMouseMove(event)
      }
    })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Move || event.type === TouchType.Down) {
        this.onTouchMove(event)
      }
    })
  }
}
