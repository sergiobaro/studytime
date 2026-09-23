import SwiftUI

/// A task's icon, as a button that opens `TaskStylePicker`.
///
/// Its own view so each row holds its own presentation state: `List` builds
/// rows outside the editor's body, where a binding reading the editor's
/// `@State` crashes.
struct TaskStyleButton: View {
    let task: StudyTask
    let tasks: TaskList

    @State private var isPresented = false

    var body: some View {
        Button {
            isPresented = true
        } label: {
            TaskIconView(icon: task.icon, color: task.color)
                .frame(width: 18)
        }
        .buttonStyle(.borderless)
        .help("Change icon and colour")
        .accessibilityLabel("Change icon and colour of \(task.name)")
        .popover(isPresented: $isPresented) {
            TaskStylePicker(task: task, tasks: tasks)
        }
    }
}

/// Chooses a task's icon and colour. Shown in a popover from the task's row
/// in `TaskEditor`, and applies each choice as it is made.
struct TaskStylePicker: View {
    let task: StudyTask
    let tasks: TaskList

    private let columns = Array(repeating: GridItem(.fixed(28), spacing: 8), count: 6)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Colour")
                .font(.subheadline.weight(.semibold))

            LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                ForEach(TaskColor.allCases) { color in
                    Button {
                        tasks.restyle(task.id, icon: task.icon, color: color)
                    } label: {
                        Circle()
                            .fill(color.color)
                            .frame(width: 20, height: 20)
                            .overlay {
                                if color == task.color {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }
                            .frame(width: 28, height: 28)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help(color.title)
                    .accessibilityLabel(color.title)
                    .accessibilityAddTraits(color == task.color ? .isSelected : [])
                }
            }

            Text("Icon")
                .font(.subheadline.weight(.semibold))

            LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                ForEach(TaskIcon.allCases) { icon in
                    Button {
                        tasks.restyle(task.id, icon: icon, color: task.color)
                    } label: {
                        Image(systemName: icon.systemImage)
                            .font(.system(size: 14))
                            .foregroundStyle(icon == task.icon ? Color.white : task.color.color)
                            .frame(width: 28, height: 28)
                            .background(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(icon == task.icon ? task.color.color : Color.secondary.opacity(0.12))
                            )
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help(icon.title)
                    .accessibilityLabel(icon.title)
                    .accessibilityAddTraits(icon == task.icon ? .isSelected : [])
                }
            }
        }
        .padding()
        .foregroundStyle(Color.primary)
    }
}
