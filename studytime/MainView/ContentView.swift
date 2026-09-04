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

            HStack(spacing: 12) {
                // A matching empty slot on the left, so the clock stays
                // centred whether or not the arrows are showing.
                durationArrows.hidden()

                Text(studyTimer.displayTime)
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.default, value: studyTimer.seconds)

                durationArrows
            }

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
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(appearance.theme.background.ignoresSafeArea())
        .foregroundStyle(appearance.theme.foreground)
        // Anchored to the window rather than the stack, and on the trailing
        // side so it stays clear of the traffic lights. The hidden title bar
        // still reserves a safe area at the top, which the overlay reaches
        // into so the button sits in the corner rather than below it.
        .overlay(alignment: .topTrailing) {
            AppearanceMenu(selection: $appearance.theme)
                .padding(.top, 6)
                .padding(.trailing, 10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .ignoresSafeArea(.container, edges: .top)
        }
        .onReceive(ticker) { _ in
            // Only a second the clock actually counted is credited, so a
            // paused or finished timer adds nothing to the task.
            if studyTimer.tick() {
                tasks.recordStudied(seconds: 1)
            }
        }
    }

    /// The countdown's duration arrows, in a fixed-width slot that is empty
    /// in stopwatch mode — a stopwatch has no duration to set.
    private var durationArrows: some View {
        Group {
            if studyTimer.mode == .countdown {
                ThemedStepper(
                    value: $studyTimer.durationMinutes,
                    range: StudyTimer.durationRange,
                    theme: appearance.theme,
                    label: "duration"
                )
                .disabled(studyTimer.isRunning)
            }
        }
        .frame(width: ThemedStepper.width)
    }

    private var startButtonTitle: String {
        if studyTimer.isRunning { return "Pause" }
        return studyTimer.isPaused ? "Resume" : "Start"
    }
}

#Preview {
    ContentView()
}
