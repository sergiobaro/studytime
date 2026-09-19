import SwiftUI
import UniformTypeIdentifiers

enum TaskBackupAction {
    case export
    case `import`
}

/// The file dialogs behind the Export and Import buttons, and the
/// confirmation an import needs before it replaces everything.
struct TaskBackupTransfer: ViewModifier {
    let tasks: TaskList
    @Binding var action: TaskBackupAction?
    /// Called once a backup has replaced the tasks, so the clock can be reset
    /// rather than keep counting toward a task that may no longer exist.
    let onRestore: () -> Void

    @State private var pendingBackup: StudyTimeBackup?
    @State private var failure: Failure?

    func body(content: Content) -> some View {
        content
            .fileExporter(
                isPresented: isPresenting(.export),
                document: exportDocument,
                contentType: .studyTimeBackup,
                defaultFilename: defaultFilename
            ) { result in
                if case .failure(let error) = result {
                    failure = Failure(title: "Couldn't Export", message: error.localizedDescription)
                }
            }
            .fileImporter(
                isPresented: isPresenting(.import),
                // Plain JSON too, in case the extension was lost along the way.
                allowedContentTypes: [.studyTimeBackup, .json]
            ) { result in
                load(result)
            }
            .alert("Replace All Tasks?", isPresented: isConfirming, presenting: pendingBackup) { backup in
                Button("Replace", role: .destructive) { restore(backup) }
                Button("Cancel", role: .cancel) {}
            } message: { backup in
                Text(confirmationMessage(for: backup))
            }
            .alert(failure?.title ?? "", isPresented: isFailing, presenting: failure) { _ in
                Button("OK") {}
            } message: { failure in
                Text(failure.message)
            }
    }
}

private extension TaskBackupTransfer {

    struct Failure {
        let title: String
        let message: String
    }

    /// Built only while exporting, so the file holds the tasks as they are
    /// when the dialog opens.
    var exportDocument: StudyTimeBackupDocument? {
        guard action == .export else { return nil }
        return try? StudyTimeBackupDocument(data: tasks.backup().encoded())
    }

    var defaultFilename: String {
        "StudyTime Backup \(Date.now.formatted(.iso8601.year().month().day()))"
    }

    func isPresenting(_ requested: TaskBackupAction) -> Binding<Bool> {
        Binding(
            get: { action == requested },
            set: { isPresented in
                if !isPresented, action == requested { action = nil }
            }
        )
    }

    var isConfirming: Binding<Bool> {
        Binding(
            get: { pendingBackup != nil },
            set: { if !$0 { pendingBackup = nil } }
        )
    }

    var isFailing: Binding<Bool> {
        Binding(
            get: { failure != nil },
            set: { if !$0 { failure = nil } }
        )
    }

    /// Reads and checks the file before asking, so a bad file is reported
    /// straight away instead of after the user has agreed to lose their tasks.
    func load(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            // A file picked outside the sandbox is readable only while access is held.
            let isAccessing = url.startAccessingSecurityScopedResource()
            defer {
                if isAccessing { url.stopAccessingSecurityScopedResource() }
            }

            let backup = try StudyTimeBackup.decoded(from: Data(contentsOf: url))
            _ = try TaskList.validatedTasks(in: backup)
            pendingBackup = backup
        } catch {
            failure = Failure(title: "Couldn't Import", message: error.localizedDescription)
        }
    }

    func restore(_ backup: StudyTimeBackup) {
        do {
            try tasks.restore(backup)
            onRestore()
        } catch {
            failure = Failure(title: "Couldn't Import", message: error.localizedDescription)
        }
    }

    func confirmationMessage(for backup: StudyTimeBackup) -> String {
        let count = backup.tasks.count
        let incoming = count == 1 ? "1 task" : "\(count) tasks"
        let exported = backup.exportedAt.formatted(date: .abbreviated, time: .shortened)
        return "Your tasks and their history will be replaced by the \(incoming) "
            + "in this backup from \(exported), and the timer will be reset. "
            + "This can't be undone."
    }
}

/// `fileExporter` writes documents rather than raw data.
struct StudyTimeBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.studyTimeBackup] }

    let data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw StudyTimeBackupError.unreadable
        }
        self.data = data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

extension View {

    func taskBackupTransfer(
        tasks: TaskList,
        action: Binding<TaskBackupAction?>,
        onRestore: @escaping () -> Void
    ) -> some View {
        modifier(TaskBackupTransfer(tasks: tasks, action: action, onRestore: onRestore))
    }
}
