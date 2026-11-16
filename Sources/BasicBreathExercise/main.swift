import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let popover = NSPopover()
    private let session = BreathSession()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.action = #selector(togglePopover(_:))
            button.target = self
        }

        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(rootView: ContentView(session: session))

        session.onChange = { [weak self] in self?.updateStatusItem() }
        updateStatusItem()
    }

    @objc private func togglePopover(_ sender: Any?) {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    /// Egzersiz sırasında menü çubuğunda renkli nokta + kalan saniye gösterilir,
    /// böylece popover kapalıyken de takip edilebilir.
    private func updateStatusItem() {
        guard let button = statusItem.button else { return }
        let font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .medium)

        switch session.state {
        case .idle, .finished:
            let img = NSImage(systemSymbolName: "wind", accessibilityDescription: "Basic Breath Exercise")
            img?.isTemplate = true
            button.image = img
            button.attributedTitle = NSAttributedString(string: "")
            button.imagePosition = .imageOnly

        case .countdown(let n):
            button.image = nil
            button.attributedTitle = NSAttributedString(string: "⏱ \(n)", attributes: [.font: font])

        case .breathing(let phase, let remaining):
            button.image = nil
            let s = NSMutableAttributedString(
                string: "● ",
                attributes: [.foregroundColor: phase.nsColor, .font: NSFont.systemFont(ofSize: 15)]
            )
            s.append(NSAttributedString(string: "\(remaining)", attributes: [.font: font]))
            button.attributedTitle = s
        }
    }
}

MainActor.assumeIsolated {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.setActivationPolicy(.accessory) // Dock'ta görünmesin
    app.run()
}
