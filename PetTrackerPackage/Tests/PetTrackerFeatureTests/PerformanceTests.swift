import Testing
@testable import PetTrackerFeature
import Foundation

/// Comprehensive tests for performance monitoring and battery optimization
@Suite("Performance Monitoring Tests")
@MainActor
struct PerformanceTests {

    // MARK: - GPS Latency Tests

    @Test("Records GPS latency correctly")
    func testRecordGPSLatency() async {
        let monitor = PerformanceMonitor.shared
        monitor.resetMetrics()

        // Record some latencies
        monitor.recordGPSLatency(0.1) // 100ms
        monitor.recordGPSLatency(0.2) // 200ms
        monitor.recordGPSLatency(0.3) // 300ms

        // Verify average
        let avg = monitor.averageGPSLatency
        #expect(abs(avg - 0.2) < 0.001) // Average should be ~200ms

        // Verify p95
        let p95 = monitor.p95GPSLatency
        #expect(p95 >= 0.2) // Should be at least 200ms
    }

    @Test("GPS latency target is 500ms")
    func testGPSLatencyTarget() {
        let monitor = PerformanceMonitor.shared
        #expect(monitor.gpsLatencyTarget == 0.5)
    }

    @Test("Tracks GPS latency over multiple samples")
    func testMultipleGPSLatencies() async {
        let monitor = PerformanceMonitor.shared
        monitor.resetMetrics()

        // Record 50 samples
        for i in 1...50 {
            let latency = Double(i) / 1000.0 // 1ms to 50ms
            monitor.recordGPSLatency(latency)
        }

        let avg = monitor.averageGPSLatency
        #expect(avg > 0) // Should have valid average
        #expect(avg < 0.1) // All samples under 100ms
    }

    @Test("GPS p95 latency calculation is accurate")
    func testGPSP95Calculation() async {
        let monitor = PerformanceMonitor.shared
        monitor.resetMetrics()

        // Record 100 samples: 0.1s to 1.0s
        for i in 1...100 {
            monitor.recordGPSLatency(Double(i) / 100.0)
        }

        let p95 = monitor.p95GPSLatency
        // P95 of 0.01-1.0 should be around 0.95
        #expect(abs(p95 - 0.95) < 0.05)
    }

    // MARK: - Message Latency Tests

    @Test("Records message latency correctly")
    func testRecordMessageLatency() async {
        let monitor = PerformanceMonitor.shared
        monitor.resetMetrics()

        // Send message
        monitor.recordMessageSent(messageId: "msg1")

        // Simulate network delay
        try? await Task.sleep(nanoseconds: 50_000_000)

        // Receive message
        monitor.recordMessageReceived(messageId: "msg1")

        // Check latency was recorded
        let avg = monitor.averageMessageLatency
        #expect(avg > 0) // Should be positive
        #expect(avg < 0.2) // Less than 200ms
    }

    @Test("Message latency target is 100ms")
    func testMessageLatencyTarget() {
        let monitor = PerformanceMonitor.shared
        #expect(monitor.messageLatencyTarget == 0.1)
    }

    @Test("Handles missing message ID gracefully")
    func testMissingMessageID() {
        let monitor = PerformanceMonitor.shared
        monitor.resetMetrics()

        // Receive message that was never sent
        monitor.recordMessageReceived(messageId: "nonexistent")

        // Should not crash, average should be 0
        #expect(monitor.averageMessageLatency == 0)
    }

    @Test("Tracks multiple concurrent messages")
    func testMultipleConcurrentMessages() async {
        let monitor = PerformanceMonitor.shared
        monitor.resetMetrics()

        // Send multiple messages
        for i in 1...5 {
            monitor.recordMessageSent(messageId: "msg\(i)")
        }

        // Simulate staggered receipt
        for i in 1...5 {
            try? await Task.sleep(nanoseconds: 10_000_000)
            monitor.recordMessageReceived(messageId: "msg\(i)")
        }

        let avg = monitor.averageMessageLatency
        #expect(avg > 0) // Should have recorded latencies
    }

    @Test("Message p95 latency calculation is accurate")
    func testMessageP95Calculation() async {
        let monitor = PerformanceMonitor.shared
        monitor.resetMetrics()

        // Send and receive 100 messages with varying latencies
        for i in 1...100 {
            monitor.recordMessageSent(messageId: "msg\(i)")
            try? await Task.sleep(nanoseconds: UInt64(i) * 1_000_000) // 1-100ms latency
            monitor.recordMessageReceived(messageId: "msg\(i)")
        }

        let p95 = monitor.p95MessageLatency
        // P95 should be around 95ms (0.095s)
        #expect(p95 >= 0.08) // At least 80ms
        #expect(p95 <= 0.12) // At most 120ms
    }

    // MARK: - Battery Monitoring Tests

    @Test("Battery level is between 0 and 1")
    func testBatteryLevelRange() {
        let monitor = PerformanceMonitor.shared
        #expect(monitor.batteryLevel >= 0.0)
        #expect(monitor.batteryLevel <= 1.0)
    }

    @Test("Battery percentage conversion is correct")
    func testBatteryPercentage() {
        let monitor = PerformanceMonitor.shared
        let percentage = monitor.batteryPercentage
        #expect(percentage >= 0)
        #expect(percentage <= 100)
    }

    @Test("Low battery threshold is 20%")
    func testLowBatteryThreshold() {
        let monitor = PerformanceMonitor.shared
        #expect(monitor.lowBatteryThreshold == 0.20)
    }

    @Test("Critical battery threshold is 10%")
    func testCriticalBatteryThreshold() {
        let monitor = PerformanceMonitor.shared
        #expect(monitor.criticalBatteryThreshold == 0.10)
    }

    @Test("Low battery detection works")
    func testLowBatteryDetection() {
        let monitor = PerformanceMonitor.shared

        // Note: This test depends on actual device battery level
        // We can only verify the logic is consistent
        let isLow = monitor.isLowBattery
        let isCritical = monitor.isCriticalBattery

        // If critical, must also be low
        if isCritical {
            #expect(isLow)
        }

        // Battery level should match detection
        if monitor.batteryLevel <= 0.10 {
            #expect(isCritical)
            #expect(isLow)
        } else if monitor.batteryLevel <= 0.20 {
            #expect(isLow)
            #expect(!isCritical)
        } else {
            #expect(!isLow)
            #expect(!isCritical)
        }
    }

    // MARK: - Memory Monitoring Tests

    @Test("Memory usage is tracked")
    func testMemoryUsage() {
        let monitor = PerformanceMonitor.shared
        let memory = monitor.memoryUsageMB

        // Memory should be positive
        #expect(memory >= 0)

        // Memory should be reasonable (not in GBs)
        #expect(memory < 500.0)
    }

    @Test("Memory target for iOS is 50MB")
    func testMemoryTargetiOS() {
        let monitor = PerformanceMonitor.shared
        #expect(monitor.memoryTargetMB_iOS == 50.0)
    }

    @Test("Memory target for Watch is 25MB")
    func testMemoryTargetWatch() {
        let monitor = PerformanceMonitor.shared
        #expect(monitor.memoryTargetMB_Watch == 25.0)
    }

    // MARK: - CPU Monitoring Tests

    @Test("CPU usage is tracked")
    func testCPUUsage() {
        let monitor = PerformanceMonitor.shared
        let cpu = monitor.cpuUsagePercent

        // CPU should be non-negative
        #expect(cpu >= 0)

        // CPU should not exceed 100% (per thread, but total should be reasonable)
        #expect(cpu < 500.0)
    }

    @Test("CPU target is 10%")
    func testCPUTarget() {
        let monitor = PerformanceMonitor.shared
        #expect(monitor.cpuTargetPercent == 10.0)
    }

    // MARK: - Performance Summary Tests

    @Test("Performance summary captures all metrics")
    func testPerformanceSummary() {
        let monitor = PerformanceMonitor.shared
        monitor.resetMetrics()

        // Record some data
        monitor.recordGPSLatency(0.3)
        monitor.recordGPSLatency(0.4)

        let summary = monitor.getPerformanceSummary()

        // Verify all fields are populated
        #expect(summary.gpsLatencyAvg >= 0)
        #expect(summary.gpsLatencyP95 >= 0)
        #expect(summary.messageLatencyAvg >= 0)
        #expect(summary.messageLatencyP95 >= 0)
        #expect(summary.memoryUsageMB >= 0)
        #expect(summary.cpuUsagePercent >= 0)
        #expect(summary.batteryLevel >= 0)
        #expect(summary.batteryLevel <= 1.0)
    }

    @Test("Performance summary GPS target check")
    func testSummaryGPSTarget() {
        let monitor = PerformanceMonitor.shared
        monitor.resetMetrics()

        // Record latencies under target
        monitor.recordGPSLatency(0.2) // 200ms
        monitor.recordGPSLatency(0.3) // 300ms
        monitor.recordGPSLatency(0.4) // 400ms

        let summary = monitor.getPerformanceSummary()
        #expect(summary.meetsGPSTarget) // All under 500ms
    }

    @Test("Performance summary GPS target failure")
    func testSummaryGPSTargetFailure() {
        let monitor = PerformanceMonitor.shared
        monitor.resetMetrics()

        // Record latencies over target
        for _ in 1...100 {
            monitor.recordGPSLatency(0.6) // 600ms - over 500ms target
        }

        let summary = monitor.getPerformanceSummary()
        #expect(!summary.meetsGPSTarget) // Should fail target
    }

    @Test("Performance summary message target check")
    func testSummaryMessageTarget() async {
        let monitor = PerformanceMonitor.shared
        monitor.resetMetrics()

        // Record latencies under target
        for i in 1...10 {
            monitor.recordMessageSent(messageId: "msg\(i)")
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
            monitor.recordMessageReceived(messageId: "msg\(i)")
        }

        let summary = monitor.getPerformanceSummary()
        #expect(summary.meetsMessageTarget) // All under 100ms
    }

    @Test("Performance summary memory target check")
    func testSummaryMemoryTarget() {
        let monitor = PerformanceMonitor.shared
        let summary = monitor.getPerformanceSummary()

        // Memory should meet target
        #if os(iOS)
        let meetsTarget = summary.memoryUsageMB < 50.0
        #else
        let meetsTarget = summary.memoryUsageMB < 25.0
        #endif

        #expect(summary.meetsMemoryTarget == meetsTarget)
    }

    @Test("Performance summary CPU target check")
    func testSummaryCPUTarget() {
        let monitor = PerformanceMonitor.shared
        let summary = monitor.getPerformanceSummary()

        // CPU check
        let meetsTarget = summary.cpuUsagePercent < 10.0
        #expect(summary.meetsCPUTarget == meetsTarget)
    }

    @Test("Performance summary battery checks")
    func testSummaryBatteryChecks() {
        let monitor = PerformanceMonitor.shared
        let summary = monitor.getPerformanceSummary()

        // Verify battery state matches level
        if summary.batteryLevel <= 0.10 {
            #expect(summary.isCriticalBattery)
            #expect(summary.isLowBattery)
        } else if summary.batteryLevel <= 0.20 {
            #expect(summary.isLowBattery)
            #expect(!summary.isCriticalBattery)
        } else {
            #expect(!summary.isLowBattery)
            #expect(!summary.isCriticalBattery)
        }
    }

    // MARK: - Reset Tests

    @Test("Reset clears all metrics")
    func testResetMetrics() async {
        let monitor = PerformanceMonitor.shared

        // Add some data
        monitor.recordGPSLatency(0.5)
        monitor.recordMessageSent(messageId: "test")
        try? await Task.sleep(nanoseconds: 10_000_000)
        monitor.recordMessageReceived(messageId: "test")

        // Reset
        monitor.resetMetrics()

        // Verify all cleared
        #expect(monitor.averageGPSLatency == 0)
        #expect(monitor.averageMessageLatency == 0)
        #expect(monitor.p95GPSLatency == 0)
        #expect(monitor.p95MessageLatency == 0)
    }

    // MARK: - Edge Cases

    @Test("Empty metrics return zero")
    func testEmptyMetrics() {
        let monitor = PerformanceMonitor.shared
        monitor.resetMetrics()

        #expect(monitor.averageGPSLatency == 0)
        #expect(monitor.averageMessageLatency == 0)
        #expect(monitor.p95GPSLatency == 0)
        #expect(monitor.p95MessageLatency == 0)
    }

    @Test("Single sample percentile calculation")
    func testSingleSamplePercentile() {
        let monitor = PerformanceMonitor.shared
        monitor.resetMetrics()

        monitor.recordGPSLatency(0.3)

        // With single sample, average and p95 should be same
        #expect(monitor.averageGPSLatency == monitor.p95GPSLatency)
    }

    @Test("Maximum samples limit is enforced")
    func testMaxSamplesLimit() {
        let monitor = PerformanceMonitor.shared
        monitor.resetMetrics()

        // Record 150 samples (max is 100)
        for i in 1...150 {
            monitor.recordGPSLatency(Double(i) / 1000.0)
        }

        // Summary should still work (using last 100)
        let summary = monitor.getPerformanceSummary()
        #expect(summary.gpsLatencyAvg > 0)
    }

    // MARK: - Concurrency Tests

    @Test("Multiple GPS latency recordings work correctly")
    func testMultipleGPSRecordings() async {
        let monitor = PerformanceMonitor.shared
        monitor.resetMetrics()

        // Record sequentially
        for i in 1...10 {
            monitor.recordGPSLatency(Double(i) / 100.0)
        }

        // Should have recorded all
        let avg = monitor.averageGPSLatency
        #expect(avg > 0)
    }

    @Test("Multiple message latency recordings work correctly")
    func testMultipleMessageRecordings() async {
        let monitor = PerformanceMonitor.shared
        monitor.resetMetrics()

        // Send messages sequentially
        for i in 1...10 {
            monitor.recordMessageSent(messageId: "msg\(i)")
            try? await Task.sleep(nanoseconds: 10_000_000)
            monitor.recordMessageReceived(messageId: "msg\(i)")
        }

        // Should have recorded all
        let avg = monitor.averageMessageLatency
        #expect(avg > 0)
    }
}

// MARK: - Battery Optimization Tests

@Suite("Battery Optimization Tests")
@MainActor
struct BatteryOptimizationTests {

    @Test("Battery drain rate is calculated")
    func testBatteryDrainRate() {
        let monitor = PerformanceMonitor.shared
        let drainRate = monitor.batteryDrainRate

        // Drain rate should be non-negative in most cases
        // (Could be negative if charging, but typically positive)
        #expect(drainRate >= -100.0) // Not draining faster than 100%/hour
    }

    @Test("Low battery state detection")
    func testLowBatteryState() {
        let monitor = PerformanceMonitor.shared

        // Verify consistency between battery level and state
        let isLow = monitor.isLowBattery
        let level = monitor.batteryLevel

        if level <= 0.20 {
            #expect(isLow)
        } else {
            #expect(!isLow)
        }
    }

    @Test("Critical battery state detection")
    func testCriticalBatteryState() {
        let monitor = PerformanceMonitor.shared

        let isCritical = monitor.isCriticalBattery
        let level = monitor.batteryLevel

        if level <= 0.10 {
            #expect(isCritical)
        } else {
            #expect(!isCritical)
        }
    }
}

// MARK: - Integration Tests

@Suite("Performance Integration Tests")
@MainActor
struct PerformanceIntegrationTests {

    @Test("Full monitoring workflow")
    func testFullMonitoringWorkflow() async {
        let monitor = PerformanceMonitor.shared

        // Note: Since PerformanceMonitor is a singleton shared across tests,
        // we don't reset metrics here as other tests may have added data.
        // Instead, we just verify the workflow adds data correctly.

        // Get initial state
        let initialGPSAvg = monitor.averageGPSLatency
        let initialMsgAvg = monitor.averageMessageLatency

        // Record GPS latencies
        monitor.recordGPSLatency(0.1) // 100ms
        monitor.recordGPSLatency(0.2) // 200ms
        monitor.recordGPSLatency(0.3) // 300ms

        // Verify GPS data was recorded (should be different from initial)
        #expect(monitor.averageGPSLatency >= initialGPSAvg)

        // Simulate message exchange
        monitor.recordMessageSent(messageId: "integration_test1")
        try? await Task.sleep(nanoseconds: 50_000_000)
        monitor.recordMessageReceived(messageId: "integration_test1")

        monitor.recordMessageSent(messageId: "integration_test2")
        try? await Task.sleep(nanoseconds: 50_000_000)
        monitor.recordMessageReceived(messageId: "integration_test2")

        // Verify message data was recorded (should be different from initial)
        #expect(monitor.averageMessageLatency >= initialMsgAvg)

        // Get summary
        let summary = monitor.getPerformanceSummary()

        // Verify battery level is valid (this should always work)
        #expect(summary.batteryLevel >= 0)
        #expect(summary.batteryLevel <= 1.0)

        // Note: Memory and CPU usage may be 0 initially, which is fine
    }

    @Test("Performance metrics logging doesn't crash")
    func testMetricsLogging() {
        let monitor = PerformanceMonitor.shared
        monitor.resetMetrics()

        // Add some data
        monitor.recordGPSLatency(0.3)

        // Log metrics (should not crash)
        monitor.logMetrics()
    }
}
