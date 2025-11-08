import SwiftUI
import PetTrackerFeature
import OSLog

/// Main entry point for PetTracker iOS app
///
/// This is a minimal shell that imports the PetTrackerFeature package
/// and sets up the SwiftUI app structure.
@main
struct PetTrackerApp: App {

    /// Location manager instance (shared across views)
    @State private var locationManager: PetLocationManager

    init() {
        Logger.ui.info("iOS app starting")
        let manager = PetLocationManager()
        _locationManager = State(initialValue: manager)
        Logger.ui.info("iOS app initialized")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(locationManager)
        }
    }
}
