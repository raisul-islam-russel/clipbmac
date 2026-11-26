import Cocoa
import SwiftUI
import Carbon.HIToolbox
import ServiceManagement
import CryptoKit

// MARK: - Model

struct ClipItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var text: String?
    var imageFile: String?
    var date = Date()
    var pinned = false
}

final class Store: ObservableObject {
    static let shared = Store()
    @Published var items: [ClipItem] = []
    @Published var query = ""
    @Published var selected = 0
    let maxUnpinned = 50
    let dir: URL
    let imageCache = NSCache<NSString, NSImage>()
    private var file: URL { dir.appendingPathComponent("history.json") }

    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        dir = base.appendingPathComponent("ClipBMac", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        if let d = try? Data(contentsOf: file),
           let arr = try? JSONDecoder().decode([ClipItem].self, from: d) {
            items = arr
        }
    }

    var visible: [ClipItem] {
        let sorted = items.sorted { a, b in
            if a.pinned != b.pinned { return a.pinned }
            return a.date > b.date
        }
        let q = query.trimmingCharacters(in: .whitespaces)
        if q.isEmpty { return sorted }
        return sorted.filter { ($0.text ?? "").localizedCaseInsensitiveContains(q) }
    }

    func clampSelection() {
        let n = visible.count
        if n == 0 { selected = 0 } else { selected = min(max(selected, 0), n - 1) }
    }

    func save() {
        if let d = try? JSONEncoder().encode(items) { try? d.write(to: file, options: .atomic) }
    }

    func add(text: String) {
        if let i = items.firstIndex(where: { $0.text == text }) {
            items[i].date = Date()
        } else {
            items.append(ClipItem(text: text))
        }
        trim(); save()
    }

    func add(imagePNG data: Data) {
        let hash = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        let name = String(hash.prefix(24)) + ".png"
        if let i = items.firstIndex(where: { $0.imageFile == name }) {
            items[i].date = Date()
        } else {
            try? data.write(to: dir.appendingPathComponent(name))
            items.append(ClipItem(imageFile: name))
        }
        trim(); save()
    }

    func touch(_ id: UUID) {
        if let i = items.firstIndex(where: { $0.id == id }) { items[i].date = Date(); save() }
    }

    func togglePin(_ id: UUID) {
        if let i = items.firstIndex(where: { $0.id == id }) { items[i].pinned.toggle(); save() }
    }

    func remove(_ id: UUID) {
        if let i = items.firstIndex(where: { $0.id == id }) {
            removeFile(items[i]); items.remove(at: i); save(); clampSelection()
        }
    }

    func clearUnpinned() {
        for it in items where !it.pinned { removeFile(it) }
        items.removeAll { !$0.pinned }
        save(); clampSelection()
    }

    private func removeFile(_ it: ClipItem) {
        if let f = it.imageFile {
            try? FileManager.default.removeItem(at: dir.appendingPathComponent(f))
            imageCache.removeObject(forKey: f as NSString)
        }
    }

    private func trim() {
        let unpinned = items.filter { !$0.pinned }.sorted { $0.date > $1.date }
        if unpinned.count > maxUnpinned {
            for it in unpinned.dropFirst(maxUnpinned) {
                removeFile(it)
                items.removeAll { $0.id == it.id }
            }
        }
    }

    func image(for it: ClipItem) -> NSImage? {
        guard let f = it.imageFile else { return nil }
        if let c = imageCache.object(forKey: f as NSString) { return c }
        guard let img = NSImage(contentsOf: dir.appendingPathComponent(f)) else { return nil }
        imageCache.setObject(img, forKey: f as NSString)
        return img
    }
}

// MARK: - Hotkey (Carbon, no permission needed)

struct Preset {
    let name: String
    let key: UInt32
    let mods: UInt32
}

let presets: [Preset] = [
    Preset(name: "⌘⇧V", key: UInt32(kVK_ANSI_V), mods: UInt32(cmdKey | shiftKey)),
    Preset(name: "⌥B",  key: UInt32(kVK_ANSI_B), mods: UInt32(optionKey)),
    Preset(name: "⌃⌥V", key: UInt32(kVK_ANSI_V), mods: UInt32(controlKey | optionKey)),
    Preset(name: "⌘⌥V", key: UInt32(kVK_ANSI_V), mods: UInt32(cmdKey | optionKey)),
]

enum HotKey {
    static var ref: EventHotKeyRef?
    static var installed = false
    static var action: (() -> Void)?

    static func register(_ p: Preset) {
        if let r = ref { UnregisterEventHotKey(r); ref = nil }
        if !installed {
            var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                     eventKind: UInt32(kEventHotKeyPressed))
            InstallEventHandler(GetApplicationEventTarget(), { _, _, _ -> OSStatus in
                HotKey.action?()
                return noErr
            }, 1, &spec, nil, nil)
            installed = true
        }
        let id = EventHotKeyID(signature: OSType(0x434C4950), id: 1)
        RegisterEventHotKey(p.key, p.mods, id, GetApplicationEventTarget(), 0, &ref)
    }
}

// MARK: - UI

struct VisualEffect: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = .popover
        v.blendingMode = .behindWindow
        v.state = .active
        return v
    }
    func updateNSView(_ v: NSVisualEffectView, context: Context) {}
}

func previewText(_ t: String) -> String {
    let s = t.trimmingCharacters(in: .whitespacesAndNewlines)
    return String(s.prefix(220))
}

struct Row: View {
    let item: ClipItem
    let selected: Bool
    @ObservedObject var store: Store
    let onPick: (ClipItem) -> Void
    @State private var hover = false

    var body: some View {
        HStack(spacing: 8) {
            if let img = store.image(for: item) {
                Image(nsImage: img)
                    .resizable().scaledToFit()
                    .frame(maxWidth: 220, maxHeight: 56, alignment: .leading)
                    .cornerRadius(4)
            } else if let t = item.text {
                Text(previewText(t))
                    .font(.system(size: 13))
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Spacer(minLength: 4)
            if hover || item.pinned {
                Button { store.togglePin(item.id) } label: {
                    Image(systemName: item.pinned ? "pin.fill" : "pin")
                        .foregroundColor(item.pinned ? .accentColor : .secondary)
                }.buttonStyle(.plain)
            }
            if hover {
                Button { store.remove(item.id) } label: {
                    Image(systemName: "xmark").foregroundColor(.secondary)
                }.buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(selected ? Color.accentColor.opacity(0.28)
                               : (hover ? Color.primary.opacity(0.07) : Color.clear))
        )
        .contentShape(Rectangle())
        .onHover { hover = $0 }
        .onTapGesture { onPick(item) }
    }
}

struct HistoryView: View {
    @ObservedObject var store: Store
    let onPick: (ClipItem) -> Void

    var body: some View {
        let list = store.visible
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                Text(store.query.isEmpty ? "Type to search" : store.query)
                    .foregroundColor(store.query.isEmpty ? .secondary : .primary)
                    .lineLimit(1)
                Spacer()
                Text("ClipBMac").font(.system(size: 10, weight: .semibold)).foregroundColor(.secondary)
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
            Divider()
            if list.isEmpty {
                Spacer()
                Text(store.query.isEmpty ? "Nothing copied yet" : "No matches")
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 2) {
                            ForEach(Array(list.enumerated()), id: \.element.id) { idx, it in
                                Row(item: it, selected: idx == store.selected, store: store, onPick: onPick)
                                    .id(it.id)
                            }
                        }
                        .padding(6)
                    }
                    .onChange(of: store.selected) { _ in
                        let l = store.visible
                        if store.selected >= 0 && store.selected < l.count {
                            proxy.scrollTo(l[store.selected].id)
                        }
                    }
                }
            }
            Divider()
            Text("↑↓ choose   ⏎ paste   ⌘P pin   ⌘⌫ delete   esc close")
                .font(.system(size: 10)).foregroundColor(.secondary)
                .padding(.vertical, 6)
        }
        .frame(width: 380, height: 480)
        .background(VisualEffect())
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

final class Panel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

// MARK: - App

final class AppDelegate: NSObject, NSApplicationDelegate {
    let store = Store.shared
    var statusItem: NSStatusItem!
    var panel: Panel!
    var timer: Timer?
    var lastChange = NSPasteboard.general.changeCount
    var paused = false
    var keyMonitor: Any?
    var clickMonitor: Any?

    var presetIndex: Int {
        get {
            let i = UserDefaults.standard.integer(forKey: "preset")
            return (0..<presets.count).contains(i) ? i : 0
        }
        set { UserDefaults.standard.set(newValue, forKey: "preset") }
    }

    func applicationDidFinishLaunching(_ n: Notification) {
        setupPanel()
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "ClipBMac")
        buildMenu()

        HotKey.action = { [weak self] in self?.toggle() }
        HotKey.register(presets[presetIndex])

        timer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { [weak self] _ in self?.poll() }
        RunLoop.main.add(timer!, forMode: .common)

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] e in
            guard let self = self, self.panel.isVisible else { return e }
            return self.handleKey(e) ? nil : e
        }
        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.hide()
        }

        if !UserDefaults.standard.bool(forKey: "askedAX") {
            UserDefaults.standard.set(true, forKey: "askedAX")
            requestAccessibility()
        }
    }

    func setupPanel() {
        panel = Panel(contentRect: NSRect(x: 0, y: 0, width: 380, height: 480),
                      styleMask: [.borderless, .nonactivatingPanel],
                      backing: .buffered, defer: false)
        panel.isFloatingPanel = true
        panel.level = .popUpMenu
        panel.hidesOnDeactivate = false
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        let host = NSHostingView(rootView: HistoryView(store: store, onPick: { [weak self] in self?.pick($0) }))
        host.frame = NSRect(x: 0, y: 0, width: 380, height: 480)
        panel.contentView = host
    }

    // MARK: clipboard watching

    func poll() {
        let pb = NSPasteboard.general
        guard pb.changeCount != lastChange else { return }
        lastChange = pb.changeCount
        if paused { return }
        let types = (pb.types ?? []).map { $0.rawValue }
        if types.contains("org.nspasteboard.ConcealedType")
            || types.contains("org.nspasteboard.TransientType")
            || types.contains("org.nspasteboard.AutoGeneratedType") { return }
        if let s = pb.string(forType: .string),
           !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            store.add(text: s)
        } else if let d = pb.data(forType: .png), d.count < 25_000_000 {
            store.add(imagePNG: d)
        } else if let t = pb.data(forType: .tiff), t.count < 25_000_000,
                  let rep = NSBitmapImageRep(data: t),
                  let png = rep.representation(using: .png, properties: [:]) {
            store.add(imagePNG: png)
        }
    }

    // MARK: show / hide / paste

    func toggle() { panel.isVisible ? hide() : show() }

    func show() {
        store.query = ""
        store.selected = 0
        let size = panel.frame.size
        let m = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(m, $0.frame, false) } ?? NSScreen.main ?? NSScreen.screens[0]
        let vf = screen.visibleFrame
        var x = m.x - size.width / 2
        var y = m.y - size.height - 8
        x = min(max(x, vf.minX + 8), vf.maxX - size.width - 8)
        y = min(max(y, vf.minY + 8), vf.maxY - size.height - 8)
        panel.setFrameOrigin(NSPoint(x: x, y: y))
        panel.makeKeyAndOrderFront(nil)
    }

    func hide() { panel.orderOut(nil) }

    func pick(_ item: ClipItem) {
        let pb = NSPasteboard.general
        pb.clearContents()
        if let t = item.text {
            pb.setString(t, forType: .string)
        } else if let img = store.image(for: item) {
            pb.writeObjects([img])
        }
        lastChange = pb.changeCount
        store.touch(item.id)
        hide()
        if AXIsProcessTrusted() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { self.sendPaste() }
        } else {
            requestAccessibility()
        }
    }

    func sendPaste() {
        let src = CGEventSource(stateID: .combinedSessionState)
        let down = CGEvent(keyboardEventSource: src, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true)
        let up = CGEvent(keyboardEventSource: src, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false)
        down?.flags = .maskCommand
        up?.flags = .maskCommand
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
    }

    func requestAccessibility() {
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(opts)
    }

    // MARK: keyboard inside the panel

    func handleKey(_ e: NSEvent) -> Bool {
        let flags = e.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let cmd = flags.contains(.command)
        let list = store.visible
        switch Int(e.keyCode) {
        case kVK_Escape:
            hide(); return true
        case kVK_UpArrow:
            store.selected = max(0, store.selected - 1); return true
        case kVK_DownArrow:
            store.selected = min(max(0, list.count - 1), store.selected + 1); return true
        case kVK_Return, kVK_ANSI_KeypadEnter:
            if store.selected < list.count { pick(list[store.selected]) }
            return true
        case kVK_Delete:
            if cmd {
                if store.selected < list.count { store.remove(list[store.selected].id) }
            } else if !store.query.isEmpty {
                store.query.removeLast(); store.selected = 0
            }
            return true
        case kVK_ANSI_P where cmd:
            if store.selected < list.count { store.togglePin(list[store.selected].id) }
            return true
        default:
            if cmd || flags.contains(.control) { return false }
            if let c = e.characters, !c.isEmpty,
               c.unicodeScalars.allSatisfy({ $0.value >= 32 && $0.value != 127 && !(0xF700...0xF8FF).contains($0.value) }) {
                store.query += c
                store.selected = 0
                return true
            }
            return false
        }
    }

    // MARK: menu bar

    func buildMenu() {
        let m = NSMenu()
        let show = NSMenuItem(title: "Show Clipboard  (\(presets[presetIndex].name))", action: #selector(menuShow), keyEquivalent: "")
        show.target = self
        m.addItem(show)
        m.addItem(.separator())

        let hk = NSMenuItem(title: "Hotkey", action: nil, keyEquivalent: "")
        let sub = NSMenu()
        for (i, p) in presets.enumerated() {
            let it = NSMenuItem(title: p.name, action: #selector(pickPreset(_:)), keyEquivalent: "")
            it.target = self; it.tag = i
            it.state = (i == presetIndex) ? .on : .off
            sub.addItem(it)
        }
        hk.submenu = sub
        m.addItem(hk)

        let pause = NSMenuItem(title: "Pause Recording", action: #selector(togglePause), keyEquivalent: "")
        pause.target = self; pause.state = paused ? .on : .off
        m.addItem(pause)

        let login = NSMenuItem(title: "Launch at Login", action: #selector(toggleLogin), keyEquivalent: "")
        login.target = self
        login.state = (SMAppService.mainApp.status == .enabled) ? .on : .off
        m.addItem(login)

        let ax = NSMenuItem(title: "Grant Auto-Paste Permission…", action: #selector(menuAX), keyEquivalent: "")
        ax.target = self
        m.addItem(ax)

        m.addItem(.separator())
        let clear = NSMenuItem(title: "Clear History (keeps pinned)", action: #selector(menuClear), keyEquivalent: "")
        clear.target = self
        m.addItem(clear)
        m.addItem(.separator())
        m.addItem(NSMenuItem(title: "Quit ClipBMac", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = m
    }

    @objc func menuShow() { show() }
    @objc func pickPreset(_ s: NSMenuItem) {
        presetIndex = s.tag
        HotKey.register(presets[s.tag])
        buildMenu()
    }
    @objc func togglePause() { paused.toggle(); buildMenu() }
    @objc func toggleLogin() {
        do {
            if SMAppService.mainApp.status == .enabled { try SMAppService.mainApp.unregister() }
            else { try SMAppService.mainApp.register() }
        } catch {}
        buildMenu()
    }
    @objc func menuAX() {
        if !AXIsProcessTrusted() { requestAccessibility() }
        if let u = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(u)
        }
    }
    @objc func menuClear() { store.clearUnpinned() }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
