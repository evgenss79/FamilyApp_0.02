import Foundation
import SwiftUI

/// A persistent data store that holds family members, tasks, and events.
///
/// The `DataStore` class manages three separate arrays of domain models
/// (`FamilyMember`, `Task`, and `FamilyEvent`) and synchronises them to
/// disk whenever modifications occur. It uses a simple JSON file stored
/// in the user's Application Support directory so that data persists
/// across app launches. Because it conforms to `ObservableObject`, its
/// published properties can be observed by SwiftUI views, automatically
/// triggering UI updates when the underlying data changes.
final class DataStore: ObservableObject {
    /// The list of family members currently in the data store.
    @Published var members: [FamilyMember] = []
    /// The list of tasks currently in the data store.
    @Published var tasks: [Task] = []
    /// The list of events currently in the data store.
    @Published var events: [FamilyEvent] = []

    /// The URL where the JSON file backing this data store is saved.
    private let fileURL: URL

    /// Creates a new data store and loads existing data from disk if available.
    init() {
        // Determine a directory inside Application Support for the app's data.
        let manager = FileManager.default
        let appSupport = manager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = appSupport.appendingPathComponent("FamilyApp", isDirectory: true)
        // Create the directory if it doesn't exist.
        try? manager.createDirectory(at: directory, withIntermediateDirectories: true)
        // Define the file URL for persisting the JSON data.
        self.fileURL = directory.appendingPathComponent("store.json")
        // Attempt to load any existing saved data.
        load()
    }

    /// A struct used to encode and decode the data store's contents in a single
    /// payload. This makes the on‑disk format simple and flexible.
    private struct SaveData: Codable {
        var members: [FamilyMember]
        var tasks: [Task]
        var events: [FamilyEvent]
    }

    /// Reads the JSON file and populates the published arrays. Any errors
    /// encountered are silently ignored so that corrupt data doesn't crash
    /// the application.
    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        do {
            let decoded = try JSONDecoder().decode(SaveData.self, from: data)
            members = decoded.members
            tasks = decoded.tasks
            events = decoded.events
        } catch {
            // If decoding fails, simply leave the arrays empty. In a real
            // application you might want to handle this more gracefully.
            members = []
            tasks = []
            events = []
        }
    }

    /// Persists the current state of all collections to disk. The data is
    /// encoded into JSON and written to the predefined file URL. Errors
    /// are silently ignored in favour of keeping the UI responsive.
    private func save() {
        let payload = SaveData(members: members, tasks: tasks, events: events)
        guard let data = try? JSONEncoder().encode(payload) else { return }
        try? data.write(to: fileURL)
    }

    // MARK: - Member operations

    /// Adds a new member to the data store and saves the change.
    func addMember(_ member: FamilyMember) {
        members.append(member)
        save()
    }

    /// Updates an existing member in the data store and saves the change.
    func updateMember(_ member: FamilyMember) {
        if let index = members.firstIndex(where: { $0.id == member.id }) {
            members[index] = member
            save()
        }
    }

    /// Removes members at the specified indexes from the data store and saves the change.
    func removeMember(at offsets: IndexSet) {
        members.remove(atOffsets: offsets)
        save()
    }

    // MARK: - Task operations

    /// Adds a new task to the data store and saves the change.
    func addTask(_ task: Task) {
        tasks.append(task)
        save()
    }

    /// Updates an existing task in the data store and saves the change.
    func updateTask(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
            save()
        }
    }

    /// Removes tasks at the specified indexes from the data store and saves the change.
    func removeTask(at offsets: IndexSet) {
        tasks.remove(atOffsets: offsets)
        save()
    }

    // MARK: - Event operations

    /// Adds a new event to the data store and saves the change.
    func addEvent(_ event: FamilyEvent) {
        events.append(event)
        save()
    }

    /// Updates an existing event in the data store and saves the change.
    func updateEvent(_ event: FamilyEvent) {
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index] = event
            save()
        }
    }

    /// Removes events at the specified indexes from the data store and saves the change.
    func removeEvent(at offsets: IndexSet) {
        events.remove(atOffsets: offsets)
        save()
    }
}
