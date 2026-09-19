import SwiftUI

@main
struct StudyTimeApp: App {
    init() {
        #if os(macOS)
        NSWindow.allowsAutomaticWindowTabbing = false
        #endif
        SystemCountdownNotifier.shared.activate()
    }

    var body: some Scene {
        #if os(macOS)
        Window("StudyTime", id: "main") {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        #else
        WindowGroup {
            ContentView()
        }
        .commandsRemoved()
        #endif
    }
}
