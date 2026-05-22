import SwiftUI
import AppKit

/// CodeClip - macOS 菜单栏剪贴板历史管理器
///
/// 应用入口点。这是一个 LSUIElement 应用（菜单栏驻留，无 Dock 图标）。
/// 初始化时注册全局快捷键和剪贴板监听器，通过 MenuBarExtra 提供菜单操作。
@main
struct CodeClipApp: App {
    @StateObject private var settings = SettingsManager.shared

    init() {
        // 注册全局快捷键回调：按下快捷键时切换剪贴板面板的显示/隐藏
        HotKeyManager.shared.onHotKey = {
            DispatchQueue.main.async {
                ClipboardPanel.shared.toggle()
            }
        }
        HotKeyManager.shared.register()

        // 强制初始化剪贴板管理器单例，启动定时器轮询
        _ = ClipboardManager.shared
    }

    var body: some Scene {
        MenuBarExtra("CodeClip", systemImage: "clipboard") {
            Button("设置...") {
                SettingsWindow.shared.show()
            }
            .keyboardShortcut(",")

            Divider()

            Button("退出 CodeClip") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}
