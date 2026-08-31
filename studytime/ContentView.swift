import SwiftUI
import Combine

struct WindowInspector: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            view.window?.titlebarAppearsTransparent = true
            view.window?.titleVisibility = .hidden
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

struct ContentView: View {
    @AppStorage("durationMinutes") private var durationMinutes = 25
    @State private var remainingSeconds = 25 * 60
    @State private var isRunning = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var timeString: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var body: some View {
        VStack(spacing: 24) {
            Stepper("Duration: \(durationMinutes) min", value: $durationMinutes, in: 1...180)
                .disabled(isRunning)
                .onChange(of: durationMinutes) { _, newValue in
                    remainingSeconds = newValue * 60
                }
                .frame(maxWidth: 220)

            Text(timeString)
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .monospacedDigit()

            HStack(spacing: 16) {
                Button(isRunning ? "Pause" : "Start") {
                    isRunning.toggle()
                }
                .disabled(remainingSeconds == 0)

                Button("Reset") {
                    isRunning = false
                    remainingSeconds = durationMinutes * 60
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
        #if os(macOS)
        .background(WindowInspector())
        #endif
        .onAppear {
            remainingSeconds = durationMinutes * 60
        }
        .onReceive(timer) { _ in
            guard isRunning, remainingSeconds > 0 else { return }
            remainingSeconds -= 1
            if remainingSeconds == 0 {
                isRunning = false
            }
        }
    }
}

#Preview {
    ContentView()
}
