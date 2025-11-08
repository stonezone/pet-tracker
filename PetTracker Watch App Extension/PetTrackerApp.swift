import SwiftUI
import WatchKit
import OSLog

#if os(watchOS)
import PetTrackerFeature

/// Main entry point for PetTracker Watch app
///
/// This is a minimal shell that imports the PetTrackerFeature package
/// and sets up the WatchKit app structure.
@main
struct PetTracker_Watch_App: App {

    /// Location provider instance for Watch GPS tracking
    @State private var locationProvider: WatchLocationProvider

    init() {
        Logger.ui.info("========================================")
        Logger.ui.info("PetTracker Watch app starting")
        Logger.ui.info("watchOS Version: \(WKInterfaceDevice.current().systemVersion)")
        Logger.ui.info("Device Model: \(WKInterfaceDevice.current().model)")
        Logger.ui.info("========================================")

        Logger.ui.debug("Creating WatchLocationProvider...")
        let provider = WatchLocationProvider()
        Logger.ui.debug("WatchLocationProvider created successfully")

        Logger.ui.debug("Initializing SwiftUI @State wrapper...")
        _locationProvider = State(initialValue: provider)
        Logger.ui.debug("@State wrapper initialized")

        Logger.ui.info("✅ Watch app initialization COMPLETE")
        Logger.ui.info("========================================")
    }

    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .environment(locationProvider)
        }
    }
}
#endif
