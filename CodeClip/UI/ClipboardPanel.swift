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
    private var globalMonitor: Any?        // 全局鼠标事件监听（面板外点击关闭）
    private var lastClickTime: TimeInterval = 0  // 最近一次内部交互时间戳
    private var isHiding = false           // 标记是否正在执行隐藏动画，防止重复调用

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
        collectionBehavior = [.fullScreenAuxiliary, .ignoresCycle, .transient]  // 不跨 Space，失焦时自动隐藏
        backgroundColor = NSColor.clear                 // 透明背景（由 SwiftUI 视图控制外观）
        isMovableByWindowBackground = true              // 允许拖动面板
        hasShadow = false                               // 不使用系统阴影（由 SwiftUI 实现）
        animationBehavior = .none                       // 禁用系统动画（使用自定义动画）
        hidesOnDeactivate = true                        // 失焦时自动隐藏（配合 .transient）
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

    /// 设置全局鼠标事件监听器
    private func setupEventMonitors() {
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self else { return }

            // 设置窗口打开时，不处理任何关闭逻辑
            if SettingsWindow.shared.isVisible {
                return
            }

            // 点击来源是面板自身（包括 panel 上的 SwiftUI 控件），直接跳过关闭
            if event.windowNumber == self.windowNumber {
                return
            }

            // 将点击位置转换为屏幕坐标
            // locationInWindow 是事件源窗口的本地坐标，需要加上该窗口的屏幕原点
            let clickScreenLocation: NSPoint
            if let eventWindow = event.window {
                clickScreenLocation = NSPoint(
                    x: event.locationInWindow.x + eventWindow.frame.origin.x,
                    y: event.locationInWindow.y + eventWindow.frame.origin.y
                )
            } else {
                clickScreenLocation = event.locationInWindow
            }

            // 坐标检查：点击位置在面板扩展区域内，直接跳过关闭
            let paddedFrame = self.frame.insetBy(dx: -12, dy: -12)
            if paddedFrame.contains(clickScreenLocation) {
                return
            }

            // 时间戳检测：如果此前有面板内的交互（按钮点击等），视为同一次操作，跳过关闭
            let timeDiff = abs(event.timestamp - self.lastClickTime)
            if timeDiff < 0.3 { // 300ms 容差，覆盖 View 重建和动画延迟
                return
            }

            self.hide()
        }
    }

    /// 移除事件监听器
    private func removeEventMonitors() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        lastClickTime = 0
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
        // 如果正在执行隐藏动画，先完成隐藏再显示，避免状态冲突
        if isHiding {
            isHiding = false
            orderOut(nil)
        }

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

        // 延迟激活应用，让淡入动画先开始，避免激活瞬间的窗口重排导致闪烁
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
            NSApp.activate(ignoringOtherApps: true)
        }

        setupEventMonitors()  // 开始监听鼠标事件
        lastClickTime = Date().timeIntervalSince1970  // 记录显示时间戳

        // 淡入动画
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            animator().alphaValue = 1.0
        }
    }

    /// 隐藏面板（带淡出动画）
    /// - Parameter restorePreviousApp: 是否恢复之前的活跃应用，打开设置窗口时为 false
    func hide(restorePreviousApp: Bool = true) {
        // 防止重复触发隐藏动画
        if isHiding { return }
        isHiding = true

        removeEventMonitors()  // 停止监听鼠标事件

        // 在动画开始前捕获 previousApp，避免 completionHandler 中 self.previousApp 已过期
        let appToRestore = restorePreviousApp ? previousApp : nil
        // 淡出动画
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.08  // 缩短淡出时长，减少用户等待感
            animator().alphaValue = 0.0
        } completionHandler: {
            self.isHiding = false
            self.orderOut(nil)
            // 恢复到之前的应用（如果 CodeClip 当前是前台应用，说明用户未主动切换）
            // 只有 CodeClip 自身是前台时才切回 previousApp，避免与用户主动切换冲突
            if let app = appToRestore,
               NSWorkspace.shared.frontmostApplication?.bundleIdentifier == Bundle.main.bundleIdentifier {
                app.activate()
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
