import Foundation
import OSLog
#if os(iOS)
import UIKit
#elseif os(watchOS)
import WatchKit
#endif

/// Monitors application performance and battery metrics
///
/// This utility tracks critical performance indicators:
/// - GPS update latency (target: <500ms)
/// - WatchConnectivity message latency (target: <100ms)
/// - Memory usage (iOS <50MB, Watch <25MB)
/// - CPU usage (average <10%)
/// - Battery drain rate
///
/// ## Usage
/// ```swift
/// let monitor = PerformanceMonitor.shared
///
/// // Track GPS latency
/// let startTime = Date()
/// // ... GPS update received ...
/// monitor.recordGPSLatency(Date().timeIntervalSince(startTime))
///
/// // Track message latency
/// monitor.recordMessageSent(messageId: "123")
/// // ... message acknowledged ...
/// monitor.recordMessageReceived(messageId: "123")
///
/// // Check battery status
/// if monitor.isLowBattery {
///     // Reduce GPS frequency
/// }
/// ```
///
/// ## Performance Targets
/// - GPS latency: <500ms (95th percentile)
/// - WC message latency: <100ms (when reachable)
/// - Memory: iOS <50MB, Watch <25MB
/// - CPU: Average <10%
/// - Battery: >8 hours continuous GPS on Watch
@available(iOS 14.0, watchOS 7.0, macOS 11.0, *)
@MainActor
public final class PerformanceMonitor {

    // MARK: - Singleton

    public static let shared = PerformanceMonitor()

    // MARK: - Performance Metrics

    /// GPS update latency measurements (seconds)
    private var gpsLatencies: [TimeInterval] = []

    /// WatchConnectivity message latency measurements (seconds)
    private var messageLatencies: [TimeInterval] = []

    /// Pending message timestamps (for latency calculation)
    private var pendingMessages: [String: Date] = [:]

    /// Current memory usage in megabytes
    public private(set) var memoryUsageMB: Double = 0.0

    /// Current CPU usage percentage (0-100)
    public private(set) var cpuUsagePercent: Double = 0.0

    /// Current battery level (0.0-1.0)
    public private(set) var batteryLevel: Double = 1.0

    /// Battery drain rate (percent per hour)
    public private(set) var batteryDrainRate: Double = 0.0

    /// Last battery check timestamp
    private var lastBatteryCheck: Date = Date()

    /// Last battery level (for drain rate calculation)
    private var lastBatteryLevel: Double = 1.0

    // MARK: - Constants

    /// Maximum number of latency samples to keep
    private let maxLatencySamples = 100

    /// GPS latency target (500ms)
    public let gpsLatencyTarget: TimeInterval = 0.5

    /// Message latency target (100ms)
    public let messageLatencyTarget: TimeInterval = 0.1

    /// Memory target for iOS (50MB)
    public let memoryTargetMB_iOS: Double = 50.0

    /// Memory target for Watch (25MB)
    public let memoryTargetMB_Watch: Double = 25.0

    /// CPU target (10%)
    public let cpuTargetPercent: Double = 10.0

    /// Low battery threshold (20%)
    public let lowBatteryThreshold: Double = 0.20

    /// Critical battery threshold (10%)
    public let criticalBatteryThreshold: Double = 0.10

    // MARK: - Initialization

    private init() {
        setupMonitoring()
        updateBatteryLevel()
    }

    // MARK: - Setup

    private func setupMonitoring() {
        // Start periodic metrics collection
        Task {
            await startMetricsCollection()
        }

        // Setup battery monitoring
        #if os(iOS)
        UIDevice.current.isBatteryMonitoringEnabled = true
        NotificationCenter.default.addObserver(
            forName: UIDevice.batteryLevelDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.updateBatteryLevel()
            }
        }
        #elseif os(watchOS)
        WKInterfaceDevice.current().isBatteryMonitoringEnabled = true
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("WKInterfaceDeviceBatteryLevelDidChange"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.updateBatteryLevel()
            }
        }
        #endif
    }

    // MARK: - GPS Latency Tracking

    /// Records GPS update latency
    ///
    /// - Parameter latency: Time interval from GPS request to receipt (seconds)
    public func recordGPSLatency(_ latency: TimeInterval) {
        gpsLatencies.append(latency)

        // Keep only recent samples
        if gpsLatencies.count > maxLatencySamples {
            gpsLatencies.removeFirst()
        }

        // Log if exceeds target
        if latency > gpsLatencyTarget {
            Logger.performance.warning("GPS latency \(Int(latency * 1000))ms exceeds target \(Int(self.gpsLatencyTarget * 1000))ms")
        }

        Logger.performance.debug("GPS latency: \(Int(latency * 1000))ms")
    }

    /// Average GPS latency (seconds)
    public var averageGPSLatency: TimeInterval {
        guard !gpsLatencies.isEmpty else { return 0 }
        return gpsLatencies.reduce(0, +) / Double(gpsLatencies.count)
    }

    /// 95th percentile GPS latency (seconds)
    public var p95GPSLatency: TimeInterval {
        guard !gpsLatencies.isEmpty else { return 0 }
        let sorted = gpsLatencies.sorted()
        let index = Int(Double(sorted.count) * 0.95)
        return sorted[min(index, sorted.count - 1)]
    }

    // MARK: - Message Latency Tracking

    /// Records that a message was sent (start latency timer)
    ///
    /// - Parameter messageId: Unique identifier for the message
    public func recordMessageSent(messageId: String) {
        pendingMessages[messageId] = Date()
    }

    /// Records that a message was received/acknowledged (stop latency timer)
    ///
    /// - Parameter messageId: Unique identifier for the message
    public func recordMessageReceived(messageId: String) {
        guard let sentTime = pendingMessages.removeValue(forKey: messageId) else {
            Logger.performance.warning("Received message \(messageId) with no sent timestamp")
            return
        }

        let latency = Date().timeIntervalSince(sentTime)
        messageLatencies.append(latency)

        // Keep only recent samples
        if messageLatencies.count > maxLatencySamples {
            messageLatencies.removeFirst()
        }

        // Log if exceeds target
        if latency > messageLatencyTarget {
            Logger.performance.warning("Message latency \(Int(latency * 1000))ms exceeds target \(Int(self.messageLatencyTarget * 1000))ms")
        }

        Logger.performance.debug("Message latency: \(Int(latency * 1000))ms")
    }

    /// Average message latency (seconds)
    public var averageMessageLatency: TimeInterval {
        guard !messageLatencies.isEmpty else { return 0 }
        return messageLatencies.reduce(0, +) / Double(messageLatencies.count)
    }

    /// 95th percentile message latency (seconds)
    public var p95MessageLatency: TimeInterval {
        guard !messageLatencies.isEmpty else { return 0 }
        let sorted = messageLatencies.sorted()
        let index = Int(Double(sorted.count) * 0.95)
        return sorted[min(index, sorted.count - 1)]
    }

    // MARK: - Memory Tracking

    /// Updates current memory usage
    private func updateMemoryUsage() {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        if result == KERN_SUCCESS {
            let memoryBytes = Double(info.resident_size)
            memoryUsageMB = memoryBytes / 1024.0 / 1024.0

            #if os(iOS)
            let target = memoryTargetMB_iOS
            #else
            let target = memoryTargetMB_Watch
            #endif

            if memoryUsageMB > target {
                Logger.performance.warning("Memory usage \(Int(self.memoryUsageMB))MB exceeds target \(Int(target))MB")
            }

            Logger.performance.debug("Memory usage: \(Int(self.memoryUsageMB))MB")
        }
    }

    // MARK: - CPU Tracking

    /// Updates current CPU usage
    private func updateCPUUsage() {
        var threadList: thread_act_array_t?
        var threadCount: mach_msg_type_number_t = 0

        let result = task_threads(mach_task_self_, &threadList, &threadCount)

        guard result == KERN_SUCCESS, let threads = threadList else {
            return
        }

        var totalUsage: Double = 0

        for i in 0..<Int(threadCount) {
            var threadInfo = thread_basic_info()
            var threadInfoCount = mach_msg_type_number_t(THREAD_INFO_MAX)

            let infoResult = withUnsafeMutablePointer(to: &threadInfo) {
                $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                    thread_info(threads[i], thread_flavor_t(THREAD_BASIC_INFO), $0, &threadInfoCount)
                }
            }

            if infoResult == KERN_SUCCESS {
                let usage = Double(threadInfo.cpu_usage) / Double(TH_USAGE_SCALE) * 100.0
                totalUsage += usage
            }
        }

        let size = Int(threadCount) * MemoryLayout<thread_t>.stride
        vm_deallocate(mach_task_self_, vm_address_t(bitPattern: threads), vm_size_t(size))

        cpuUsagePercent = totalUsage

        if cpuUsagePercent > cpuTargetPercent {
            Logger.performance.warning("CPU usage \(Int(self.cpuUsagePercent))% exceeds target \(Int(self.cpuTargetPercent))%")
        }

        Logger.performance.debug("CPU usage: \(Int(self.cpuUsagePercent))%")
    }

    // MARK: - Battery Monitoring

    /// Updates current battery level and drain rate
    private func updateBatteryLevel() {
        let now = Date()
        let previousLevel = batteryLevel

        #if os(iOS)
        batteryLevel = Double(UIDevice.current.batteryLevel)
        #elseif os(watchOS)
        batteryLevel = Double(WKInterfaceDevice.current().batteryLevel)
        #endif

        // Calculate drain rate if we have a valid previous measurement
        let timeSinceLastCheck = now.timeIntervalSince(lastBatteryCheck)
        if timeSinceLastCheck > 60.0 && previousLevel > 0 { // At least 1 minute
            let levelChange = previousLevel - batteryLevel
            let hoursElapsed = timeSinceLastCheck / 3600.0
            batteryDrainRate = (levelChange / hoursElapsed) * 100.0 // Percent per hour

            Logger.performance.info("Battery: \(Int(self.batteryLevel * 100))%, drain rate: \(String(format: "%.1f", self.batteryDrainRate))%/hour")
        }

        lastBatteryCheck = now
        lastBatteryLevel = previousLevel

        // Log low battery warnings
        if batteryLevel < criticalBatteryThreshold {
            Logger.performance.warning("Critical battery level: \(Int(self.batteryLevel * 100))%")
        } else if batteryLevel < lowBatteryThreshold {
            Logger.performance.warning("Low battery level: \(Int(self.batteryLevel * 100))%")
        }
    }

    // MARK: - Battery State Queries

    /// Whether battery is at or below low threshold (20%)
    public var isLowBattery: Bool {
        return batteryLevel <= lowBatteryThreshold
    }

    /// Whether battery is at or below critical threshold (10%)
    public var isCriticalBattery: Bool {
        return batteryLevel <= criticalBatteryThreshold
    }

    /// Battery percentage (0-100)
    public var batteryPercentage: Int {
        return Int(batteryLevel * 100)
    }

    // MARK: - Metrics Collection

    /// Starts periodic metrics collection
    private func startMetricsCollection() async {
        while true {
            updateMemoryUsage()
            updateCPUUsage()

            // Update every 5 seconds (using nanoseconds for macOS compatibility)
            try? await Task.sleep(nanoseconds: 5_000_000_000)
        }
    }

    // MARK: - Performance Summary

    /// Returns a summary of all performance metrics
    public func getPerformanceSummary() -> PerformanceSummary {
        return PerformanceSummary(
            gpsLatencyAvg: averageGPSLatency,
            gpsLatencyP95: p95GPSLatency,
            messageLatencyAvg: averageMessageLatency,
            messageLatencyP95: p95MessageLatency,
            memoryUsageMB: memoryUsageMB,
            cpuUsagePercent: cpuUsagePercent,
            batteryLevel: batteryLevel,
            batteryDrainRate: batteryDrainRate
        )
    }

    /// Logs current performance metrics
    public func logMetrics() {
        let summary = getPerformanceSummary()

        Logger.performance.info("""
            Performance Metrics:
            - GPS Latency: avg=\(Int(summary.gpsLatencyAvg * 1000))ms, p95=\(Int(summary.gpsLatencyP95 * 1000))ms
            - Message Latency: avg=\(Int(summary.messageLatencyAvg * 1000))ms, p95=\(Int(summary.messageLatencyP95 * 1000))ms
            - Memory: \(Int(summary.memoryUsageMB))MB
            - CPU: \(Int(summary.cpuUsagePercent))%
            - Battery: \(Int(summary.batteryLevel * 100))%, drain=\(String(format: "%.1f", summary.batteryDrainRate))%/hour
            """)
    }

    /// Resets all metrics (useful for testing)
    public func resetMetrics() {
        gpsLatencies.removeAll()
        messageLatencies.removeAll()
        pendingMessages.removeAll()
        memoryUsageMB = 0.0
        cpuUsagePercent = 0.0
        Logger.performance.debug("Performance metrics reset")
    }
}

// MARK: - Performance Summary

/// Summary of performance metrics at a point in time
@available(iOS 14.0, watchOS 7.0, macOS 11.0, *)
public struct PerformanceSummary: Sendable {
    /// Average GPS latency (seconds)
    public let gpsLatencyAvg: TimeInterval

    /// 95th percentile GPS latency (seconds)
    public let gpsLatencyP95: TimeInterval

    /// Average message latency (seconds)
    public let messageLatencyAvg: TimeInterval

    /// 95th percentile message latency (seconds)
    public let messageLatencyP95: TimeInterval

    /// Memory usage (megabytes)
    public let memoryUsageMB: Double

    /// CPU usage (percentage 0-100)
    public let cpuUsagePercent: Double

    /// Battery level (0.0-1.0)
    public let batteryLevel: Double

    /// Battery drain rate (percent per hour)
    public let batteryDrainRate: Double

    /// Whether GPS latency meets target (<500ms p95)
    public var meetsGPSTarget: Bool {
        return gpsLatencyP95 < 0.5
    }

    /// Whether message latency meets target (<100ms p95)
    public var meetsMessageTarget: Bool {
        return messageLatencyP95 < 0.1
    }

    /// Whether memory usage meets target
    public var meetsMemoryTarget: Bool {
        #if os(iOS)
        return memoryUsageMB < 50.0
        #else
        return memoryUsageMB < 25.0
        #endif
    }

    /// Whether CPU usage meets target (<10%)
    public var meetsCPUTarget: Bool {
        return cpuUsagePercent < 10.0
    }

    /// Whether battery is low (<=20%)
    public var isLowBattery: Bool {
        return batteryLevel <= 0.20
    }

    /// Whether battery is critical (<=10%)
    public var isCriticalBattery: Bool {
        return batteryLevel <= 0.10
    }
}
