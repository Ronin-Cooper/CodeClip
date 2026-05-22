import SwiftUI

/// 历史记录设置面板
/// 包含：最大记录数量、自动清除时长
struct HistorySettingsView: View {
    @ObservedObject private var settings = SettingsManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("历史记录")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 16) {
                // 最大记录数量：50/100/200/500
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("最大记录数量")
                            .font(.body)
                        Text("超出限制后将自动删除最旧的记录")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Picker("", selection: $settings.maxItemsOption) {
                        ForEach(MaxItemsOption.allCases) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 100)
                }

                Divider()

                // 自动清除：1天/7天/30天/永不
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("自动清除")
                            .font(.body)
                        Text("自动删除超过指定时间的记录")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Picker("", selection: $settings.autoClearOption) {
                        ForEach(AutoClearOption.allCases) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 100)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)

            Spacer()
        }
    }
}
