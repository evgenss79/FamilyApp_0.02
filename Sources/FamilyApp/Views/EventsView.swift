import SwiftUI

/// View that lists all family events and provides controls to add or delete them.
struct EventsView: View {
    @EnvironmentObject private var dataStore: DataStore
    @State private var showingAddEvent = false

    var body: some View {
        NavigationView {
            List {
                ForEach(dataStore.events) { event in
                    VStack(alignment: .leading) {
                        Text(event.title)
                            .font(.headline)
                        Text(dateFormatter.string(from: event.date))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        if let description = event.description, !description.isEmpty {
                            Text(description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onDelete(perform: dataStore.removeEvent)
            }
            .navigationTitle("Events")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(action: { showingAddEvent = true }) {
                        Label("Add Event", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddEvent) {
                AddEventView(isPresented: $showingAddEvent)
                    .environmentObject(dataStore)
            }
        }
    }

    /// A date formatter for displaying event dates.
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}
