import AppKit
import SwiftUI

/// 剪贴板历史浮动面板
///
/// 使用 NSPanel 实现的无边框浮动窗口，用于显示剪贴板历史记录列表。
/// 支持三种定位模式（屏幕居中/跟随光标/屏幕顶部），通过设置动态配置。
/// 点击面板外部区域或按 ESC 键关闭面板。
class ClipboardPanel: NSPanel {
    static let shared = ClipboardPanel()

    // MARK: - 面板尺寸配置

    private let panelWidth: CGFloat = 360
    private let panelMaxHeight: CGFloat = 500
    private let cornerRadius: CGFloat = 12

    // MARK: - 私有属性

    private var previousApp: NSRunningApplication?       // 打开面板前的活跃应用，关闭时恢复
    private var hostingView: NSHostingView<ClipboardHistoryView>?
    private var globalMonitor: Any?                    // 全局鼠标事件监听（面板外点击）
    
    private var localMonitor: Any?      // 【新增】本地鼠标事件监听（面板内部点击）
    private var isClickInsidePanel = false // 【新增】标记当前点击是否发生在面板内部
    // 用时间戳代替布尔标志，避免状态残留
    private var lastLocalClickTime: TimeInterval = 0

    // MARK: - 初始化

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: panelMaxHeight),
            styleMask: [.borderless],  // 无边框样式
            backing: .buffered,
            defer: false
        )

        // 面板属性配置
        isFloatingPanel = true                          // 浮动面板，始终在其他窗口之上
        level = .floating                               // 浮动层级
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]  // 跨 Space 显示
        backgroundColor = NSColor.clear                 // 透明背景（由 SwiftUI 视图控制外观）
        isMovableByWindowBackground = true              // 允许拖动面板
        hasShadow = false                               // 不使用系统阴影（由 SwiftUI 实现）
        animationBehavior = .none                       // 禁用系统动画（使用自定义动画）
        hidesOnDeactivate = false                       // 不自动隐藏（由事件监听器控制关闭）
        isOpaque = false                                // 非不透明（支持毛玻璃效果）

        setupNotifications()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var canBecomeKey: Bool { true }   // 允许成为 key window（接收键盘事件）
    override var canBecomeMain: Bool { true }  // 允许成为 main window

    // MARK: - 通知设置

    /// 监听剪贴板历史变化，实时更新面板内容
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clipboardDidChange),
            name: ClipboardManager.historyDidChangeNotification,
            object: nil
        )
    }

    // MARK: - 事件监听

    /// 设置鼠标事件监听器，用于点击面板外部时关闭面板
    private func setupEventMonitors() {
        // 【关键修改】本地监听：仅记录点击时间戳，绝不消费事件（始终返回 event）
            localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
                guard let self = self else { return event }
                
                let locationInPanel = self.contentView?.convert(event.locationInWindow, from: nil) ?? .zero
                let isInContentArea = self.contentView?.bounds.contains(locationInPanel) ?? false
                
                if isInContentArea {
                    // ✅ 只记录时间戳，不消费事件，按钮和关闭按钮正常响应
                    self.lastLocalClickTime = event.timestamp
                }
                
                // ✅ 始终返回 event，保证事件继续派发给 NSButton / NSWindow
                return event
            }
            
            // 全局监听：通过时间戳判断是否为同一次点击
            globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
                guard let self = self else { return }
                
                // 设置窗口打开时，不处理任何关闭逻辑
                if SettingsWindow.shared.isVisible {
                    return
                }
                
                // 【关键】如果全局事件与本地事件时间戳相同（或极接近），
                // 说明这是面板内部的同一次点击，跳过关闭
                let timeDiff = abs(event.timestamp - self.lastLocalClickTime)
                if timeDiff < 0.05 { // 50ms 容差，覆盖事件派发延迟
                    return
                }
                
                let clickLocation = event.locationInWindow
                let paddedFrame = self.frame.insetBy(dx: -2, dy: -2)
                
                if !paddedFrame.contains(clickLocation) {
                    self.hide()
                }
            }
    }

    /// 移除事件监听器
    private func removeEventMonitors() {
        if let monitor = globalMonitor {
                NSEvent.removeMonitor(monitor)
                globalMonitor = nil
            }
            if let monitor = localMonitor {
                NSEvent.removeMonitor(monitor)
                localMonitor = nil
            }
            lastLocalClickTime = 0
    }

    // MARK: - 视图构建

    /// 创建剪贴板历史的 SwiftUI 视图
    private func makeSwiftUIView() -> ClipboardHistoryView {
        ClipboardHistoryView(
            items: ClipboardManager.shared.history,
            onPaste: { index in
                self.pasteItem(at: index)
            },
            onPin: { id in
                ClipboardManager.shared.togglePin(id: id)
            },
            onDelete: { id in
                ClipboardManager.shared.deleteItem(with: id)
            },
            onClearAll: {
                ClipboardManager.shared.clearAll()
            }
        )
    }

    // MARK: - 显示/隐藏

    /// 显示面板（带淡入动画）
    func show() {
        previousApp = NSWorkspace.shared.frontmostApplication  // 记住当前活跃应用
        positionPanel()                                         // 根据设置定位面板
        alphaValue = 0                                          // 初始透明

        // 重建 SwiftUI 视图
        hostingView?.removeFromSuperview()
        hostingView = NSHostingView(rootView: makeSwiftUIView())
        hostingView?.frame = NSRect(x: 0, y: 0, width: panelWidth, height: panelMaxHeight)
        contentView = hostingView

        orderFrontRegardless()                           // 强制显示在最前
        makeKeyAndOrderFront(nil)                        // 成为 key window
        NSApp.activate(ignoringOtherApps: true)          // 激活应用

        setupEventMonitors()                             // 开始监听鼠标事件

        // 淡入动画
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            animator().alphaValue = 1.0
        }
    }

    /// 隐藏面板（带淡出动画）
    /// - Parameter restorePreviousApp: 是否恢复之前的活跃应用，打开设置窗口时为 false
    func hide(restorePreviousApp: Bool = true) {
        removeEventMonitors()  // 停止监听鼠标事件
        // 淡出动画
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            animator().alphaValue = 0.0
        } completionHandler: {
            self.orderOut(nil)
            if restorePreviousApp {
                self.previousApp?.activate()  // 恢复到之前的应用
            }
        }
    }

    /// 切换面板显示/隐藏
    func toggle() {
        if isVisible {
            hide()
        } else {
            show()
        }
    }

    /// ESC 键关闭面板
    override func cancelOperation(_ sender: Any?) {
        hide()
    }

    // MARK: - 面板定位

    /// 根据设置选择定位模式
    private func positionPanel() {
        let position = SettingsManager.shared.panelPosition

        switch position {
        case .followCursor:
            positionFollowCursor()
        case .top:
            positionCenterTop()
        case .rightBottom:
            positionScreenBottomRight()
        case .leftBottom:
            positionScreenBottomLeft()
        }
    }

    /// 获取鼠标当前所在屏幕的安全方法（关闭独立空间后仍需动态匹配）
    private var currentScreen: NSScreen? {
        let mouseLoc = NSEvent.mouseLocation
        return NSScreen.screens.first(where: { NSMouseInRect(mouseLoc, $0.frame, false) })
            ?? NSScreen.main
    }

    /// 定位到屏幕居中偏上位置
    private func positionCenterTop() {
        guard let screen = currentScreen else { return }
        let rect = screen.visibleFrame
        let topOffset = rect.height * 0.2
        let x = rect.midX - panelWidth / 2
        let y = rect.maxY - panelMaxHeight - topOffset
        setFrame(NSRect(x: x, y: y, width: panelWidth, height: panelMaxHeight), display: false)
    }

    /// 定位到光标右下方
    private func positionFollowCursor() {
        guard let screen = currentScreen else { return }
        let mouseLocation = NSEvent.mouseLocation
        let cursorOffset: CGFloat = 15
        var x = mouseLocation.x + cursorOffset
        var y = mouseLocation.y - panelMaxHeight - cursorOffset

        // 边界钳制：确保面板不超出当前屏幕可见区域
        let visibleFrame = screen.visibleFrame
        x = max(visibleFrame.minX, min(x, visibleFrame.maxX - panelWidth))
        y = max(visibleFrame.minY, min(y, visibleFrame.maxY - panelMaxHeight))

        setFrame(NSRect(x: x, y: y, width: panelWidth, height: panelMaxHeight), display: false)
    }

    /// 定位到屏幕右下角
    private func positionScreenBottomRight() {
        guard let screen = currentScreen else { return }
        let rect = screen.visibleFrame
        let x = rect.maxX - panelWidth - 10
        let y = rect.minY + 10
        setFrame(NSRect(x: x, y: y, width: panelWidth, height: panelMaxHeight), display: false)
    }

    /// 定位到屏幕左下角
    private func positionScreenBottomLeft() {
        guard let screen = currentScreen else { return }
        let rect = screen.visibleFrame
        let x = rect.minX + 10
        let y = rect.minY + 10
        setFrame(NSRect(x: x, y: y, width: panelWidth, height: panelMaxHeight), display: false)
    }

    // MARK: - 剪贴板操作

    /// 剪贴板变化时刷新视图
    @objc private func clipboardDidChange() {
        guard isVisible else { return }
        hostingView?.rootView = makeSwiftUIView()
    }

    /// 粘贴指定索引的剪贴板项
    /// 流程：写入剪贴板 → 关闭面板 → 模拟 Cmd+V
    private func pasteItem(at index: Int) {
        let items = ClipboardManager.shared.history
        guard index < items.count else { return }

        let item = items[index]
        let pb = NSPasteboard.general

        // 标记跳过下一次剪贴板变化，防止被重新记录
        ClipboardManager.shared.ignoreNextPasteboardChange()

        // 写入剪贴板
        pb.clearContents()
        switch item.content {
        case .text(let text):
            pb.setString(text, forType: .string)
        case .image(let image):
            if let tiff = image.tiffRepresentation {
                pb.setData(tiff, forType: .tiff)
            }
        }

        // 关闭面板，稍后模拟粘贴（等待面板关闭动画完成）
        hide()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            PasteSimulator.simulatePaste()
        }
    }
}
