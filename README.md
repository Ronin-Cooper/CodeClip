# CodeClip

[![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue.svg)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange.svg)](https://swift.org/)
[![License](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)

English | [中文](./README-CN.md)

CodeClip is a lightweight macOS clipboard history manager that lives in the menu bar, helping you easily manage and reuse copied content.

## ✨ Features

- **📋 Clipboard History** - Automatically records copied text and images, up to 500 items
- **⌨️ Global Hotkey** - Quickly summon the history panel with `⌘+⇧+V` (customizable)
- **📌 Pin Favorites** - Pin important items to the top so they won't be auto-cleaned
- **🎨 Frosted Glass UI** - Beautiful and smooth with native macOS frosted glass effects
- **⚡ Quick Paste** - Click any history item to quickly paste into any app
- **🔒 Privacy First** - All data stored locally, nothing is ever uploaded
- **🚀 Launch at Login** - Supports automatic startup on login
- **🎯 Flexible Positioning** - Three position options: centered, follow cursor, or top of screen
- **🧹 Auto Cleanup** - Configurable auto-cleanup for expired records (1 day / 7 days / 30 days)

## 📸 Screenshot

![CodeClip Screenshot](doc/screenshot.png)

## 🚀 Installation

### Option 1: Build from Source

```bash
# Clone the repository
git clone https://git.learny.dpdns.org/cooper/CodeClip.git
cd CodeClip

# Open the project with Xcode
open CodeClip.xcodeproj

# Press Cmd+R in Xcode to run
```

### Option 2: Download Pre-built Release

Visit the [Releases](https://git.learny.dpdns.org/cooper/CodeClip/releases) page to download the latest version.

## ⚙️ System Requirements

- macOS 13.0 (Ventura) or later
- Apple Silicon (arm64) or Intel (x86_64)

## 🔐 Permissions

The following permissions are required on first run:

1. **Accessibility** (Required)
   - System Settings → Privacy & Security → Accessibility → Add CodeClip
   - Used for listening to global hotkeys and simulating paste operations

2. **Clipboard Access** (Requested automatically)
   - Used for reading and writing clipboard content

## 📖 Usage

### Basic Operations

1. **Copy Content** - Use `⌘+C` to copy as usual
2. **Open Panel** - Press `⌘+⇧+V` or click the menu bar icon
3. **Paste History** - Click any history item to paste
4. **Pin Content** - Click the pin icon on hover
5. **Delete Record** - Click the trash icon on hover

### Settings

Click the menu bar icon → Settings, or press `⌘+,` to open the settings panel:

- **General** - Launch at login
- **Hotkeys** - Customize the summon hotkey
- **History** - Set max records and auto-cleanup interval
- **Appearance** - Set the panel position

## 🛠 Tech Stack

- **Language**: Swift 5.9
- **Framework**: SwiftUI + AppKit
- **Minimum Support**: macOS 13.0
- **Architecture**: Apple Silicon (arm64)

## 📁 Project Structure

```
CodeClip/
├── CodeClipApp.swift           # App entry point
├── Models/
│   ├── ClipboardItem.swift     # Clipboard item model
│   └── SettingsKey.swift       # Settings key definitions
├── Services/
│   ├── ClipboardManager.swift  # Clipboard manager
│   ├── HotKeyManager.swift     # Hotkey manager
│   ├── PasteSimulator.swift    # Paste simulator
│   └── SettingsManager.swift   # Settings manager
├── UI/
│   ├── ClipboardPanel.swift    # Main panel window
│   ├── ClipboardHistoryView.swift  # History list view
│   └── Settings/               # Settings UI
│       ├── SettingsWindow.swift
│       ├── SettingsView.swift
│       └── Panes/
└── Assets.xcassets/            # Asset files
```

## 🤝 Contributing

Issues and Pull Requests are welcome!

### Development Setup

1. Install Xcode 15.0 or later
2. Clone the repository
3. Open `CodeClip.xcodeproj`
4. Press `Cmd+R` to run

### Commit Convention

```
feat: New feature
fix: Bug fix
docs: Documentation update
style: Code formatting
refactor: Refactoring
test: Tests
chore: Build/tooling
```

## 📄 License

This project is licensed under GPLv3 - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgements

- Inspired by [Maccy](https://github.com/p0deje/Maccy) and [Paste](https://pasteapp.io/)
- Built with [SwiftUI](https://developer.apple.com/xcode/swiftui/)

---

**CodeClip** - Making clipboard management simple 🎉
