import ApplicationServices
import Combine
import AppKit

/// 全局快捷键管理器 - 监听键盘事件，触发剪贴板面板显示
///
/// 使用 CGEvent tap 拦截全局键盘事件，匹配指定的快捷键组合（默认 Cmd+Shift+V）。
/// 需要在系统设置中授予辅助功能权限才能正常工作。
/// 支持动态修改快捷键，修改后自动重新注册。
class HotKeyManager {
    static let shared = HotKeyManager()

    /// 快捷键触发时的回调
    var onHotKey: (() -> Void)?

    // MARK: - 私有属性

    private var eventTap: CFMachPort?          // CGEvent tap 端口
    private var runLoopSource: CFRunLoopSource? // RunLoop 事件源
    private var cancellables = Set<AnyCancellable>()

    private var hotKeyModifiers: CGEventFlags  // 当前快捷键修饰键
    private var hotKeyKeyCode: UInt16          // 当前快捷键主键码

    private init() {
        let settings = SettingsManager.shared
        hotKeyModifiers = CGEventFlags(rawValue: settings.hotKeyModifiers)
        hotKeyKeyCode = UInt16(settings.hotKeyKeyCode)

        // 监听设置变化，快捷键修改后重新注册
        settings.objectWillChange
            .sink { [weak self] _ in
                guard let self = self else { return }
                let newModifiers = CGEventFlags(rawValue: settings.hotKeyModifiers)
                let newKeyCode = UInt16(settings.hotKeyKeyCode)
                if self.hotKeyModifiers != newModifiers || self.hotKeyKeyCode != newKeyCode {
                    self.hotKeyModifiers = newModifiers
                    self.hotKeyKeyCode = newKeyCode
                    self.reRegister()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - 权限检测

    /// 检查辅助功能权限，未授权时弹出引导对话框
    /// - Parameter showOnFailure: 是否在权限缺失时弹出对话框（启动时传 true，后续检查传 false）
    @discardableResult
    func checkAccessibilityPermission(showOnFailure: Bool = false) -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): showOnFailure] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)

        if !trusted && showOnFailure {
            // 延迟弹出对话框，确保 UI 已就绪
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.showAccessibilityAlert()
            }
        }
        return trusted
    }

    /// 弹出辅助功能权限引导对话框
    private func showAccessibilityAlert() {
        let alert = NSAlert()
        alert.messageText = "需要辅助功能权限"
        alert.informativeText = "CodeClip 需要辅助功能权限才能使用全局快捷键和模拟粘贴。\n\n请在「系统设置 → 隐私与安全性 → 辅助功能」中允许 CodeClip。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "打开系统设置")
        alert.addButton(withTitle: "稍后")

        if alert.runModal() == .alertFirstButtonReturn {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        }
    }

    // MARK: - 注册/注销

    /// 注册全局快捷键监听
    /// 通过 CGEvent.tapCreate 拦截所有 keyDown 事件，匹配快捷键后触发回调并消费事件（返回 nil）
    func register() {
        let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue)

        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { proxy, type, event, refcon in
                let manager = Unmanaged<HotKeyManager>.fromOpaque(refcon!).takeUnretainedValue()
                if type == .keyDown {
                    // 提取修饰键和键码
                    let flags = event.flags.intersection([.maskCommand, .maskShift, .maskControl, .maskAlternate])
                    let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode) & 0xFFFF)
                    // 匹配快捷键
                    if flags == manager.hotKeyModifiers && keyCode == manager.hotKeyKeyCode {
                        manager.onHotKey?()
                        return nil  // 消费事件，防止传递给其他应用
                    }
                }
                return Unmanaged.passUnretained(event)  // 非快捷键事件正常传递
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("Failed to create event tap. Accessibility permission may be required.")
            return
        }

        self.eventTap = eventTap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
    }

    /// 注销快捷键监听
    func unregister() {
        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            self.eventTap = nil
        }
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            self.runLoopSource = nil
        }
    }

    /// 重新注册（先注销再注册），用于快捷键变更后
    private func reRegister() {
        unregister()
        register()
    }
}
