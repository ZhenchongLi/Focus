import SwiftUI
import AppKit
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, ObservableObject {
    private var statusItem: NSStatusItem?

    // Handle window closing confirmation
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        let alert = NSAlert()
        alert.messageText = "确定要退出专注计时器吗？"
        alert.informativeText = "退出后计时将停止"
        alert.addButton(withTitle: "退出")
        alert.addButton(withTitle: "取消")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            NSApp.terminate(nil)
        }
        return false // Always prevent automatic window closing
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
    }

    @objc func focusMainWindow() {
        // Activate app and bring main window to front
        NSApp.activate(ignoringOtherApps: true)

        if NSApp.windows.isEmpty {
            // Recreate main window if none exists
            NSApp.windows.first?.makeKeyAndOrderFront(nil)
        } else {
            if let window = NSApp.windows.first {
                window.makeKeyAndOrderFront(nil)
            }
        }
    }

    // Update menu bar title
    func updateMenuBarTitle(_ title: String) {
        DispatchQueue.main.async {
            self.menuBarTitle = title
            self.statusItem?.button?.title = title
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
