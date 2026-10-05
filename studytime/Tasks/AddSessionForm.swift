import SwiftUI

/// A button that opens `AddSessionForm` for a task.
///
/// Its own view for the same reason as `TaskStyleButton`: `List` builds rows
/// outside the editor's body, so each row holds its own presentation state.
struct AddSessionButton: View {
    let task: StudyTask
    let tasks: TaskList

    @State private var isPresented = false

    var body: some View {
        Button {
            isPresented = true
        } label: {
            Image(systemName: "calendar.badge.plus")
        }
        .buttonStyle(.borderless)
        .help("Add a session to \(task.name)")
        .accessibilityLabel("Add a session to \(task.name)")
        .popover(isPresented: $isPresented) {
            AddSessionForm(task: task, tasks: tasks) { isPresented = false }
        }
    }
}

/// Records a session studied away from the timer: when it started and how
/// long it lasted.
struct AddSessionForm: View {
    let task: StudyTask
    let tasks: TaskList
    let dismiss: () -> Void

    /// Defaults to a half-hour that has just finished, the most likely thing
    /// to be catching up on.
    @State private var startedAt = Self.defaultStart(minutes: 30)
    @State private var hours = 0
    @State private var minutes = 30

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add Session")
                .font(.headline)

            Form {
                DatePicker("Start", selection: $startedAt, displayedComponents: [.date, .hourAndMinute])

                LabeledContent("Duration") {
                    HStack(spacing: 12) {
                        durationField(value: $hours, range: 0...23, unit: "h")
                        durationField(value: $minutes, range: 0...59, unit: "min")
                    }
                }
            }

            HStack {
                Spacer()
                Button("Cancel", role: .cancel, action: dismiss)
                    .keyboardShortcut(.cancelAction)
                Button("Add", action: add)
                    .keyboardShortcut(.defaultAction)
                    .disabled(totalSeconds <= 0)
            }
        }
        .padding()
        .frame(width: 320)
        .foregroundStyle(Color.primary)
    }

    private func durationField(value: Binding<Int>, range: ClosedRange<Int>, unit: String) -> some View {
        HStack(spacing: 4) {
            // Labels hidden: inside a `Form` the title is drawn in front of
            // the field, eating the width meant for the number.
            TextField(unit, value: clamped(value, to: range), format: .number)
                .textFieldStyle(.roundedBorder)
                .labelsHidden()
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
                .frame(width: 44)
            Stepper(unit, value: value, in: range)
                .labelsHidden()
            Text(unit)
                .foregroundStyle(.secondary)
        }
    }

    /// Keeps a typed value inside the stepper's range, so "90 min" can't
    /// slip past it.
    private func clamped(_ value: Binding<Int>, to range: ClosedRange<Int>) -> Binding<Int> {
        Binding(
            get: { value.wrappedValue },
            set: { value.wrappedValue = min(max($0, range.lowerBound), range.upperBound) }
        )
    }

    private var totalSeconds: Int {
        (hours * 60 + minutes) * 60
    }

    private func add() {
        tasks.addSession(to: task.id, startedAt: startedAt, seconds: totalSeconds)
        dismiss()
    }

    /// Now, less the default duration, to the minute — the picker shows no
    /// seconds, so any left over would be invisible in the recorded time.
    private static func defaultStart(minutes: Int) -> Date {
        let start = Date().addingTimeInterval(-Double(minutes * 60))
        let calendar = Calendar.current
        return calendar.dateInterval(of: .minute, for: start)?.start ?? start
    }
}

#Preview {
    let tasks = TaskList()
    let task = StudyTask(name: "Maths")
    return AddSessionForm(task: task, tasks: tasks) {}
}
