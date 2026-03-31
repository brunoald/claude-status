import SwiftUI

@main
struct ClaudeStatusApp: App {
    @StateObject private var statusManager = StatusManager()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(statusManager: statusManager)
        } label: {
            HStack(spacing: 4) {
                Image(nsImage: MenuBarIcon.circleImage(color: statusManager.statusNSColor))
                Text(statusManager.menuBarTitle)
                    .font(.system(size: 7))
            }
        }
        .menuBarExtraStyle(.window)
    }
}
