import Foundation
import Combine
import AppKit

/// 设置管理器 - 统一管理所有应用设置的读写和持久化
///
/// 设计说明：
/// - 使用私有存储属性 + 公开计算属性的模式，手动控制通知时机
/// - 不使用 @Published，而是通过 objectWillChange 手动发送变更通知
/// - notifyChange() 延迟到下一个 RunLoop 周期，避免"视图更新中发布变更"的警告
/// - 所有设置持久化到 UserDefaults
class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    private let defaults = UserDefaults.standard

    // MARK: - General（通用设置）

    /// 开机自启动
    var launchAtLogin: Bool {
        get { _launchAtLogin }
        set {
            guard _launchAtLogin != newValue else { return }
            _launchAtLogin = newValue
            defaults.set(newValue, forKey: SettingsKey.launchAtLogin)
            notifyChange()
        }
    }
    private var _launchAtLogin: Bool = false

    // MARK: - Shortcut（快捷键设置）

    /// 快捷键修饰键（Cmd/Shift/Ctrl/Option 的 rawValue 组合）
    var hotKeyModifiers: UInt64 {
        get { _hotKeyModifiers }
        set {
            guard _hotKeyModifiers != newValue else { return }
            _hotKeyModifiers = newValue
            defaults.set(newValue, forKey: SettingsKey.hotKeyModifiers)
            notifyChange()
        }
    }
    private var _hotKeyModifiers: UInt64 = SettingsKey.defaultModifiers

    /// 快捷键主键的虚拟键码
    var hotKeyKeyCode: Int {
        get { _hotKeyKeyCode }
        set {
            guard _hotKeyKeyCode != newValue else { return }
            _hotKeyKeyCode = newValue
            defaults.set(newValue, forKey: SettingsKey.hotKeyKeyCode)
            notifyChange()
        }
    }
    private var _hotKeyKeyCode: Int = SettingsKey.defaultKeyCode

    // MARK: - History（历史记录设置）

    /// 最大历史记录数量
    var maxItemsOption: MaxItemsOption {
        get { _maxItemsOption }
        set {
            guard _maxItemsOption != newValue else { return }
            _maxItemsOption = newValue
            defaults.set(newValue.rawValue, forKey: SettingsKey.maxItems)
            notifyChange()
        }
    }
    private var _maxItemsOption: MaxItemsOption = .oneHundred

    /// 自动清除过期记录的时长
    var autoClearOption: AutoClearOption {
        get { _autoClearOption }
        set {
            guard _autoClearOption != newValue else { return }
            _autoClearOption = newValue
            defaults.set(newValue.rawValue, forKey: SettingsKey.autoClearDays)
            notifyChange()
        }
    }
    private var _autoClearOption: AutoClearOption = .never

    // MARK: - Appearance（外观设置）

    /// 面板显示位置（屏幕居中/跟随光标/屏幕顶部）
    var panelPosition: PanelPosition {
        get { _panelPosition }
        set {
            guard _panelPosition != newValue else { return }
            _panelPosition = newValue
            defaults.set(newValue.rawValue, forKey: SettingsKey.panelPosition)
            notifyChange()
        }
    }
    // 默认跟随光标
    private var _panelPosition: PanelPosition = .followCursor

    /// 应用主题（浅色/深色/跟随系统）
    var appTheme: AppTheme {
        get { _appTheme }
        set {
            guard _appTheme != newValue else { return }
            _appTheme = newValue
            defaults.set(newValue.rawValue, forKey: SettingsKey.appTheme)
            applyTheme()
            notifyChange()
        }
    }
    private var _appTheme: AppTheme = .system

    // MARK: - Computed Properties（计算属性）

    /// 最大记录数（便捷访问）
    var maxItems: Int {
        maxItemsOption.rawValue
    }

    /// 自动清除的时间间隔（秒），nil 表示永不清除
    var autoClearInterval: TimeInterval? {
        autoClearOption.timeInterval
    }

    // MARK: - Init

    private init() {
        let d = UserDefaults.standard

        // 从 UserDefaults 加载设置，未找到时使用默认值
        _launchAtLogin = d.object(forKey: SettingsKey.launchAtLogin) as? Bool ?? false
        _hotKeyModifiers = d.object(forKey: SettingsKey.hotKeyModifiers) as? UInt64 ?? SettingsKey.defaultModifiers
        _hotKeyKeyCode = d.object(forKey: SettingsKey.hotKeyKeyCode) as? Int ?? SettingsKey.defaultKeyCode
        _maxItemsOption = MaxItemsOption(rawValue: d.object(forKey: SettingsKey.maxItems) as? Int ?? MaxItemsOption.oneHundred.rawValue) ?? .oneHundred
        _autoClearOption = AutoClearOption(rawValue: d.object(forKey: SettingsKey.autoClearDays) as? Int ?? AutoClearOption.never.rawValue) ?? .never
        _panelPosition = PanelPosition(rawValue: d.string(forKey: SettingsKey.panelPosition) ?? PanelPosition.followCursor.rawValue) ?? .followCursor
        _appTheme = AppTheme(rawValue: d.string(forKey: SettingsKey.appTheme) ?? AppTheme.system.rawValue) ?? .system

        // 启动时应用主题设置
        applyTheme()
    }

    // MARK: - Change Notification

    private var notifyPending = false

    /// 延迟发送 objectWillChange 通知到下一个 RunLoop 周期
    /// 同一 RunLoop 周期内的多次调用会合并为一次通知，避免：
    /// 1. SwiftUI 视图更新中发布变更的警告
    /// 2. updateHotKey 同时修改两个值时触发两次 reRegister
    private func notifyChange() {
        guard !notifyPending else { return }
        notifyPending = true
        DispatchQueue.main.async { [weak self] in
            self?.notifyPending = false
            self?.objectWillChange.send()
        }
    }

    // MARK: - Hotkey Helpers（快捷键辅助方法）

    /// 快捷键的可读显示字符串，如 "⌘+⇧+V"
    var hotKeyDisplayString: String {
        var parts: [String] = []
        let flags = CGEventFlags(rawValue: hotKeyModifiers)

        if flags.contains(.maskControl) { parts.append("⌃") }
        if flags.contains(.maskAlternate) { parts.append("⌥") }
        if flags.contains(.maskShift) { parts.append("⇧") }
        if flags.contains(.maskCommand) { parts.append("⌘") }

        parts.append(Self.keyCodeToString(UInt16(hotKeyKeyCode)))

        return parts.joined(separator: "+")
    }

    /// 原子更新修饰键和主键码（只触发一次通知，避免 reRegister 被调用两次）
    func updateHotKey(modifiers: UInt64, keyCode: Int) {
        _hotKeyModifiers = modifiers
        _hotKeyKeyCode = keyCode
        defaults.set(modifiers, forKey: SettingsKey.hotKeyModifiers)
        defaults.set(keyCode, forKey: SettingsKey.hotKeyKeyCode)
        notifyChange()
    }

    /// 将虚拟键码转换为可读的按键名称
    private static func keyCodeToString(_ keyCode: UInt16) -> String {
        let keyMap: [UInt16: String] = [
            0x00: "A", 0x01: "S", 0x02: "D", 0x03: "F", 0x04: "H",
            0x05: "G", 0x06: "Z", 0x07: "X", 0x08: "C", 0x09: "V",
            0x0B: "B", 0x0C: "Q", 0x0D: "W", 0x0E: "E", 0x0F: "R",
            0x10: "Y", 0x11: "T", 0x12: "1", 0x13: "2", 0x14: "3",
            0x15: "4", 0x16: "6", 0x17: "5", 0x18: "=", 0x19: "9",
            0x1A: "7", 0x1B: "-", 0x1C: "8", 0x1D: "0", 0x1E: "]",
            0x1F: "O", 0x20: "U", 0x21: "[", 0x22: "I", 0x23: "P",
            0x25: "L", 0x26: "J", 0x28: "K", 0x2C: "/", 0x2D: "N",
            0x2E: "M", 0x31: "Space", 0x24: "Return",
            0x30: "Tab", 0x33: "Delete", 0x35: "Esc",
        ]
        return keyMap[keyCode] ?? "Key\(keyCode)"
    }

    // MARK: - Theme Helpers

    /// 根据当前主题设置应用外观
    private func applyTheme() {
        // NSApp 可能在 SettingsManager.init() 时尚未完全初始化，延迟到主线程执行
        DispatchQueue.main.async {
            switch self.appTheme {
            case .system:
                NSApp.appearance = nil  // 跟随系统
            case .light:
                NSApp.appearance = NSAppearance(named: .aqua)
            case .dark:
                NSApp.appearance = NSAppearance(named: .darkAqua)
            }
        }
    }
}
