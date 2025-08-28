import SwiftUI

/// View that presents a form for creating a new event.
struct AddEventView: View {
    @EnvironmentObject private var dataStore: DataStore
    @Binding var isPresented: Bool
    @State private var title: String = ""
    @State private var date: Date = Date()
    @State private var description: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Event")) {
                    TextField("Title", text: $title)
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    TextField("Description", text: $description)
                }
            }
            .navigationTitle("New Event")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: addEvent)
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    /// Constructs a new `FamilyEvent` from the form fields and adds it to the data store.
    private func addEvent() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        guard !trimmedTitle.isEmpty else { return }
        let event = FamilyEvent(
            id: UUID(),
            title: trimmedTitle,
            date: date,
            description: description.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        dataStore.addEvent(event)
        isPresented = false
    }
}
