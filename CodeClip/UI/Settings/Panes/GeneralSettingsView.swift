import SwiftUI
import ServiceManagement

/// 通用设置面板
/// 包含：开机自启动
struct GeneralSettingsView: View {
    @ObservedObject private var settings = SettingsManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("通用")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 16) {
                // 开机自启动：通过 SMAppService 注册/注销登录项
                Toggle(isOn: $settings.launchAtLogin) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("开机自启动")
                            .font(.body)
                        Text("登录时自动启动 CodeClip")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .toggleStyle(.switch)
                .onChange(of: settings.launchAtLogin) { _, newValue in
                    setLaunchAtLogin(newValue)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)

            Spacer()
        }
    }

    /// 设置开机自启动状态
    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()    // 注册登录项
            } else {
                try SMAppService.mainApp.unregister()  // 注销登录项
            }
        } catch {
            print("Failed to set launch at login: \(error)")
        }
    }
}
