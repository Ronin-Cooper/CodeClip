import SwiftUI

/// 外观设置面板
/// 包含：面板显示位置、应用主题、自定义主题颜色
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

            // MARK: - 自定义颜色（仅在选择自定义主题时显示）
            if settings.appTheme == .custom {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("自定义颜色")
                            .font(.body)
                        Text("自定义剪贴板面板的背景、文字和强调色")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    VStack(spacing: 12) {
                        CustomColorRow(
                            label: "背景颜色",
                            hex: Binding(
                                get: { settings.customThemeColors.backgroundColor },
                                set: { h in
                                    var colors = settings.customThemeColors
                                    colors.backgroundColor = h
                                    settings.customThemeColors = colors
                                }
                            )
                        )
                        CustomColorRow(
                            label: "主要文字",
                            hex: Binding(
                                get: { settings.customThemeColors.primaryTextColor },
                                set: { h in
                                    var colors = settings.customThemeColors
                                    colors.primaryTextColor = h
                                    settings.customThemeColors = colors
                                }
                            )
                        )
                        CustomColorRow(
                            label: "次要文字",
                            hex: Binding(
                                get: { settings.customThemeColors.secondaryTextColor },
                                set: { h in
                                    var colors = settings.customThemeColors
                                    colors.secondaryTextColor = h
                                    settings.customThemeColors = colors
                                }
                            )
                        )
                        CustomColorRow(
                            label: "强调色",
                            hex: Binding(
                                get: { settings.customThemeColors.accentColor },
                                set: { h in
                                    var colors = settings.customThemeColors
                                    colors.accentColor = h
                                    settings.customThemeColors = colors
                                }
                            )
                        )
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }

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

// MARK: - 自定义颜色行

/// 自定义主题的单行颜色选择器：标签 + ColorPicker + Hex 显示
private struct CustomColorRow: View {
    let label: String
    @Binding var hex: String

    @State private var pickedColor: Color = .white

    init(label: String, hex: Binding<String>) {
        self.label = label
        self._hex = hex
        self._pickedColor = State(initialValue: Color(hex: hex.wrappedValue) ?? .white)
    }

    var body: some View {
        HStack {
            Text(label)
                .font(.body)
                .frame(width: 80, alignment: .leading)

            ColorPicker("", selection: $pickedColor, supportsOpacity: false)
                .labelsHidden()

            Text(hex.uppercased())
                .font(.caption)
                .foregroundColor(.secondary)
                .fontDesign(.monospaced)

            Spacer()
        }
        .onChange(of: pickedColor) { _, newColor in
            let nsColor = NSColor(newColor)
            hex = nsColor.toHex()
        }
    }
}
