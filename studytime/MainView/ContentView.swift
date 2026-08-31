import SwiftUI
import Combine

struct ContentView: View {
    
    @State private var studyTimer = StudyTimer()

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 24) {
            Picker("Mode", selection: $studyTimer.mode) {
                ForEach(TimerMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(maxWidth: 220)

            // Reserve the row so the window doesn't resize when the stepper hides.
            Group {
                if studyTimer.mode == .countdown {
                    Stepper(
                        "Duration: \(studyTimer.durationMinutes) min",
                        value: $studyTimer.durationMinutes,
                        in: StudyTimer.durationRange
                    )
                    .disabled(studyTimer.isRunning)
                    .frame(maxWidth: 220)
                }
            }
            .frame(height: 24)

            Text(studyTimer.displayTime)
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.default, value: studyTimer.seconds)

            HStack(spacing: 16) {
                Button(studyTimer.isRunning ? "Pause" : "Start") {
                    studyTimer.toggle()
                }
                .disabled(!studyTimer.canStart)

                Button("Reset") {
                    studyTimer.reset()
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .onReceive(ticker) { _ in
            studyTimer.tick()
        }
    }
}

#Preview {
    ContentView()
}
