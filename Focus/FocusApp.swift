import SwiftUI

@main
struct FocusApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appDelegate)
                .frame(width: 400, height: 300)
                .fixedSize()
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .commands {
            // Hide standard menu items
            CommandGroup(replacing: .newItem) {}
        }
    }
}
