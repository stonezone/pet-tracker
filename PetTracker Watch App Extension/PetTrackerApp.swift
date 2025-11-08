import SwiftUI

#if os(watchOS)
import PetTrackerFeature

/// Main entry point for PetTracker Watch app
///
/// This is a minimal shell that imports the PetTrackerFeature package
/// and sets up the WatchKit app structure.
@main
struct PetTracker_Watch_App: App {

    /// Location provider instance for Watch GPS tracking
    @State private var locationProvider = WatchLocationProvider()

    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .environment(locationProvider)
        }
    }
}
#endif
