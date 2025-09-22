import SwiftUI

/// View that lists all family members and allows the user to add or delete them.
struct MembersView: View {
    @EnvironmentObject private var dataStore: DataStore
    @State private var showingAddMember = false

    var body: some View {
        NavigationView {
            List {
                ForEach(dataStore.members) { member in
                    VStack(alignment: .leading) {
                        Text(member.name)
                            .font(.headline)
                        Text(member.relationship)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        if let birthday = member.birthday {
                            Text("Birthday: " + dateFormatter.string(from: birthday))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onDelete(perform: dataStore.removeMember)
            }
            .navigationTitle("Family Members")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(action: { showingAddMember = true }) {
                        Label("Add Member", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddMember) {
                AddMemberView(isPresented: $showingAddMember)
                    .environmentObject(dataStore)
            }
        }
    }

    /// A shared date formatter used for displaying birthdays in a friendly way.
    private static let birthdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    private var dateFormatter: DateFormatter { Self.birthdayFormatter }
}
