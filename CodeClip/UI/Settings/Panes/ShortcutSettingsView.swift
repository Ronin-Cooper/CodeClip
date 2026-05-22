import SwiftUI
import AppKit

/// 快捷键设置面板
/// 包含：快捷键录入器，支持录制自定义快捷键组合
struct ShortcutSettingsView: View {
    @ObservedObject private var settings = SettingsManager.shared
    @State private var isRecording = false        // 是否处于录制模式
    @State private var localMonitor: Any?         // 本地键盘事件监听器

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("快捷键")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("呼出快捷键")
                            .font(.body)
                        Text("按下快捷键组合来显示/隐藏剪贴板面板")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // 快捷键录入按钮
                    Button(action: {
                        toggleRecording()
                    }) {
                        Text(isRecording ? "按下新快捷键..." : settings.hotKeyDisplayString)
                            .font(.system(.body, design: .monospaced))
                            .frame(minWidth: 100)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(isRecording ? Color.blue.opacity(0.1) : Color(NSColor.controlBackgroundColor))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(isRecording ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)

            Spacer()
        }
        .onDisappear {
            stopRecording()  // 离开页面时停止录制
        }
    }

    /// 切换录制状态
    private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    /// 开始录制快捷键
    /// 通过本地键盘事件监听器捕获按键，要求至少包含一个修饰键
    private func startRecording() {
        isRecording = true

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let flags = event.modifierFlags.intersection([.command, .shift, .control, .option])
            let keyCode = event.keyCode

            // 必须至少包含一个修饰键
            guard !flags.isEmpty else {
                return event
            }

            // ESC 键取消录制
            if keyCode == 53 {
                stopRecording()
                return nil
            }

            // 将 NSEvent 修饰键转换为 CGEventFlags 的 rawValue
            var cgFlags: UInt64 = 0
            if flags.contains(.command) { cgFlags |= CGEventFlags.maskCommand.rawValue }
            if flags.contains(.shift) { cgFlags |= CGEventFlags.maskShift.rawValue }
            if flags.contains(.control) { cgFlags |= CGEventFlags.maskControl.rawValue }
            if flags.contains(.option) { cgFlags |= CGEventFlags.maskAlternate.rawValue }

            settings.updateHotKey(modifiers: cgFlags, keyCode: Int(keyCode))
            stopRecording()
            return nil
        }
    }

    /// 停止录制
    private func stopRecording() {
        isRecording = false
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }
}
