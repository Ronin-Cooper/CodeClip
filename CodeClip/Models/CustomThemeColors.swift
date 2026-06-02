import SwiftUI
import AppKit

// MARK: - 自定义主题颜色模型

/// 用户自定义的 4 组主题颜色，以 Hex 字符串形式存储/持久化
struct CustomThemeColors: Codable, Equatable {
    var backgroundColor: String     // 背景色 hex (#RRGGBB)
    var primaryTextColor: String    // 主要文字色
    var secondaryTextColor: String  // 次要文字色（时间戳、描述）
    var accentColor: String         // 强调色（选中高亮、图标背景）

    /// 默认暗色主题
    static let `default` = CustomThemeColors(
        backgroundColor: "#1E1E1E",
        primaryTextColor: "#FFFFFF",
        secondaryTextColor: "#999999",
        accentColor: "#007AFF"
    )
}

// MARK: - Color 解析扩展

extension CustomThemeColors {
    /// 背景色
    var bgColor: Color {
        Color(hex: backgroundColor) ?? Color(NSColor.controlBackgroundColor)
    }

    /// 主要文字色
    var primaryColor: Color {
        Color(hex: primaryTextColor) ?? .primary
    }

    /// 次要文字色
    var secondaryColor: Color {
        Color(hex: secondaryTextColor) ?? .secondary
    }

    /// 强调色
    var accent: Color {
        Color(hex: accentColor) ?? .accentColor
    }
}

// MARK: - Hex → Color 解析

extension Color {
    /// 从 "#RRGGBB" 或 "RRGGBB" 格式的 Hex 字符串创建 Color
    init?(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard cleaned.count == 6,
              let int = UInt64(cleaned, radix: 16) else { return nil }

        let r = CGFloat((int >> 16) & 0xFF) / 255.0
        let g = CGFloat((int >> 8)  & 0xFF) / 255.0
        let b = CGFloat(int         & 0xFF) / 255.0

        self.init(NSColor(red: r, green: g, blue: b, alpha: 1.0))
    }
}

// MARK: - NSColor → Hex 转换

extension NSColor {
    /// 将 NSColor 转换为 "#RRGGBB" 格式的 Hex 字符串
    func toHex() -> String {
        guard let rgb = usingColorSpace(.sRGB) ?? usingColorSpace(.genericRGB) else {
            return "#000000"
        }
        let r = Int(round(rgb.redComponent   * 255))
        let g = Int(round(rgb.greenComponent * 255))
        let b = Int(round(rgb.blueComponent  * 255))
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
