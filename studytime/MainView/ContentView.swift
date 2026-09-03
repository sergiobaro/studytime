import SwiftUI
import Combine

struct ContentView: View {
    
    @State private var studyTimer = StudyTimer()
    @State private var appearance = AppearanceSettings()
    @State private var tasks = TaskList()

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 24) {
            TaskPicker(tasks: tasks, theme: appearance.theme)

            ThemedSegmentedPicker(
                options: TimerMode.allCases,
                selection: $studyTimer.mode,
                theme: appearance.theme,
                title: \.title
            )
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
                Button(startButtonTitle) {
                    studyTimer.toggle()
                }
                .disabled(!studyTimer.canStart)

                Button("Finish") {
                    studyTimer.reset()
                }
                .disabled(!studyTimer.isActive)
            }
            .buttonStyle(.bordered)

            BackgroundThemePicker(selection: $appearance.theme)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(appearance.theme.background.ignoresSafeArea())
        .foregroundStyle(appearance.theme.foreground)
        .onReceive(ticker) { _ in
            // Only a second the clock actually counted is credited, so a
            // paused or finished timer adds nothing to the task.
            if studyTimer.tick() {
                tasks.recordStudied(seconds: 1)
            }
        }
    }

    private var startButtonTitle: String {
        if studyTimer.isRunning { return "Pause" }
        return studyTimer.isPaused ? "Resume" : "Start"
    }
}

#Preview {
    ContentView()
}
