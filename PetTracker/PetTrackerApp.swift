import SwiftUI
import PetTrackerFeature

/// Main entry point for PetTracker iOS app
///
/// This is a minimal shell that imports the PetTrackerFeature package
/// and sets up the SwiftUI app structure.
@main
struct PetTrackerApp: App {

    /// Location manager instance (shared across views)
    @State private var locationManager = PetLocationManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(locationManager)
        }
    }
}
