import SwiftUI

// MARK: - 设置分类枚举

/// 设置界面的分类：通用、快捷键、历史记录、外观
enum SettingsSection: String, CaseIterable, Identifiable {
    case general = "通用"
    case shortcut = "快捷键"
    case history = "历史记录"
    case appearance = "外观"

    var id: String { rawValue }

    /// 侧边栏图标
    var icon: String {
        switch self {
        case .general: return "gear"
        case .shortcut: return "keyboard"
        case .history: return "clock"
        case .appearance: return "paintbrush"
        }
    }
}

// MARK: - 设置根视图

/// 设置窗口的根视图：左侧边栏导航 + 右侧内容区
struct SettingsView: View {
    @State private var selectedSection: SettingsSection = .general

    var body: some View {
        NavigationSplitView {
            // 左侧边栏：分类列表
            List(SettingsSection.allCases, selection: $selectedSection) { section in
                Label(section.rawValue, systemImage: section.icon)
                    .tag(section)
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 120, ideal: 140)
        } detail: {
            // 右侧内容区：根据选中分类显示对应设置面板
            Group {
                switch selectedSection {
                case .general:
                    GeneralSettingsView()
                case .shortcut:
                    ShortcutSettingsView()
                case .history:
                    HistorySettingsView()
                case .appearance:
                    AppearanceSettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(20)
        }
        .navigationSplitViewStyle(.balanced)
    }
}
