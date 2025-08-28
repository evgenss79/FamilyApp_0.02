import SwiftUI

/// The root view of the application.
///
/// This view displays a tab bar with three sections: family members,
/// tasks and events. Each tab is backed by its own view which is
/// responsible for presenting and manipulating the corresponding
/// collection within the `DataStore`.
struct ContentView: View {
    var body: some View {
        TabView {
            MembersView()
                .tabItem {
                    Label("Members", systemImage: "person.3")
                }
            TasksView()
                .tabItem {
                    Label("Tasks", systemImage: "checklist")
                }
            EventsView()
                .tabItem {
                    Label("Events", systemImage: "calendar")
                }
        }
        .frame(minWidth: 500, minHeight: 400)
    }
}

// SwiftUI previews for the root view. These previews do not depend on
// actual persisted data and instead provide an empty data store.
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(DataStore())
    }
}
