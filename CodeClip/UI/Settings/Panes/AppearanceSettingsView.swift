import SwiftUI

/// 外观设置面板
/// 包含：面板显示位置、应用主题
struct AppearanceSettingsView: View {
    @ObservedObject private var settings = SettingsManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("外观")
                .font(.title2)
                .fontWeight(.semibold)

            // MARK: - 主题设置
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("主题")
                        .font(.body)
                    Text("设置剪贴板面板的显示主题")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 12) {
                    ForEach(AppTheme.allCases) { theme in
                        themeCard(theme: theme)
                    }
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)

            // MARK: - 面板位置
            VStack(alignment: .leading, spacing: 16) {
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

    // MARK: - 主题卡片

    @ViewBuilder
    private func themeCard(theme: AppTheme) -> some View {
        VStack(spacing: 6) {
            Image(systemName: theme.icon)
                .font(.system(size: 22))
                .foregroundColor(settings.appTheme == theme ? .white : .primary)

            Text(theme.displayName)
                .font(.caption)
                .foregroundColor(settings.appTheme == theme ? .white : .secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(settings.appTheme == theme ? Color.blue : Color(NSColor.controlAccentColor).opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(settings.appTheme == theme ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            settings.appTheme = theme
        }
    }

    /// 根据面板位置返回对应的 SF Symbol 图标
    private func iconForPosition(_ position: PanelPosition) -> String {
        switch position {
        case .followCursor: return "cursorarrow.rays"
        case .top: return "arrow.up.to.line"
        case .rightBottom: return "arrow.down.right"
        case .leftBottom: return "arrow.down.left"
        }
    }
}
