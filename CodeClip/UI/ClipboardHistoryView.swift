import SwiftUI

// MARK: - Clipboard History View
// 剪贴板历史记录列表视图，显示在浮动面板中

struct ClipboardHistoryView: View {
    let items: [ClipboardItem]          // 历史记录列表
    let onPaste: (Int) -> Void          // 粘贴回调（传入索引）
    let onPin: (UUID) -> Void           // 固定/取消固定回调
    let onDelete: (UUID) -> Void        // 删除回调
    let onClearAll: () -> Void          // 清除全部回调

    @State private var hoveredIndex: Int? = nil  // 当前悬停的行索引

    // 面板尺寸（与 ClipboardPanel 保持一致）
    private let panelWidth: CGFloat = 360
    private let panelMaxHeight: CGFloat = 500
    private let cornerRadius: CGFloat = 12

    var body: some View {
        ZStack(alignment: .top) {
            // Background
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .cornerRadius(cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.25), radius: 20, x: 0, y: 8)
                .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)

            VStack(spacing: 0) {
                // Header
                HeaderView(onClose: {
                    ClipboardPanel.shared.hide()
                })

                Divider()
                    .padding(.horizontal, 16)

                // List
                if items.isEmpty {
                    EmptyStateView()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 4) {
                            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                                ClipboardRowView(
                                    item: item,
                                    index: index,
                                    isHovered: hoveredIndex == index,
                                    onHover: { isHovering in
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            hoveredIndex = isHovering ? index : nil
                                        }
                                    },
                                    onPaste: { onPaste(index) },
                                    onPin: { onPin(item.id) },
                                    onDelete: { onDelete(item.id) }
                                )
                                .id(item.id)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    }
                    .frame(maxHeight: panelMaxHeight - 88)
                }

                Divider()
                    .padding(.horizontal, 16)

                // Footer
                FooterView(onClearAll: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        onClearAll()
                    }
                })
            }
        }
        .frame(width: panelWidth, height: panelMaxHeight)
    }
}

// MARK: - Header View
// 面板头部：标题 + 设置按钮 + 关闭按钮

private struct HeaderView: View {
    let onClose: () -> Void

    var body: some View {
        HStack {
            Text("剪贴板历史记录")
                .font(.headline)
                .foregroundColor(.primary)

            Spacer()

            // 设置按钮：先关闭面板（不恢复之前的应用），再打开设置窗口
            Button(action: {
                ClipboardPanel.shared.hide(restorePreviousApp: false)
                SettingsWindow.shared.show()
            }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .frame(width: 28, height: 28)
                    .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)

            // 关闭按钮
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(width: 28, height: 28)
                    .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Empty State View

private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 32))
                .foregroundColor(.secondary)
            Text("暂无剪贴板记录")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("复制文本或图片后将自动显示在这里")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Clipboard Row View
// 单条剪贴板记录行视图：显示类型图标、内容预览、复制时间、操作按钮

private struct ClipboardRowView: View {
    let item: ClipboardItem
    let index: Int
    let isHovered: Bool
    let onHover: (Bool) -> Void
    let onPaste: () -> Void
    let onPin: () -> Void
    let onDelete: () -> Void

    @State private var showActions = false  // 悬停时显示操作按钮

    var body: some View {
        HStack(spacing: 0) {
            // Content area — different layout for text vs image
            switch item.content {
            case .text:
                HStack(spacing: 10) {
                    // Type icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(typeIconColor)
                            .frame(width: 32, height: 32)
                        Image(systemName: typeIcon)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }

                    // Content preview
                    VStack(alignment: .leading, spacing: 2) {
                        Text(contentPreview)
                            .font(.system(size: 13, design: .monospaced))
                            .lineLimit(2)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(timeAgo)
                            .font(.caption2)
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                }
                .padding(.leading, 10)
                .padding(.vertical, 8)

            case .image(let nsImage):
                // Image thumbnail spanning the full content area
                let thumbHeight = rowHeight - 16  // 减去上下各 8px 的 padding
                ZStack(alignment: .bottomLeading) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: thumbHeight)
                        .clipShape(RoundedRectangle(cornerRadius: 4))

                    // Timestamp overlay
                    Text(timeAgo)
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                        .padding(3)
                }
                .padding(.leading, 10)
                .padding(.vertical, 8)
            }

            Spacer(minLength: 8)

            // Action buttons
            HStack(spacing: 2) {
                if showActions || item.isPinned {
                    ActionButton(
                        icon: item.isPinned ? "pin.fill" : "pin",
                        tooltip: item.isPinned ? "取消固定" : "固定",
                        color: item.isPinned ? .blue : .secondary
                    ) { onPin() }
                }
                if showActions {
                    ActionButton(icon: "trash", tooltip: "删除", color: .red) { onDelete() }
                }
            }
            .padding(.trailing, 8)
        }
        .frame(height: rowHeight)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovered ? Color.primary.opacity(0.06) : Color.clear)
        )
        .contentShape(RoundedRectangle(cornerRadius: 6))
        .onTapGesture {
            onPaste()
        }
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                showActions = hovering
            }
            onHover(hovering)
        }
    }

    /// 行高：文本行紧凑显示，图片行增高以保持缩略图比例
    private var rowHeight: CGFloat {
        switch item.content {
        case .text: return 48
        case .image: return 100
        }
    }

    /// 根据内容类型返回对应的 SF Symbol 图标
    private var typeIcon: String {
        switch item.content {
        case .text: return "doc.text"
        case .image: return "photo"
        }
    }

    /// 根据内容类型返回图标背景色
    private var typeIconColor: Color {
        switch item.content {
        case .text: return .blue
        case .image: return .orange
        }
    }

    /// 内容预览文本
    private var contentPreview: String {
        switch item.content {
        case .text:
            return item.content.previewText
        case .image:
            return item.content.imageDimensionText ?? "[Image]"
        }
    }

    /// 复制时间（HH:mm 格式，静态显示）
    private var timeAgo: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: item.timestamp)
    }
}

// MARK: - Action Button

private struct ActionButton: View {
    let icon: String
    let tooltip: String
    var color: Color = .secondary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(color == .red ? .red : .secondary)
                .frame(width: 24, height: 24)
                .background(
                    color == .red
                        ? Color.red.opacity(0.1)
                        : Color.secondary.opacity(0.1),
                    in: RoundedRectangle(cornerRadius: 4)
                )
        }
        .buttonStyle(.plain)
        .help(tooltip)
    }
}

// MARK: - Footer View

private struct FooterView: View {
    let onClearAll: () -> Void

    var body: some View {
        HStack {
            Button(action: onClearAll) {
                Text("清除全部")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
            .padding(.leading, 16)
            .padding(.vertical, 8)

            Spacer()

            let count = ClipboardManager.shared.history.count
            if count > 0 {
                Text("共 \(count) 项")
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.6))
                    .padding(.trailing, 16)
            }
        }
    }
}

// MARK: - Visual Effect View
// NSVisualEffectView 的 SwiftUI 包装，用于实现毛玻璃背景效果

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material      // 材质类型（如 hudWindow）
    let blendingMode: NSVisualEffectView.BlendingMode  // 混合模式（如 behindWindow）

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active  // 保持活跃状态，不受窗口激活状态影响
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// MARK: - Preview

struct ClipboardHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        ClipboardHistoryView(
            items: [
                ClipboardItem(
                    content: .text("Hello World! This is a sample clipboard item that demonstrates the preview text truncation behavior."),
                    timestamp: Date()
                ),
                ClipboardItem(
                    content: .text("import SwiftUI\nstruct ContentView: View {\n    var body: some View {\n        Text(\"Hello\")\n    }\n}"),
                    timestamp: Date().addingTimeInterval(-120)
                ),
                ClipboardItem(
                    content: .text("https://developer.apple.com/swiftui"),
                    timestamp: Date().addingTimeInterval(-300)
                ),
                ClipboardItem(
                    content: .text("let items = items.filter { $0.isPinned }"),
                    timestamp: Date().addingTimeInterval(-600)
                ),
            ],
            onPaste: { _ in },
            onPin: { _ in },
            onDelete: { _ in },
            onClearAll: {}
        )
        .previewLayout(.sizeThatFits)
    }
}
