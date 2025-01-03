import Foundation

// MARK: - Constants
struct BLEConstants {
    static let NRF_UUID_SERVICE     = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
    static let NRF_UUID_CHAR_READ   = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"
    static let NRF_UUID_CHAR_WRITE  = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"
    static let NI_UUID_SERVICE      = "00001530-1212-efde-1523-785feabcd123"
    static let TJLABS_WARD_UUID     = "0000FEAA-0000-1000-8000-00805f9b34fb"
    static let BASE_UUID            = "-0000-1000-8000-00805f9b34fb"
}

enum RFD_SCAN_FILTER: String {
    case TJ = "TJ-"
    case NI = "NI-"
}

public enum SCAN_MODE {
    case NO_FILTER_SCAN
    case ONLY_WARD_SCAN
    case ONLY_SEI_SCAN
    case WARD_SEI_SCAN
}

// MARK: - Enums
enum TrimBleDataError: Error {
    case invalidInput
    case noValidData
}

public enum RFDInfo {
    case success
    case fail
}

// MARK: - Structs
public struct ReceivedForce: Encodable {
    let user_id: String
    let mobile_time: Int
    let ble: [String: Double]
    let pressure: Double

    public init(user_id: String, mobile_time: Int, ble: [String: Double], pressure: Double) {
        self.user_id = user_id
        self.mobile_time = mobile_time
        self.ble = ble
        self.pressure = pressure
    }
}

// MARK: - Protocol
public protocol RFDGeneratorDelegate: AnyObject {
    func onRFDResult(_ generator: RFDGenerator, receivedForce: ReceivedForce, info: RFDInfo)
}
