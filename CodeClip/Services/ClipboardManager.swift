import AppKit
import Combine

/// 剪贴板管理器 - 监控剪贴板变化并维护历史记录
///
/// 职责：
/// - 定时轮询剪贴板，检测新内容
/// - 维护历史记录（支持固定、删除、清空）
/// - 自动清除过期记录
/// - 防止程序内部粘贴操作被重复记录
class ClipboardManager: ObservableObject {
    static let shared = ClipboardManager()

    /// 历史记录变化时发送的通知
    static let historyDidChangeNotification = Notification.Name("ClipboardHistoryDidChange")

    /// 剪贴板历史记录列表
    @Published private(set) var history: [ClipboardItem] = []

    // MARK: - 私有属性

    private var maxItems: Int { SettingsManager.shared.maxItems }  // 从设置动态读取
    private var timer: Timer?                  // 剪贴板轮询定时器
    private var autoClearTimer: Timer?         // 自动清除定时器
    private var lastChangeCount: Int = 0       // 上次检测到的 changeCount，用于判断是否有新内容
    private var ignoreNextChange = false       // 标记位：跳过下一次剪贴板变化（用于程序内部粘贴）
    private var cancellables = Set<AnyCancellable>()

    private init() {
        lastChangeCount = NSPasteboard.general.changeCount
        startMonitoring()
        startAutoClear()

        // 监听设置变化，动态调整历史记录上限
        SettingsManager.shared.objectWillChange
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.trimHistory()
                }
            }
            .store(in: &cancellables)
    }

    deinit {
        timer?.invalidate()
        autoClearTimer?.invalidate()
    }

    // MARK: - 定时器管理

    /// 启动剪贴板轮询定时器（每 0.1 秒检查一次）
    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.checkForChanges()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    /// 启动自动清除定时器（每 60 秒检查一次过期记录）
    private func startAutoClear() {
        autoClearTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.autoClearOldItems()
        }
        RunLoop.main.add(autoClearTimer!, forMode: .common)
        autoClearOldItems() // 启动时立即执行一次
    }

    /// 清除超过指定时间的非固定记录
    private func autoClearOldItems() {
        guard let interval = SettingsManager.shared.autoClearInterval else { return }
        let cutoff = Date().addingTimeInterval(-interval)
        let before = history.count
        history.removeAll { !$0.isPinned && $0.timestamp < cutoff }
        if history.count != before {
            NotificationCenter.default.post(name: Self.historyDidChangeNotification, object: nil)
        }
    }

    /// 裁剪历史记录，确保不超过最大数量限制
    /// 固定项不会被裁剪，优先裁剪最旧的非固定项
    private func trimHistory() {
        let pinnedCount = history.filter(\.isPinned).count
        while history.count - pinnedCount > maxItems,
              let lastIndex = history.lastIndex(where: { !$0.isPinned }) {
            history.remove(at: lastIndex)
        }
        if history.count != history.filter(\.isPinned).count || history.count > maxItems + pinnedCount {
            NotificationCenter.default.post(name: Self.historyDidChangeNotification, object: nil)
        }
    }

    /// 检查剪贴板是否有新内容
    private func checkForChanges() {
        let pasteboard = NSPasteboard.general
        let changeCount = pasteboard.changeCount

        // changeCount 未变化说明没有新内容
        guard changeCount != lastChangeCount else { return }
        lastChangeCount = changeCount

        // 如果是程序内部粘贴触发的变化，跳过记录
        if ignoreNextChange {
            ignoreNextChange = false
            return
        }

        let types = pasteboard.types ?? []
        print("[ClipboardManager] changeCount=\(changeCount), types=\(types)")

        var newContent: ClipboardContent?

        // 优先读取文本内容
        if types.contains(.string), let string = pasteboard.string(forType: .string) {
            print("[ClipboardManager] read string: \(string.prefix(50))")
            newContent = .text(string)
        }
        // 其次读取图片内容（通过 TIFF 数据创建 NSImage，避免 NSSecureCoding 警告）
        else if types.contains(.tiff),
                  let data = pasteboard.data(forType: .tiff),
                  let image = NSImage(data: data) {
            newContent = .image(image)
        }

        guard let content = newContent else {
            print("[ClipboardManager] no supported content found")
            return
        }

        // 去重：如果与最新一条内容相同则跳过（避免重新粘贴时产生重复记录）
        if let last = history.first, last.content == content {
            return
        }

        let item = ClipboardItem(content: content, timestamp: Date())
        history.insert(item, at: 0)
        sortHistory()
        trimHistory()

        print("[ClipboardManager] added item, total=\(history.count)")
        NotificationCenter.default.post(name: Self.historyDidChangeNotification, object: nil)
    }

    // MARK: - 公开方法

    /// 标记跳过下一次剪贴板变化（用于程序内部粘贴操作）
    func ignoreNextPasteboardChange() {
        ignoreNextChange = true
    }

    /// 切换指定项的固定状态，并重新排序
    func togglePin(id: UUID) {
        guard let index = history.firstIndex(where: { $0.id == id }) else { return }
        history[index].isPinned.toggle()
        sortHistory()
        NotificationCenter.default.post(name: Self.historyDidChangeNotification, object: nil)
    }

    /// 删除指定项
    func deleteItem(with id: UUID) {
        history.removeAll { $0.id == id }
        NotificationCenter.default.post(name: Self.historyDidChangeNotification, object: nil)
    }

    /// 清除所有非固定项
    func clearAll() {
        history.removeAll { !$0.isPinned }
        NotificationCenter.default.post(name: Self.historyDidChangeNotification, object: nil)
    }

    // MARK: - 私有方法

    /// 排序：固定项置顶，其余按时间倒序
    private func sortHistory() {
        history.sort { a, b in
            if a.isPinned != b.isPinned { return a.isPinned }
            return a.timestamp > b.timestamp
        }
    }
}
