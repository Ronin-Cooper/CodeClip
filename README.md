# CodeClip

[![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue.svg)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange.svg)](https://swift.org/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

CodeClip 是一款轻量级的 macOS 剪贴板历史管理器，常驻菜单栏，帮助你轻松管理和复用复制过的内容。

## ✨ 功能特性

- **📋 剪贴板历史记录** - 自动记录复制的文本和图片，最多保存 500 条
- **⌨️ 全局快捷键** - 使用 `⌘+⇧+V` 快速呼出历史面板（可自定义）
- **📌 固定常用项** - 将重要内容固定在顶部，不会被自动清理
- **🎨 毛玻璃界面** - 采用 macOS 原生毛玻璃效果，美观流畅
- **⚡ 快速粘贴** - 点击历史项即可快速粘贴到任意应用
- **🔒 隐私保护** - 本地存储，不上传任何数据
- **🚀 开机自启** - 支持开机自动启动
- **🎯 灵活定位** - 支持屏幕居中、跟随光标、屏幕顶部三种定位方式
- **🧹 自动清理** - 可设置自动清理过期记录（1天/7天/30天）

## 📸 截图

![CodeClip Screenshot](doc/screenshot.png)

## 🚀 安装

### 方式一：从源码构建

```bash
# 克隆仓库
git clone https://github.com/yourusername/CodeClip.git
cd CodeClip

# 使用 Xcode 打开项目
open CodeClip.xcodeproj

# 在 Xcode 中按 Cmd+R 运行
```

### 方式二：下载预编译版本

前往 [Releases](https://github.com/yourusername/CodeClip/releases) 页面下载最新版本。

## ⚙️ 系统要求

- macOS 13.0 (Ventura) 或更高版本
- Apple Silicon (arm64) 或 Intel (x86_64)

## 🔐 权限说明

首次运行时需要授予以下权限：

1. **辅助功能权限**（必需）
   - 系统设置 → 隐私与安全性 → 辅助功能 → 添加 CodeClip
   - 用于监听全局快捷键和模拟粘贴操作

2. **剪贴板访问权限**（自动请求）
   - 用于读取和写入剪贴板内容

## 📖 使用说明

### 基本操作

1. **复制内容** - 像平常一样使用 `⌘+C` 复制
2. **呼出面板** - 按下 `⌘+⇧+V` 或点击菜单栏图标
3. **粘贴历史** - 点击任意历史项即可粘贴
4. **固定内容** - 悬停时点击图钉图标
5. **删除记录** - 悬停时点击垃圾桶图标

### 设置

点击菜单栏图标 → 设置，或按 `⌘+,` 打开设置面板：

- **通用** - 开机自启动
- **快捷键** - 自定义呼出快捷键
- **历史记录** - 设置最大记录数和自动清理时间
- **外观** - 设置面板显示位置

## 🛠 技术栈

- **语言**: Swift 5.9
- **框架**: SwiftUI + AppKit
- **最低支持**: macOS 13.0
- **架构**: Apple Silicon (arm64)

## 📁 项目结构

```
CodeClip/
├── CodeClipApp.swift           # 应用入口
├── Models/
│   ├── ClipboardItem.swift     # 剪贴板项模型
│   └── SettingsKey.swift       # 设置项定义
├── Services/
│   ├── ClipboardManager.swift  # 剪贴板管理器
│   ├── HotKeyManager.swift     # 快捷键管理器
│   ├── PasteSimulator.swift    # 粘贴模拟器
│   └── SettingsManager.swift   # 设置管理器
├── UI/
│   ├── ClipboardPanel.swift    # 主面板窗口
│   ├── ClipboardHistoryView.swift  # 历史列表视图
│   └── Settings/               # 设置界面
│       ├── SettingsWindow.swift
│       ├── SettingsView.swift
│       └── Panes/
└── Assets.xcassets/            # 资源文件
```

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

### 开发环境

1. 安装 Xcode 15.0 或更高版本
2. 克隆仓库
3. 打开 `CodeClip.xcodeproj`
4. 按 `Cmd+R` 运行

### 提交规范

```
feat: 新功能
fix: 修复 bug
docs: 文档更新
style: 代码格式
refactor: 重构
test: 测试
chore: 构建/工具
```

## 📄 许可证

本项目采用 GPLv3 许可证 - 详见 [LICENSE](LICENSE) 文件

## 🙏 致谢

- 灵感来源于 [Maccy](https://github.com/p0deje/Maccy) 和 [Paste](https://pasteapp.io/)
- 使用 [SwiftUI](https://developer.apple.com/xcode/swiftui/) 构建

## 📧 联系方式

- 作者: cooper
- 邮箱: cooper.hy.zhang@outlook.com

---

**CodeClip** - 让剪贴板管理更简单 🎉
