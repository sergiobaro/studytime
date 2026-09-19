import SwiftUI
import Combine

struct ContentView: View {
    
    @State private var studyTimer = StudyTimer()
    @State private var appearance = AppearanceSettings()
    @State private var tasks = TaskList()
    @State private var countdownAlert = CountdownAlert()

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

            VStack(spacing: 4) {
                HStack(spacing: 12) {
                    // A matching empty slot on the left, so the clock stays
                    // centred whether or not the arrows are showing.
                    durationArrows.hidden()

                    Text(studyTimer.displayTime)
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .animation(.default, value: studyTimer.seconds)
                        // Greyed out while paused, so a stopped clock reads
                        // differently from a running one at a glance.
                        .foregroundStyle(appearance.theme.foreground.opacity(studyTimer.isPaused ? 0.4 : 1))
                        .animation(.default, value: studyTimer.isPaused)

                    durationArrows
                }

                // Always laid out and only faded in, so pausing or finishing
                // doesn't shift the buttons below.
                Text(pausedCaption)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .opacity(showsPausedCaption ? 1 : 0)
                    .accessibilityHidden(!showsPausedCaption)
            }

            HStack(spacing: 12) {
                Button(startButtonTitle) {
                    studyTimer.toggle()
                }
                .buttonStyle(ThemedButtonStyle(theme: appearance.theme, prominent: true))
                .disabled(!studyTimer.canStart)

                Button("Finish") {
                    studyTimer.reset()
                }
                .buttonStyle(ThemedButtonStyle(theme: appearance.theme))
                .disabled(!studyTimer.isActive)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(appearance.theme.background.ignoresSafeArea())
        .foregroundStyle(appearance.theme.foreground)
        // Anchored to the window rather than the stack, and on the trailing
        // side so it stays clear of the traffic lights. The hidden title bar
        // still reserves a safe area at the top, which the overlay reaches
        // into so the buttons sit in the corner rather than below it.
        .overlay(alignment: .topTrailing) {
            CornerToolbar(tasks: tasks, theme: $appearance.theme) {
                // The imported tasks replace the one the clock was counting for.
                studyTimer.reset()
            }
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
        // Finishing or resetting closes the run being recorded; pausing does
        // not, so a resumed session keeps its original start date.
        .onChange(of: studyTimer.isActive) { _, isActive in
            if !isActive { tasks.endSession() }
        }
        .onChange(of: studyTimer.isRunning) {
            countdownAlert.update(for: studyTimer)
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

    private var showsPausedCaption: Bool {
        studyTimer.isPaused || studyTimer.isFinished
    }

    private var pausedCaption: String {
        studyTimer.isFinished
            ? "Finished \(studyTimer.pausedTime) ago"
            : "Paused \(studyTimer.pausedTime)"
    }

    private var startButtonTitle: String {
        if studyTimer.isRunning { return "Pause" }
        return studyTimer.isPaused ? "Resume" : "Start"
    }
}

#Preview {
    ContentView()
}
