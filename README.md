<div align="center">

# ClipBMac — Clipboard History Manager for macOS

**The Windows `Win + V` clipboard history, for your Mac.** Free, open source, minimal, and built with Swift + SwiftUI.

[![CI](https://github.com/raisul-islam-russel/clipbmac/actions/workflows/ci.yml/badge.svg)](https://github.com/raisul-islam-russel/clipbmac/actions/workflows/ci.yml)
[![Latest release](https://img.shields.io/github/v/release/raisul-islam-russel/clipbmac?label=download&color=blue)](https://github.com/raisul-islam-russel/clipbmac/releases/latest)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
![Platform](https://img.shields.io/badge/macOS-13%2B-black?logo=apple)
![Swift](https://img.shields.io/badge/Swift-5-orange?logo=swift)

[**Download**](https://github.com/raisul-islam-russel/clipbmac/releases/latest) · [Website](https://raisul-islam-russel.github.io/clipbmac/) · [Report a bug](https://github.com/raisul-islam-russel/clipbmac/issues/new?template=bug_report.yml) · [Request a feature](https://github.com/raisul-islam-russel/clipbmac/issues/new?template=feature_request.yml)

</div>

---

## What is ClipBMac?

macOS only remembers the *last* thing you copied. **ClipBMac** is a lightweight **clipboard manager for Mac** that keeps a searchable **clipboard history** of everything you copy (text and images). Press one hotkey, pick an item, and it is pasted straight into the app you were using — exactly like **Windows clipboard history (`Win + V`)**.

It lives in the menu bar, uses almost no resources, has no account, no tracking and no network access.

> Coming from Windows? ClipBMac is the macOS equivalent of the Windows 10/11 clipboard history panel.

## Features

- **Clipboard history on Mac** — text and images, last 50 items (pinned items are never removed)
- **Global hotkey** — default `⌘⇧V`; switch to `⌥B`, `⌃⌥V` or `⌘⌥V` from the menu
- **Auto-paste** — choose an item and it is pasted into the previous app instantly
- **Type to search** — start typing while the panel is open to filter your history
- **Pin items** you use all the time (email signatures, addresses, snippets)
- **Keyboard-first** — `↑ ↓` to move, `⏎` to paste, `⌘P` to pin, `⌘⌫` to delete, `esc` to close
- **Privacy-aware** — ignores items marked as concealed/transient by password managers; pause recording any time
- **Native & tiny** — pure Swift/AppKit/SwiftUI, universal binary (Apple Silicon + Intel), no dependencies
- **Launch at login** option, light/dark mode support
- **100% local** — history is stored only on your Mac

## Install

### Option 1 — Download the DMG (recommended)

1. Download `ClipBMac.dmg` from the [latest release](https://github.com/raisul-islam-russel/clipbmac/releases/latest).
2. Open it and drag **ClipBMac** into **Applications**.
3. Launch ClipBMac. A clipboard icon appears in the menu bar.
4. Grant **Accessibility** permission when asked (needed only for auto-paste).

> **First launch note:** ClipBMac is not notarized yet (that requires a paid Apple Developer account). If macOS says the app can't be opened, right-click the app → **Open**, or run:
> ```bash
> xattr -dr com.apple.quarantine /Applications/ClipBMac.app
> ```

### Option 2 — Build from source

Requirements: macOS 13+ and the Xcode Command Line Tools (`xcode-select --install`).

```bash
git clone https://github.com/raisul-islam-russel/clipbmac.git
cd clipbmac
bash scripts/build.sh
open build/ClipBMac.dmg
```

If the build asks you to accept the Xcode license, run `sudo xcodebuild -license accept` once.

## Usage

| Action | Shortcut |
| --- | --- |
| Open clipboard history | `⌘⇧V` (changeable) |
| Move selection | `↑` / `↓` |
| Paste selected item | `⏎` or click |
| Search | just start typing |
| Pin / unpin | `⌘P` |
| Delete item | `⌘⌫` |
| Close | `esc` or click outside |

Click the menu-bar icon to change the hotkey, pause recording, enable launch at login, or clear history.

## Permissions & privacy

- **Accessibility** — used only to send a `⌘V` keystroke after you pick an item. Without it, the item is still placed on your clipboard and you can paste manually.
- **No network.** ClipBMac never connects to the internet.
- History is saved in `~/Library/Application Support/ClipBMac/`. It is **not encrypted**, so use *Clear History* or *Pause Recording* before copying anything sensitive that your password manager doesn't already mark as concealed.

## FAQ

**Is there a Windows `Win + V` equivalent for Mac?**
macOS has no built-in clipboard history. ClipBMac gives you the same experience: one hotkey, a list of everything you copied, click to paste.

**Does it work on Apple Silicon and Intel Macs?**
Yes — the release is a universal binary. Requires macOS 13 Ventura or newer.

**Why does it need Accessibility permission?**
Only to simulate `⌘V` after you select an item. You can deny it and paste manually.

**Can I use `⌥B` as the hotkey?**
Yes, pick it under *Hotkey* in the menu-bar menu. Note that `⌥B` normally types "∫", which the hotkey will intercept.

**How is it different from Maccy, Raycast, Alfred or Paste?**
Those are great, mature tools. ClipBMac aims to stay tiny, dependency-free and Windows-`Win + V`-like, and it is MIT-licensed so you can fork and change anything. If you need advanced features today, try the established options.

## Roadmap

- [ ] Notarized, signed releases
- [ ] Homebrew cask (`brew install --cask clipbmac`)
- [ ] Custom hotkey recorder
- [ ] Rich text / file items
- [ ] Excluded apps list
- [ ] iCloud-free optional history encryption
- [ ] Configurable history size

Ideas and PRs welcome — see [CONTRIBUTING.md](CONTRIBUTING.md).

## Project structure

```
src/main.swift          App source (single file: model, hotkey, UI, menu bar)
scripts/build.sh        Builds the universal .app and .dmg
scripts/make_icon.swift Generates the app icon
docs/                   GitHub Pages landing page
.github/workflows/      CI and release automation
```

## Contributing

Bug reports, feature requests and pull requests are very welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) and the [Code of Conduct](CODE_OF_CONDUCT.md) first.

## License

[MIT](LICENSE) © 2026 Raisul Islam Russel

---

<sub>Keywords: macOS clipboard manager, clipboard history for Mac, Windows Win+V for Mac, copy paste history macOS, menu bar clipboard app, Swift SwiftUI open source utility.</sub>
