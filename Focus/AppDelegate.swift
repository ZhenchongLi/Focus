import SwiftUI
import AppKit
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, ObservableObject {
    private var statusItem: NSStatusItem?

    // Handle window closing confirmation (non-blocking)
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // Only show confirmation for main window
        if sender == NSApp.windows.first {
            let alert = NSAlert()
            alert.messageText = "确定要退出专注计时器吗？"
            alert.informativeText = "退出后计时将停止"
            alert.addButton(withTitle: "退出")
            alert.addButton(withTitle: "取消")

            // Use weak reference to avoid retain cycle
            weak var weakWindow = sender
            alert.beginSheetModal(for: sender) { [weak self] response in
                if response == .alertFirstButtonReturn {
                    NSApp.terminate(nil)
                } else if let window = weakWindow {
                    // Keep window open if user cancels
                    DispatchQueue.main.async {
                        window.makeKeyAndOrderFront(nil)
                    }
                }
            }
            return false // Prevent automatic window closing
        }
        return true // Allow other windows to close normally
    }

    // Ensure app quits when terminated
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false // Let windowShouldClose handle termination
    }

    // Observable property to update menu bar title
    @Published var menuBarTitle: String = "专注计时器"

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        requestNotificationPermission()
    }

    func setupMenuBar() {
        // Create status item in menu bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.title = menuBarTitle
            button.action = #selector(focusMainWindow)
            button.target = self
        }

        // Setup application menu
        let appMenu = NSMenu()

        let aboutItem = NSMenuItem(title: "About Focus", action: #selector(showAboutWindow), keyEquivalent: "")
        aboutItem.target = self
        appMenu.addItem(aboutItem)

        let helpItem = NSMenuItem(title: "Help", action: #selector(openHelpWebsite), keyEquivalent: "")
        helpItem.target = self
        appMenu.addItem(helpItem)

        appMenu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApp.terminate), keyEquivalent: "q")
        appMenu.addItem(quitItem)

        statusItem?.menu = appMenu
    }

    private weak var aboutWindow: NSWindow?

    @objc func showAboutWindow() {
        if let existingWindow = aboutWindow {
            existingWindow.makeKeyAndOrderFront(nil)
            return
        }

        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 400),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        newWindow.center()
        newWindow.contentView = NSHostingView(rootView: AboutView())
        newWindow.delegate = self
        newWindow.isReleasedWhenClosed = false
        newWindow.makeKeyAndOrderFront(nil)
        aboutWindow = newWindow

        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: newWindow,
            queue: .main
        ) { [weak self] _ in
            self?.aboutWindow = nil
        }
    }

    @objc func openHelpWebsite() {
        NSWorkspace.shared.open(URL(string: "https://fists.cc/posts/products/focus/")!)
    }

    @objc func focusMainWindow() {
        // Activate app and bring main window to front
        NSApp.activate(ignoringOtherApps: true)

        // Safely handle window access
        guard let window = NSApp.windows.first else {
            // No windows exist - create new one if needed
            return
        }
        window.makeKeyAndOrderFront(nil)
    }

    // Update menu bar title
    func updateMenuBarTitle(_ title: String) {
        DispatchQueue.main.async { [weak self] in
            self?.menuBarTitle = title
            self?.statusItem?.button?.title = title
        }
    }

    // Request permission to send notifications
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
}
