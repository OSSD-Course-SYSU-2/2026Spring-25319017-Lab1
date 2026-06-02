/**
 * 设备适配工具类
 * 用于检测设备类型、屏幕尺寸，并提供多端适配能力
 */

// 设备类型枚举
export enum DeviceType {
  PHONE = 'phone',
  TABLET = 'tablet',
  WATCH = 'watch',
  TV = 'tv',
  CAR = 'car',
  UNKNOWN = 'unknown'
}

// 设备配置接口
export interface DeviceConfig {
  deviceType: DeviceType
  screenWidth: number
  screenHeight: number
  scaleRatio: number
  isSmallScreen: boolean
  fontSizeScale: number
}

// 游戏尺寸接口
export interface GameSize {
  width: number
  height: number
}

// 设备适配管理类
export class DeviceAdapter {
  // 设计基准尺寸
  private static readonly DESIGN_WIDTH_PHONE: number = 360
  private static readonly DESIGN_HEIGHT_PHONE: number = 640
  private static readonly DESIGN_WIDTH_TABLET: number = 720
  private static readonly DESIGN_HEIGHT_TABLET: number = 1024
  private static readonly DESIGN_WIDTH_WATCH: number = 200
  private static readonly DESIGN_HEIGHT_WATCH: number = 200
  private static readonly DESIGN_WIDTH_TV: number = 1280
  private static readonly DESIGN_HEIGHT_TV: number = 720
  private static readonly DESIGN_WIDTH_CAR: number = 800
  private static readonly DESIGN_HEIGHT_CAR: number = 480

  // 获取设备类型
  static getDeviceType(): DeviceType {
    try {
      // 通过屏幕尺寸判断设备类型
      const screenWidth = DeviceAdapter.getScreenWidth()
      const screenHeight = DeviceAdapter.getScreenHeight()
      const minSize = Math.min(screenWidth, screenHeight)
      const maxSize = Math.max(screenWidth, screenHeight)

      // 手表设备：小屏幕，通常小于300px
      if (maxSize < 350) {
        return DeviceType.WATCH
      }
      // 电视设备：超大屏幕，通常宽度大于1200px
      else if (minSize >= 1200) {
        return DeviceType.TV
      }
      // 车载设备：中等偏大屏幕，通常宽度在700-1200px之间
      else if (minSize >= 700 && minSize < 1200) {
        return DeviceType.CAR
      }
      // 平板设备：大屏幕，通常宽度大于600px
      else if (minSize >= 600) {
        return DeviceType.TABLET
      }
      // 手机设备：中等屏幕
      else {
        return DeviceType.PHONE
      }
    } catch (e) {
      console.error('Failed to get device type')
      return DeviceType.PHONE
    }
  }

  // 获取屏幕宽度（实际项目中应使用系统API）
  static getScreenWidth(): number {
    // 这里返回默认值，实际应使用 display API
    return 360
  }

  // 获取屏幕高度（实际项目中应使用系统API）
  static getScreenHeight(): number {
    // 这里返回默认值，实际应使用 display API
    return 640
  }

  // 获取设备配置
  static getDeviceConfig(): DeviceConfig {
    const deviceType = DeviceAdapter.getDeviceType()
    const screenWidth = DeviceAdapter.getScreenWidth()
    const screenHeight = DeviceAdapter.getScreenHeight()

    let designWidth: number
    let designHeight: number
    let fontSizeScale: number = 1

    switch (deviceType) {
      case DeviceType.TABLET:
        designWidth = DeviceAdapter.DESIGN_WIDTH_TABLET
        designHeight = DeviceAdapter.DESIGN_HEIGHT_TABLET
        fontSizeScale = 1.3
        break
      case DeviceType.WATCH:
        designWidth = DeviceAdapter.DESIGN_WIDTH_WATCH
        designHeight = DeviceAdapter.DESIGN_HEIGHT_WATCH
        fontSizeScale = 0.7
        break
      case DeviceType.TV:
        designWidth = DeviceAdapter.DESIGN_WIDTH_TV
        designHeight = DeviceAdapter.DESIGN_HEIGHT_TV
        fontSizeScale = 1.5
        break
      case DeviceType.CAR:
        designWidth = DeviceAdapter.DESIGN_WIDTH_CAR
        designHeight = DeviceAdapter.DESIGN_HEIGHT_CAR
        fontSizeScale = 1.4
        break
      case DeviceType.PHONE:
      default:
        designWidth = DeviceAdapter.DESIGN_WIDTH_PHONE
        designHeight = DeviceAdapter.DESIGN_HEIGHT_PHONE
        fontSizeScale = 1.0
        break
    }

    // 计算缩放比例
    const widthScale = screenWidth / designWidth
    const heightScale = screenHeight / designHeight
    const scaleRatio = Math.min(widthScale, heightScale)

    return {
      deviceType,
      screenWidth,
      screenHeight,
      scaleRatio,
      isSmallScreen: deviceType === DeviceType.WATCH,
      fontSizeScale
    }
  }

  // 判断是否为手表设备
  static isWatch(): boolean {
    return DeviceAdapter.getDeviceType() === DeviceType.WATCH
  }

  // 判断是否为平板设备
  static isTablet(): boolean {
    return DeviceAdapter.getDeviceType() === DeviceType.TABLET
  }

  // 判断是否为手机设备
  static isPhone(): boolean {
    return DeviceAdapter.getDeviceType() === DeviceType.PHONE
  }

  // 获取适配后的游戏尺寸
  static getAdaptedGameSize(): GameSize {
    const config = DeviceAdapter.getDeviceConfig()
    
    let designWidth: number
    let designHeight: number

    switch (config.deviceType) {
      case DeviceType.TABLET:
        designWidth = DeviceAdapter.DESIGN_WIDTH_TABLET
        designHeight = DeviceAdapter.DESIGN_HEIGHT_TABLET
        break
      case DeviceType.WATCH:
        designWidth = DeviceAdapter.DESIGN_WIDTH_WATCH
        designHeight = DeviceAdapter.DESIGN_HEIGHT_WATCH
        break
      case DeviceType.TV:
        designWidth = DeviceAdapter.DESIGN_WIDTH_TV
        designHeight = DeviceAdapter.DESIGN_HEIGHT_TV
        break
      case DeviceType.CAR:
        designWidth = DeviceAdapter.DESIGN_WIDTH_CAR
        designHeight = DeviceAdapter.DESIGN_HEIGHT_CAR
        break
      case DeviceType.PHONE:
      default:
        designWidth = DeviceAdapter.DESIGN_WIDTH_PHONE
        designHeight = DeviceAdapter.DESIGN_HEIGHT_PHONE
        break
    }

    const result: GameSize = {
      width: Math.floor(designWidth * config.scaleRatio),
      height: Math.floor(designHeight * config.scaleRatio)
    }
    return result
  }
  
  // 判断是否为电视设备
  static isTV(): boolean {
    return DeviceAdapter.getDeviceType() === DeviceType.TV
  }
  
  // 判断是否为车载设备
  static isCar(): boolean {
    return DeviceAdapter.getDeviceType() === DeviceType.CAR
  }
}
