import ApplicationServices

/// 模拟键盘粘贴操作 - 用于从剪贴板历史记录中粘贴选中项
///
/// 通过 CGEvent 模拟 Cmd+V 按键序列，将已写入剪贴板的内容粘贴到当前活跃应用。
/// 需要在系统设置中授予辅助功能权限。
enum PasteSimulator {
    /// 模拟 Cmd+V 粘贴操作
    static func simulatePaste() {
        let source = CGEventSource(stateID: .hidSystemState)

        let cmdKey: UInt16 = 0x37  // Command 键的虚拟键码
        let vKey: UInt16 = 0x09    // V 键的虚拟键码

        // 构造按键事件序列：Cmd 按下 → V 按下 → V 松开 → Cmd 松开
        let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: cmdKey, keyDown: true)
        let vDown = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: true)
        let vUp = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: false)
        let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: cmdKey, keyDown: false)

        // 设置 Cmd 修饰键标志
        cmdDown?.flags = CGEventFlags.maskCommand
        vDown?.flags = CGEventFlags.maskCommand
        vUp?.flags = CGEventFlags.maskCommand

        // 按顺序发送事件
        cmdDown?.post(tap: CGEventTapLocation.cghidEventTap)
        vDown?.post(tap: CGEventTapLocation.cghidEventTap)
        vUp?.post(tap: CGEventTapLocation.cghidEventTap)
        cmdUp?.post(tap: CGEventTapLocation.cghidEventTap)
    }
}
