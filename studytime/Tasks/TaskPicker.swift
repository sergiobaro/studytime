import SwiftUI

/// Chooses the task the clock is counting against, and opens the editor for
/// creating or deleting them.
///
/// The label carries the running total so the selected task's time is visible
/// without opening anything.
struct TaskPicker: View {
    let tasks: TaskList
    let theme: BackgroundTheme

    @State private var isEditing = false

    var body: some View {
        Menu {
            ForEach(tasks.tasks) { task in
                Button {
                    tasks.selectedTaskID = task.id
                } label: {
                    // A checkmark rather than a `Picker`, which would need the
                    // optional selection modelled as a sentinel case.
                    if task.id == tasks.selectedTaskID {
                        Label("\(task.name) — \(task.studiedTime)", systemImage: "checkmark")
                    } else {
                        Text("\(task.name) — \(task.studiedTime)")
                    }
                }
            }

            if !tasks.tasks.isEmpty {
                Divider()

                Button("No Task") {
                    tasks.selectedTaskID = nil
                }
            }

            Divider()

            Button(tasks.tasks.isEmpty ? "Add Task…" : "Edit Tasks…") {
                isEditing = true
            }
        } label: {
            label
        }
        // The system button chrome is drawn by AppKit and follows the system
        // appearance, not the window's theme, so the menu is drawn here
        // instead — same capsule as `ThemedSegmentedPicker`.
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .frame(maxWidth: 220)
        .sheet(isPresented: $isEditing) {
            TaskEditor(tasks: tasks)
        }
    }

    private var label: some View {
        HStack(spacing: 6) {
            Image(systemName: "checklist")
            Text(title)
                .lineLimit(1)
                .truncationMode(.tail)

            if let task = tasks.selectedTask {
                Spacer(minLength: 4)
                Text(task.studiedTime)
                    .monospacedDigit()
                    .foregroundStyle(theme.foreground.opacity(0.65))
            }

            Image(systemName: "chevron.down")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(theme.foreground.opacity(0.6))
        }
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(theme.foreground)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule(style: .continuous)
                .fill(theme.foreground.opacity(0.12))
        )
        .contentShape(Capsule(style: .continuous))
    }

    private var title: String {
        tasks.selectedTask?.name ?? "No Task"
    }
}

#Preview {
    let tasks = TaskList(store: InMemoryPreviewStore())
    tasks.add(named: "Maths")
    tasks.recordStudied(seconds: 4_210)
    tasks.add(named: "Reading")

    return TaskPicker(tasks: tasks, theme: .ocean)
        .padding()
        .background(BackgroundTheme.ocean.background)
}

/// Keeps previews out of the real `UserDefaults`.
private final class InMemoryPreviewStore: KeyValueStore {
    private var storage: [String: Any] = [:]

    func object(forKey key: String) -> Any? { storage[key] }

    func set(_ value: Any?, forKey key: String) {
        if let value { storage[key] = value } else { storage.removeValue(forKey: key) }
    }

    func removeObject(forKey key: String) { storage.removeValue(forKey: key) }
}
