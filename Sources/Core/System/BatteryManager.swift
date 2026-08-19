import Foundation
import AppKit
import IOKit.ps
import Observation

/// Monitors battery percentage, charging state, and power source changes via public IOKit APIs.
@Observable
@MainActor
public final class BatteryManager {
    public static let shared = BatteryManager()

    public var batteryLevel: Int = 100
    public var isCharging: Bool = false
    public var isPluggedIn: Bool = false

    private var timerTask: Task<Void, Never>?

    public init() {
        updateBatteryState()
        startObserving()
    }

    public func updateBatteryState() {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] else {
            return
        }

        for ps in sources {
            if let description = IOPSGetPowerSourceDescription(snapshot, ps)?.takeUnretainedValue() as? [String: Any] {
                if let current = description[kIOPSCurrentCapacityKey] as? Int,
                   let max = description[kIOPSMaxCapacityKey] as? Int, max > 0 {
                    self.batteryLevel = Int((Double(current) / Double(max)) * 100)
                }

                if let isChargingVal = description[kIOPSIsChargingKey] as? Bool {
                    self.isCharging = isChargingVal
                }

                if let powerSource = description[kIOPSPowerSourceStateKey] as? String {
                    self.isPluggedIn = (powerSource == kIOPSACPowerValue)
                }
            }
        }
    }

    private func startObserving() {
        // Polls once every 30 seconds for battery changes with negligible energy impact
        timerTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 30_000_000_000)
                self?.updateBatteryState()
            }
        }
    }

    public func stopObserving() {
        timerTask?.cancel()
        timerTask = nil
    }
}
