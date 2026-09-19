import SwiftUI

/// The sessions recorded so far, grouped by day, newest first.
///
/// Left in the system appearance for the same reason as `TaskEditor`: it is a
/// standard list in its own sheet, not part of the timer window.
struct SessionHistoryView: View {
    let tasks: TaskList

    private var days: [SessionDay] {
        SessionHistory.days(from: tasks.tasks)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                SheetCloseButton()

                Text("History")
                    .font(.headline)
            }

            content
        }
        .padding()
        .frame(minWidth: 440, minHeight: 380)
    }

    @ViewBuilder
    private var content: some View {
        if days.isEmpty {
            VStack {
                Spacer()
                Text("No sessions yet. Start the timer with a task selected.")
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity)
        } else {
            List {
                ForEach(days) { day in
                    Section {
                        ForEach(day.sessions) { recorded in
                            row(for: recorded)
                        }
                    } header: {
                        header(for: day)
                    }
                }
            }
        }
    }

    private func header(for day: SessionDay) -> some View {
        HStack {
            Text(SessionHistory.title(for: day.date))
            Spacer()
            Text(day.totalSeconds.formatted(.clockTime))
                .monospacedDigit()
        }
    }

    private func row(for recorded: RecordedSession) -> some View {
        HStack(spacing: 12) {
            Text(recorded.taskName)
                .lineLimit(1)

            Spacer(minLength: 8)

            Text(SessionHistory.timeRange(of: recorded.session))
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Text(recorded.session.seconds.formatted(.clockTime))
                .monospacedDigit()
                // A fixed column so the durations line up down the list.
                .frame(minWidth: 64, alignment: .trailing)

            Button {
                tasks.removeSession(recorded.id)
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .help("Delete this session")
            .accessibilityLabel("Delete session on \(recorded.taskName)")
        }
    }
}

#Preview {
    SessionHistoryView(tasks: TaskList())
}
