import SwiftUI

/// The entry point for the FamilyApp application.
///
/// This struct conforms to the `App` protocol and sets up the
/// window group for the application. It instantiates a single
/// `DataStore` which is passed into the environment so that all
/// child views share the same state.
@main
struct FamilyAppApp: App {
    /// The shared data store for managing members, tasks and events.
    @StateObject private var dataStore = DataStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataStore)
        }
    }
}
