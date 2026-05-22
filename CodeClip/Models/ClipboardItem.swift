import AppKit

/// 剪贴板内容的枚举类型，支持文本和图片两种格式
enum ClipboardContent: Equatable {
    case text(String)
    case image(NSImage)

    // 实现 Equatable 协议，用于内容比较和去重
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.text(let a), .text(let b)):
            return a == b
        case (.image(let a), .image(let b)):
            // 通过 TIFF 数据比较图片内容
            guard let aTiff = a.tiffRepresentation, let bTiff = b.tiffRepresentation else {
                return false
            }
            return aTiff == bTiff
        default:
            return false
        }
    }

    /// 预览文本：取第一行的前 80 个字符，用于列表显示
    var previewText: String {
        switch self {
        case .text(let text):
            let lines = text.split(omittingEmptySubsequences: false) { $0.isNewline }
            let firstLine = lines.first ?? ""
            return String(firstLine.prefix(80))
        case .image:
            return "[Image]"
        }
    }

    /// 完整文本内容（仅文本类型有效）
    var fullText: String? {
        switch self {
        case .text(let text): return text
        case .image: return nil
        }
    }
}

/// 剪贴板历史记录项，包含内容、时间戳和固定状态
struct ClipboardItem: Identifiable, Equatable {
    let id = UUID()
    let content: ClipboardContent
    let timestamp: Date
    var isPinned: Bool = false  // 固定项不会被自动清除或"清除全部"删除

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.content == rhs.content
    }
}
