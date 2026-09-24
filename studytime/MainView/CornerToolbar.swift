import SwiftUI

/// The row of icons in the window's top-right corner: the task editor, the
/// calendar, the history, exporting and importing the tasks, and the
/// appearance menu.
struct CornerToolbar: View {
    let tasks: TaskList
    @Binding var theme: BackgroundTheme
    /// Called after an import has replaced the tasks.
    var onRestore: () -> Void = {}

    @State private var isEditingTasks = false
    @State private var isShowingCalendar = false
    @State private var isShowingHistory = false
    @State private var backupAction: TaskBackupAction?

    var body: some View {
        HStack(spacing: 2) {
            CornerIconButton(
                systemImage: "checklist",
                title: "Edit Tasks",
                theme: theme,
                isActive: isEditingTasks
            ) {
                isEditingTasks = true
            }

            CornerIconButton(
                systemImage: "calendar",
                title: "Calendar",
                theme: theme,
                isActive: isShowingCalendar
            ) {
                isShowingCalendar = true
            }

            CornerIconButton(
                systemImage: "clock.arrow.circlepath",
                title: "Sessions history",
                theme: theme,
                isActive: isShowingHistory
            ) {
                isShowingHistory = true
            }

            CornerIconButton(
                systemImage: "square.and.arrow.up",
                title: "Export Data",
                theme: theme,
                isActive: backupAction == .export
            ) {
                backupAction = .export
            }
            .disabled(tasks.tasks.isEmpty)
            .opacity(tasks.tasks.isEmpty ? 0.4 : 1)

            CornerIconButton(
                systemImage: "square.and.arrow.down",
                title: "Import Data",
                theme: theme,
                isActive: backupAction == .import
            ) {
                backupAction = .import
            }

            AppearanceMenu(selection: $theme)
        }
        .sheet(isPresented: $isEditingTasks) {
            TaskEditor(tasks: tasks)
        }
        .sheet(isPresented: $isShowingHistory) {
            SessionHistoryView(tasks: tasks)
        }
        .sheet(isPresented: $isShowingCalendar) {
            SessionCalendarView(tasks: tasks, theme: theme)
        }
        .taskBackupTransfer(tasks: tasks, action: $backupAction, onRestore: onRestore)
    }
}
