import SwiftUI

/// View that presents a form for creating a new task.
struct AddTaskView: View {
    @EnvironmentObject private var dataStore: DataStore
    @Binding var isPresented: Bool
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var dueDate: Date = Date()
    @State private var includeDueDate: Bool = false
    @State private var assignedMemberID: UUID?

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Details")) {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description)
                }
                Section(header: Text("Due Date")) {
                    Toggle("Include Due Date", isOn: $includeDueDate)
                    if includeDueDate {
                        DatePicker("Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }
                Section(header: Text("Assign To")) {
                    if dataStore.members.isEmpty {
                        Text("Add a family member to assign this task.")
                            .foregroundColor(.secondary)
                    } else {
                        Picker("Family Member", selection: $assignedMemberID) {
                            ForEach(dataStore.members) { member in
                                Text(member.name).tag(member.id as UUID?)
                            }
                        }
                        .pickerStyle(PopUpButtonPickerStyle())
                    }
                }
            }
            .navigationTitle("New Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: addTask)
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: updateDefaultAssignedMember)
            .onChange(of: dataStore.members.count) { _ in
                updateDefaultAssignedMember()
            }
        }
    }

    /// Constructs a new `Task` from the form fields and adds it to the data store.
    private func addTask() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        guard !trimmedTitle.isEmpty else { return }
        updateDefaultAssignedMember()
        let task = Task(
            id: UUID(),
            title: trimmedTitle,
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            dueDate: includeDueDate ? dueDate : nil,
            assignedMemberID: assignedMemberID
        )
        dataStore.addTask(task)
        isPresented = false
    }

    /// Ensures there is always a valid member selected when the list is non-empty.
    private func updateDefaultAssignedMember() {
        guard !dataStore.members.isEmpty else {
            assignedMemberID = nil
            return
        }

        if let currentID = assignedMemberID,
           dataStore.members.contains(where: { $0.id == currentID }) {
            return
        }

        assignedMemberID = dataStore.members.first?.id
    }
}
