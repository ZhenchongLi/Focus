import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(nsImage: NSImage(named: "AppIcon")!)
                .resizable()
                .frame(width: 64, height: 64)

            Text("Focus")
                .font(.title)
                .bold()

            Text("Version 1.0.1")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Author: lizc")
                Text("Email: li.joe@outlook.com")
                Button(action: {
                    NSWorkspace.shared.open(URL(string: "https://fists.cc")!)
                }) {
                    Text("fists.cc")
                }
                .buttonStyle(PlainButtonStyle())
            }
            .font(.body)

            Button(action: {
                NSWorkspace.shared.open(URL(string: "https://fists.cc/posts/products/focus/")!)
            }) {
                Text("Help & Documentation")
            }

            Spacer()
        }
        .padding()
        .frame(width: 400, height: 400)
    }
}
