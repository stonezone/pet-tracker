import SwiftUI
import UIKit
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
        Logger.ui.info("========================================")
        Logger.ui.info("PetTracker iOS app starting")
        Logger.ui.info("iOS Version: \(UIDevice.current.systemVersion)")
        Logger.ui.info("Device Model: \(UIDevice.current.model)")
        Logger.ui.info("========================================")

        Logger.ui.debug("Creating PetLocationManager...")
        let manager = PetLocationManager()
        Logger.ui.debug("PetLocationManager created successfully")

        Logger.ui.debug("Initializing SwiftUI @State wrapper...")
        _locationManager = State(initialValue: manager)
        Logger.ui.debug("@State wrapper initialized")

        Logger.ui.info("✅ iOS app initialization COMPLETE")
        Logger.ui.info("========================================")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(locationManager)
        }
    }
}
