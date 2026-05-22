import AppKit
import SwiftUI

/// 设置窗口
///
/// 使用 NSPanel 实现的设置窗口，采用 macOS 标准的左侧边栏 + 右侧内容区布局。
/// 与 ClipboardPanel 不同，这是一个普通窗口（非浮动），关闭时不恢复之前的应用。
class SettingsWindow: NSPanel {
    static let shared = SettingsWindow()

    private let windowWidth: CGFloat = 600
    private let windowHeight: CGFloat = 450
    private var hostingView: NSHostingView<SettingsView>?

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight),
            styleMask: [.titled, .closable, .fullSizeContentView],  // 标题栏 + 关闭按钮 + 全尺寸内容
            backing: .buffered,
            defer: false
        )

        title = "设置"
        isFloatingPanel = false                        // 非浮动窗口（普通窗口层级）
        level = .normal                                // 普通层级
        collectionBehavior = [.canJoinAllSpaces]       // 跨 Space 显示
        isMovableByWindowBackground = true             // 允许拖动
        titlebarAppearsTransparent = true              // 透明标题栏
        titleVisibility = .hidden                      // 隐藏标题文本
        isOpaque = false
        backgroundColor = NSColor.windowBackgroundColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 显示设置窗口
    func show() {
        // 延迟创建视图，避免初始化时加载所有设置 UI
        if hostingView == nil {
            let settingsView = SettingsView()
            hostingView = NSHostingView(rootView: settingsView)
            hostingView?.frame = NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight)
            contentView = hostingView
        }

        center()                                       // 居中显示
        makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    /// 隐藏设置窗口
    func hide() {
        orderOut(nil)
    }
}
