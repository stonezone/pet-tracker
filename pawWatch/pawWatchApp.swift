import SwiftUI
import pawWatchFeature

/// Main entry point for pawWatch iOS app
///
/// This is a minimal shell that imports the pawWatchFeature package
/// and sets up the SwiftUI app structure.
@main
struct pawWatchApp: App {

    /// Location manager instance (shared across views)
    @State private var locationManager = PetLocationManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(locationManager)
        }
    }
}
