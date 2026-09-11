import SwiftUI

@main
struct StudyTimeApp: App {
    #if os(macOS)
    init() {
        NSWindow.allowsAutomaticWindowTabbing = false
    }
    #endif

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
