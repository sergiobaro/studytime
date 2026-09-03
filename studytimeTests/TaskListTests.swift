import Foundation
import Testing
@testable import studytime

struct TaskListTests {

    let store: InMemoryKeyValueStore
    let tasks: TaskList

    /// Swift Testing builds a fresh instance per test, so each case gets its
    /// own empty store.
    init() {
        self.store = InMemoryKeyValueStore()
        self.tasks = TaskList(store: store)
    }

    @Test func anEmptyStoreStartsWithNoTasks() {
        #expect(tasks.tasks.isEmpty)
        #expect(tasks.selectedTask == nil)
    }

    @Test func addingATaskSelectsIt() {
        let task = tasks.add(named: "Maths")

        #expect(tasks.tasks.map(\.name) == ["Maths"])
        #expect(tasks.selectedTask == task)
        #expect(task?.studiedSeconds == 0)
    }

    @Test func aBlankNameIsRejected() {
        #expect(tasks.add(named: "   \n ") == nil)
        #expect(tasks.tasks.isEmpty)
    }

    @Test func aNameIsTrimmedAndCapped() {
        let padded = tasks.add(named: "  Reading  ")
        #expect(padded?.name == "Reading")

        let long = tasks.add(named: String(repeating: "a", count: 200))
        #expect(long?.name.count == TaskList.maxNameLength)
    }

    @Test func aDuplicateNameIsRejectedRegardlessOfCase() {
        tasks.add(named: "Maths")

        #expect(tasks.add(named: "maths") == nil)
        #expect(tasks.tasks.count == 1)
    }

    @Test func selectingAnUnknownIdClearsTheSelection() {
        tasks.add(named: "Maths")

        tasks.selectedTaskID = UUID()
        #expect(tasks.selectedTask == nil)
    }

    @Test func studiedTimeGoesToTheSelectedTask() {
        tasks.add(named: "Maths")
        let reading = tasks.add(named: "Reading")

        tasks.recordStudied(seconds: 30)
        tasks.recordStudied(seconds: 12)

        #expect(tasks.selectedTask?.id == reading?.id)
        #expect(tasks.selectedTask?.studiedSeconds == 42)
        // The unselected task collected nothing.
        #expect(tasks.tasks.first?.studiedSeconds == 0)
    }

    @Test func studiedTimeWithNoSelectionIsDropped() {
        tasks.add(named: "Maths")
        tasks.selectedTaskID = nil

        tasks.recordStudied(seconds: 30)

        #expect(tasks.tasks.first?.studiedSeconds == 0)
    }

    @Test func removingTheSelectedTaskClearsTheSelection() {
        let maths = tasks.add(named: "Maths")!

        tasks.remove(maths.id)

        #expect(tasks.tasks.isEmpty)
        #expect(tasks.selectedTask == nil)
    }

    @Test func removingAnotherTaskLeavesTheSelectionAlone() {
        let maths = tasks.add(named: "Maths")!
        let reading = tasks.add(named: "Reading")!

        tasks.remove(maths.id)

        #expect(tasks.selectedTask?.id == reading.id)
    }

    @Test func renamingKeepsTheCollectedTime() {
        let maths = tasks.add(named: "Maths")!
        tasks.recordStudied(seconds: 90)

        #expect(tasks.rename(maths.id, to: "Algebra"))
        #expect(tasks.selectedTask?.name == "Algebra")
        #expect(tasks.selectedTask?.studiedSeconds == 90)
    }

    @Test func renamingOntoAnotherTaskIsRejected() {
        tasks.add(named: "Maths")
        let reading = tasks.add(named: "Reading")!

        #expect(!tasks.rename(reading.id, to: "maths"))
        #expect(tasks.tasks.map(\.name) == ["Maths", "Reading"])
    }

    @Test func tasksAndSelectionSurviveRelaunch() {
        tasks.add(named: "Maths")
        let reading = tasks.add(named: "Reading")!
        tasks.recordStudied(seconds: 75)

        // A second list over the same store stands in for a relaunch.
        let relaunched = TaskList(store: store)

        #expect(relaunched.tasks.map(\.name) == ["Maths", "Reading"])
        #expect(relaunched.selectedTask?.id == reading.id)
        #expect(relaunched.selectedTask?.studiedSeconds == 75)
    }

    @Test func aSelectionNamingNoTaskIsDroppedOnLoad() {
        tasks.add(named: "Maths")
        store.set(UUID().uuidString, forKey: "selectedTaskID")

        let loaded = TaskList(store: store)

        #expect(loaded.tasks.count == 1)
        #expect(loaded.selectedTask == nil)
    }

    @Test func unreadableStoredTasksFallBackToAnEmptyList() {
        let loaded = TaskList(store: InMemoryKeyValueStore(["tasks": "not json"]))

        #expect(loaded.tasks.isEmpty)
        #expect(loaded.selectedTask == nil)
    }
}
