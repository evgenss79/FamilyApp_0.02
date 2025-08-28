import SwiftUI

/// View that presents a form for creating a new family member.
struct AddMemberView: View {
    @EnvironmentObject private var dataStore: DataStore
    @Binding var isPresented: Bool
    @State private var name: String = ""
    @State private var relationship: String = ""
    @State private var birthday: Date = Date()
    @State private var includeBirthday: Bool = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Basic Info")) {
                    TextField("Name", text: $name)
                    TextField("Relationship", text: $relationship)
                }
                Section(header: Text("Birthday")) {
                    Toggle("Include Birthday", isOn: $includeBirthday)
                    if includeBirthday {
                        DatePicker("Date", selection: $birthday, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("New Member")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: addMember)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || relationship.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    /// Constructs a new `FamilyMember` from the form fields and adds it to the data store.
    private func addMember() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedRelationship = relationship.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty, !trimmedRelationship.isEmpty else { return }
        let member = FamilyMember(id: UUID(), name: trimmedName, relationship: trimmedRelationship, birthday: includeBirthday ? birthday : nil)
        dataStore.addMember(member)
        isPresented = false
    }
}
