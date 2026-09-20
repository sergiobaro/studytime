import SwiftUI

/// Creates and deletes tasks, and shows what each has collected so far.
///
/// Left in the system appearance rather than themed: it is a standard form in
/// its own sheet, not part of the timer window.
struct TaskEditor: View {
    let tasks: TaskList

    @State private var newTaskName = ""
    @State private var pendingDeletionTask: StudyTask?
    /// The task whose row is currently a text field, and the name being typed
    /// into it. The draft is held here rather than written straight through so
    /// that Escape can abandon it.
    @State private var renamingTaskID: StudyTask.ID?
    @State private var draftName = ""
    @FocusState private var isNameFieldFocused: Bool
    @FocusState private var isRenameFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                SheetCloseButton()

                Text("Tasks")
                    .font(.headline)
            }

            HStack {
                TextField("New task", text: $newTaskName)
                    .textFieldStyle(.roundedBorder)
                    .focused($isNameFieldFocused)
                    .onSubmit(addTask)

                Button("Add", action: addTask)
                    .disabled(!canAdd)
            }

            list
        }
        .padding()
        .frame(minWidth: 340, minHeight: 320)
        // A sheet inherits the presenting view's foreground style, and the
        // task picker sits inside the themed stack — without this, a dark
        // theme's white text would land on the sheet's light background.
        // `Color.primary`, not `.primary`: the latter is the first level of
        // the inherited style, so it would resolve to that same white.
        .foregroundStyle(Color.primary)
        .alert("Delete Task?", isPresented: isConfirmingDeletion, presenting: pendingDeletionTask) { task in
            Button("Delete", role: .destructive) { tasks.remove(task.id) }
            Button("Cancel", role: .cancel) {}
        } message: { task in
            Text(deletionMessage(for: task))
        }
        .onAppear { isNameFieldFocused = true }
    }

    @ViewBuilder
    private var list: some View {
        if tasks.tasks.isEmpty {
            VStack {
                Spacer()
                Text("No tasks yet. Add one above.")
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity)
        } else {
            List {
                ForEach(tasks.tasks) { task in
                    row(for: task)
                }
            }
        }
    }

    @ViewBuilder
    private func row(for task: StudyTask) -> some View {
        if renamingTaskID == task.id {
            renameField(for: task)
        } else {
            HStack {
                Text(task.name)
                    .lineLimit(1)
                    // Double-click is the list-rename idiom; the pencil is
                    // there for anyone who doesn't think to try it.
                    .onTapGesture(count: 2) { beginRename(task) }

                Spacer(minLength: 8)

                Text(task.studiedTime)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)

                Button {
                    beginRename(task)
                } label: {
                    Image(systemName: "pencil")
                }
                .buttonStyle(.borderless)
                .help("Rename \(task.name)")
                .accessibilityLabel("Rename \(task.name)")

                Button {
                    pendingDeletionTask = task
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .help("Delete \(task.name)")
                .accessibilityLabel("Delete \(task.name)")
            }
        }
    }

    /// Replaces the whole row while it is being renamed, so the time and the
    /// trash button can't be clicked by mistake with the field open.
    private func renameField(for task: StudyTask) -> some View {
        TextField("Task name", text: $draftName)
            .textFieldStyle(.roundedBorder)
            .focused($isRenameFieldFocused)
            // Focus is taken once the field exists; asking for it in
            // `beginRename` would land before there is anything to focus.
            .onAppear { isRenameFieldFocused = true }
            .onSubmit { commitRename(task) }
            // Escape abandons the edit, and clicking away keeps it — both as
            // a Finder rename behaves.
            .onExitCommand { renamingTaskID = nil }
            .onChange(of: isRenameFieldFocused) { _, isFocused in
                if !isFocused, renamingTaskID == task.id { commitRename(task) }
            }
    }

    private func beginRename(_ task: StudyTask) {
        draftName = task.name
        renamingTaskID = task.id
    }

    /// Clears the row first, so the focus it gives up doesn't commit a second
    /// time. A blank, unchanged or duplicate name is rejected by `TaskList`,
    /// which leaves the task as it was.
    private func commitRename(_ task: StudyTask) {
        renamingTaskID = nil
        tasks.rename(task.id, to: draftName)
    }

    private var isConfirmingDeletion: Binding<Bool> {
        Binding(
            get: { pendingDeletionTask != nil },
            set: { if !$0 { pendingDeletionTask = nil } }
        )
    }

    /// Names the time about to go with the task: its total is the only part
    /// of a deletion that cannot be typed back in afterwards.
    private func deletionMessage(for task: StudyTask) -> String {
        guard task.studiedSeconds > 0 else {
            return "\"\(task.name)\" will be deleted. Nothing has been studied against it yet."
        }

        return "\(task.studiedSeconds.formatted(.compactDuration)) studied against "
            + "\"\(task.name)\" will be deleted along with its session history. "
            + "This can't be undone."
    }

    /// Blank names and repeats are rejected by `TaskList`; the button reflects
    /// that rather than letting a tap do nothing.
    private var canAdd: Bool {
        let trimmed = newTaskName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        return !tasks.tasks.contains {
            $0.name.localizedCaseInsensitiveCompare(trimmed) == .orderedSame
        }
    }

    private func addTask() {
        guard canAdd else { return }
        tasks.add(named: newTaskName)
        newTaskName = ""
        isNameFieldFocused = true
    }
}

#Preview {
    TaskEditor(tasks: TaskList())
}
