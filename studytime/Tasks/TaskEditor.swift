import SwiftUI

/// Creates and deletes tasks, and shows what each has collected so far.
///
/// Left in the system appearance rather than themed: it is a standard form in
/// its own sheet, not part of the timer window.
struct TaskEditor: View {
    let tasks: TaskList

    @State private var newTaskName = ""
    @FocusState private var isNameFieldFocused: Bool

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

    private func row(for task: StudyTask) -> some View {
        HStack {
            Text(task.name)
                .lineLimit(1)

            Spacer(minLength: 8)

            Text(task.studiedTime)
                .monospacedDigit()
                .foregroundStyle(.secondary)

            Button {
                tasks.remove(task.id)
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .help("Delete \(task.name)")
            .accessibilityLabel("Delete \(task.name)")
        }
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
