import SwiftUI

/// View that lists all tasks and provides controls to add or delete them.
struct TasksView: View {
    @EnvironmentObject private var dataStore: DataStore
    @State private var showingAddTask = false

    var body: some View {
        NavigationView {
            List {
                ForEach(dataStore.tasks) { task in
                    VStack(alignment: .leading) {
                        Text(task.title)
                            .font(.headline)
                        if let description = task.description, !description.isEmpty {
                            Text(description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        if let dueDate = task.dueDate {
                            Text("Due: " + dateFormatter.string(from: dueDate))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        if let memberID = task.assignedMemberID,
                           let member = dataStore.members.first(where: { $0.id == memberID }) {
                            Text("Assigned to: \(member.name)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onDelete(perform: dataStore.removeTask)
            }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(action: { showingAddTask = true }) {
                        Label("Add Task", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView(isPresented: $showingAddTask)
                    .environmentObject(dataStore)
            }
        }
    }

    /// A date formatter for displaying due dates.
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}
