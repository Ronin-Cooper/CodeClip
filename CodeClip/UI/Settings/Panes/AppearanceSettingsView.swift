import SwiftUI

/// 外观设置面板
/// 包含：面板显示位置（屏幕居中/跟随光标/屏幕顶部）
struct AppearanceSettingsView: View {
    @ObservedObject private var settings = SettingsManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("外观")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 16) {
                // 面板位置标题
                VStack(alignment: .leading, spacing: 2) {
                    Text("面板位置")
                        .font(.body)
                    Text("剪贴板面板在屏幕上的显示位置")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // 位置选项列表（单选）
                VStack(spacing: 8) {
                    ForEach(PanelPosition.allCases) { position in
                        HStack {
                            Image(systemName: iconForPosition(position))
                                .frame(width: 20)
                                .foregroundColor(settings.panelPosition == position ? .blue : .secondary)

                            Text(position.displayName)
                                .font(.body)

                            Spacer()

                            // 选中项显示勾号
                            if settings.panelPosition == position {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(settings.panelPosition == position ? Color.blue.opacity(0.1) : Color.clear)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            settings.panelPosition = position
                        }
                    }
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)

            Spacer()
        }
    }

    /// 根据面板位置返回对应的 SF Symbol 图标
    private func iconForPosition(_ position: PanelPosition) -> String {
        switch position {
        case .center: return "rectangle.center.inset.filled"
        case .followCursor: return "cursorarrow.rays"
        case .top: return "arrow.up.to.line"
        }
    }
}
