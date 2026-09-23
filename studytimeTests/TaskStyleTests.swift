import Foundation
import Testing
@testable import studytime

struct TaskStyleTests {

    let store: InMemoryKeyValueStore
    let tasks: TaskList

    init() {
        self.store = InMemoryKeyValueStore()
        self.tasks = TaskList(store: store)
    }

    @Test func newTasksTakeTheFirstUnusedColour() {
        let maths = tasks.add(named: "Maths")
        let reading = tasks.add(named: "Reading")

        #expect(maths?.icon == .default)
        #expect(maths?.color == TaskColor.allCases[0])
        #expect(reading?.color == TaskColor.allCases[1])
    }

    @Test func aFreedColourIsReusedFirst() {
        let maths = tasks.add(named: "Maths")!
        tasks.add(named: "Reading")
        tasks.remove(maths.id)

        #expect(tasks.add(named: "History")?.color == maths.color)
    }

    @Test func oncePaletteIsFullColoursCarryOnRoundIt() {
        let used = TaskColor.allCases + [TaskColor.allCases[0]]

        #expect(TaskColor.next(after: TaskColor.allCases) == TaskColor.allCases[0])
        #expect(TaskColor.next(after: used) == TaskColor.allCases[1])
    }

    @Test func restylingChangesOnlyTheStyle() {
        let maths = tasks.add(named: "Maths")!
        tasks.recordStudied(seconds: 60)

        tasks.restyle(maths.id, icon: .function, color: .orange)

        let restyled = tasks.tasks.first
        #expect(restyled?.icon == .function)
        #expect(restyled?.color == .orange)
        #expect(restyled?.name == "Maths")
        #expect(restyled?.studiedSeconds == 60)
    }

    @Test func aStyleSurvivesRelaunch() {
        let maths = tasks.add(named: "Maths")!
        tasks.restyle(maths.id, icon: .flask, color: .teal)

        let relaunched = TaskList(store: store)
        #expect(relaunched.tasks.first?.icon == .flask)
        #expect(relaunched.tasks.first?.color == .teal)
    }

    @Test func tasksStoredWithoutAStyleStillLoad() {
        let legacy = """
        [{"id":"\(UUID().uuidString)","name":"Maths","studiedSeconds":4210}]
        """
        let loaded = TaskList(store: InMemoryKeyValueStore(["tasks": Data(legacy.utf8)]))

        #expect(loaded.tasks.first?.icon == .default)
        #expect(loaded.tasks.first?.color == .blue)
    }

    /// A backup from a newer app may name a style this one doesn't know; the
    /// task is kept with the default rather than the whole list lost.
    @Test func anUnknownStyleFallsBackToTheDefault() {
        let stored = """
        [{"id":"\(UUID().uuidString)","name":"Maths","studiedSeconds":0,"icon":"rocket","color":"chartreuse"}]
        """
        let loaded = TaskList(store: InMemoryKeyValueStore(["tasks": Data(stored.utf8)]))

        #expect(loaded.tasks.map(\.name) == ["Maths"])
        #expect(loaded.tasks.first?.icon == .default)
        #expect(loaded.tasks.first?.color == .blue)
    }

    @Test func theStyleIsCarriedIntoHistoryAndTheCalendar() {
        let maths = tasks.add(named: "Maths")!
        tasks.restyle(maths.id, icon: .function, color: .purple)
        tasks.recordStudied(seconds: 60)

        let recorded = SessionHistory.days(from: tasks.tasks).first?.sessions.first
        #expect(recorded?.taskIcon == .function)
        #expect(recorded?.taskColor == .purple)

        let month = SessionCalendar.month(containing: .now, from: tasks.tasks)
        let total = month.daysInMonth.flatMap(\.taskTotals).first
        #expect(total?.taskIcon == .function)
        #expect(total?.taskColor == .purple)
    }
}
