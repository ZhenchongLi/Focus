import SwiftUI

@main
struct FocusApp: App {
    static let version = "1.0.2"

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appDelegate)
                .frame(width: 400, height: 300)
                .fixedSize()
                .onAppear {
                    if let window = NSApp.windows.first {
                        window.delegate = appDelegate
                    }
                }
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
