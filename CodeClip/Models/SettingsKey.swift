import Foundation
import AppKit

// MARK: - UserDefaults Keys
// 所有设置项的持久化存储键名

enum SettingsKey {
    // 通用设置
    static let launchAtLogin = "launchAtLogin"           // 开机自启动

    // 快捷键设置
    static let hotKeyModifiers = "hotKeyModifiers"       // 修饰键（Cmd/Shift/Ctrl/Option）
    static let hotKeyKeyCode = "hotKeyKeyCode"           // 主键的虚拟键码

    // 历史记录设置
    static let maxItems = "maxItems"                     // 最大记录数量
    static let autoClearDays = "autoClearDays"           // 自动清除天数

    // 外观设置
    static let panelPosition = "panelPosition"           // 面板显示位置
    static let appTheme = "appTheme"                     // 应用主题
    static let customThemeColors = "customThemeColors"   // 自定义主题颜色
}

// MARK: - Enums
// 设置选项的枚举类型

/// 面板显示位置
enum PanelPosition: String, CaseIterable, Identifiable {
    case followCursor = "followCursor"
    case top = "top"
    case rightBottom = "rightBottom"
    case leftBottom = "leftBottom"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .followCursor: return "跟随光标"
        case .top: return "屏幕顶部"
        case .rightBottom: return"右侧底部"
        case .leftBottom: return "左侧底部"
        }
    }
}

/// 应用主题
enum AppTheme: String, CaseIterable, Identifiable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    case custom = "custom"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "跟随系统"
        case .light: return "浅色"
        case .dark: return "深色"
        case .custom: return "自定义"
        }
    }

    var icon: String {
        switch self {
        case .system: return "desktopcomputer"
        case .light: return "sun.max"
        case .dark: return "moon"
        case .custom: return "paintpalette"
        }
    }
}

/// 最大历史记录数量选项
enum MaxItemsOption: Int, CaseIterable, Identifiable {
    case fifty = 50
    case oneHundred = 100
    case twoHundred = 200
    case fiveHundred = 500

    var id: Int { rawValue }

    var displayName: String {
        "\(rawValue) 条"
    }
}

/// 自动清除时长选项
enum AutoClearOption: Int, CaseIterable, Identifiable {
    case never = 0
    case oneDay = 1
    case sevenDays = 7
    case thirtyDays = 30

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .never: return "永不"
        case .oneDay: return "1 天"
        case .sevenDays: return "7 天"
        case .thirtyDays: return "30 天"
        }
    }

    var timeInterval: TimeInterval? {
        switch self {
        case .never: return nil
        case .oneDay: return 86_400
        case .sevenDays: return 604_800
        case .thirtyDays: return 2_592_000
        }
    }
}

// MARK: - Default Values

extension SettingsKey {
    // Default hotkey: Cmd+Shift+V
    static let defaultModifiers: UInt64 = CGEventFlags.maskCommand.rawValue | CGEventFlags.maskShift.rawValue
    static let defaultKeyCode: Int = 0x09 // V key
}
