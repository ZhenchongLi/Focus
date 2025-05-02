import SwiftUI
import AppKit
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    private var statusItem: NSStatusItem?

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
        if let window = NSApp.windows.first {
            window.makeKeyAndOrderFront(nil)
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
