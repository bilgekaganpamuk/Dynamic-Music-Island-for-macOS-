import Foundation
import Observation

/// Monitors live download and upload network bandwidth using standard BSD getifaddrs.
@Observable
@MainActor
public final class NetworkSpeedMonitor {
    public static let shared = NetworkSpeedMonitor()

    public var downloadSpeedString: String = "0 KB/s"
    public var uploadSpeedString: String = "0 KB/s"
    public var downloadBytesPerSec: UInt64 = 0
    public var uploadBytesPerSec: UInt64 = 0

    private var previousBytesIn: UInt64 = 0
    private var previousBytesOut: UInt64 = 0
    private var timer: Timer?

    public init() {
        let (initialIn, initialOut) = getNetworkBytes()
        self.previousBytesIn = initialIn
        self.previousBytesOut = initialOut
        startMonitoring()
    }

    public func startMonitoring() {
        resumeMonitoring()
    }

    public func resumeMonitoring() {
        guard timer == nil else { return }
        sampleSpeeds()
        timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.sampleSpeeds()
            }
        }
    }

    public func pauseMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func sampleSpeeds() {
        let (currentIn, currentOut) = getNetworkBytes()

        if previousBytesIn > 0 && currentIn >= previousBytesIn {
            let diffIn = currentIn - previousBytesIn
            self.downloadBytesPerSec = UInt64(Double(diffIn) / 1.5)
            self.downloadSpeedString = formatSpeed(bytes: downloadBytesPerSec)
        }

        if previousBytesOut > 0 && currentOut >= previousBytesOut {
            let diffOut = currentOut - previousBytesOut
            self.uploadBytesPerSec = UInt64(Double(diffOut) / 1.5)
            self.uploadSpeedString = formatSpeed(bytes: uploadBytesPerSec)
        }

        self.previousBytesIn = currentIn
        self.previousBytesOut = currentOut
    }

    private func formatSpeed(bytes: UInt64) -> String {
        if bytes >= 1024 * 1024 {
            let mb = Double(bytes) / (1024.0 * 1024.0)
            return String(format: "%.1f MB/s", mb)
        } else if bytes >= 1024 {
            let kb = Double(bytes) / 1024.0
            return String(format: "%.0f KB/s", kb)
        } else {
            return "\(bytes) B/s"
        }
    }

    private func getNetworkBytes() -> (bytesIn: UInt64, bytesOut: UInt64) {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            return (0, 0)
        }
        defer { freeifaddrs(ifaddr) }

        var totalIn: UInt64 = 0
        var totalOut: UInt64 = 0

        var cursor: UnsafeMutablePointer<ifaddrs>? = firstAddr
        while let ptr = cursor {
            let name = String(cString: ptr.pointee.ifa_name)
            // Filter loopback
            if !name.hasPrefix("lo") && ptr.pointee.ifa_data != nil {
                let data = ptr.pointee.ifa_data.assumingMemoryBound(to: if_data.self)
                totalIn += UInt64(data.pointee.ifi_ibytes)
                totalOut += UInt64(data.pointee.ifi_obytes)
            }
            cursor = ptr.pointee.ifa_next
        }

        return (totalIn, totalOut)
    }
}
