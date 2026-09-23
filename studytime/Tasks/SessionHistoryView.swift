import SwiftUI

/// The sessions recorded so far, grouped by day, newest first.
///
/// Left in the system appearance for the same reason as `TaskEditor`: it is a
/// standard list in its own sheet, not part of the timer window.
struct SessionHistoryView: View {
    let tasks: TaskList

    /// The session the trash button asked about, kept until the alert is
    /// answered.
    @State private var pendingDeletion: RecordedSession?
    /// `nil` shows every task.
    @State private var filteredTaskID: StudyTask.ID?

    private var days: [SessionDay] {
        SessionHistory.days(from: tasks.tasks, matching: filter.wrappedValue)
    }

    private var filterOptions: [StudyTask] {
        SessionHistory.tasksWithSessions(in: tasks.tasks)
    }

    /// Normalised on the way out rather than reset with `onChange`: deleting
    /// the filtered task's last session takes it out of the options, and a
    /// selection naming a task that is no longer there would leave the menu
    /// blank and the list empty.
    private var filter: Binding<StudyTask.ID?> {
        Binding(
            get: { filterOptions.contains { $0.id == filteredTaskID } ? filteredTaskID : nil },
            set: { filteredTaskID = $0 }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                SheetCloseButton()

                Text("Sessions history")
                    .font(.headline)

                // Nothing to narrow down until at least one session exists.
                if !filterOptions.isEmpty {
                    Spacer(minLength: 16)
                    taskFilter
                }
            }

            content
        }
        .padding()
        .frame(minWidth: 440, minHeight: 380)
        .alert("Delete Session?", isPresented: isConfirmingDeletion, presenting: pendingDeletion) { recorded in
            Button("Delete", role: .destructive) { tasks.removeSession(recorded.id) }
            Button("Cancel", role: .cancel) {}
        } message: { recorded in
            Text(deletionMessage(for: recorded))
        }
    }

    private var isConfirmingDeletion: Binding<Bool> {
        Binding(
            get: { pendingDeletion != nil },
            set: { if !$0 { pendingDeletion = nil } }
        )
    }

    /// Names the time about to go, and where it goes from: a session's
    /// deletion also takes its time back out of the task's running total.
    ///
    /// `clockTime`, not the task alert's `compactDuration`: a session is
    /// minutes long, so dropping the seconds would both understate it and
    /// disagree with the row it was clicked from.
    private func deletionMessage(for recorded: RecordedSession) -> String {
        let studied = recorded.session.seconds.formatted(.clockTime)
        return "\(studied) studied against \"\(recorded.taskName)\" will be deleted, "
            + "and taken back out of the task's total. This can't be undone."
    }

    private var taskFilter: some View {
        Picker("Task", selection: filter) {
            Label {
                Text("All Tasks")
            } icon: {
                Image.menuSymbol("square.stack")
            }
            .tag(StudyTask.ID?.none)

            Divider()

            ForEach(filterOptions) { task in
                Label {
                    Text(task.name)
                } icon: {
                    task.menuIcon
                }
                .tag(StudyTask.ID?.some(task.id))
            }
        }
        .labelsHidden()
        .pickerStyle(.menu)
        .fixedSize()
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
            TaskIconView(icon: recorded.taskIcon, color: recorded.taskColor)
                .frame(width: 16)

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

            moveMenu(for: recorded)

            Button {
                pendingDeletion = recorded
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .help("Delete this session")
            .accessibilityLabel("Delete session on \(recorded.taskName)")
        }
    }

    /// Reassigns a session recorded against the wrong task. Offers every task
    /// but its own, not just those with sessions: the right one may not have
    /// any yet.
    private func moveMenu(for recorded: RecordedSession) -> some View {
        Menu {
            ForEach(tasks.tasks.filter { $0.id != recorded.taskID }) { task in
                Button {
                    tasks.moveSession(recorded.id, to: task.id)
                } label: {
                    Label {
                        Text(task.name)
                    } icon: {
                        task.menuIcon
                    }
                }
            }
        } label: {
            Image(systemName: "arrow.left.arrow.right")
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        // A task alone has nowhere to move its sessions to.
        .disabled(tasks.tasks.count < 2)
        .help("Move this session to another task")
        .accessibilityLabel("Move session on \(recorded.taskName) to another task")
    }
}

#Preview {
    SessionHistoryView(tasks: TaskList())
}
