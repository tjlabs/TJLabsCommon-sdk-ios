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

enum RfdScanFilter: String {
    case TJ = "TJ-"
    case NI = "NI-"
}

public enum ScanMode {
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

struct RFDErrorCode {
    // BLE Hardware
    let BLUETOOTH_DISABLED = 100
    let BLUETOOTH_NOT_SUPPORTED = 101

    // BLE Permission
    let PERMISSION_DENIED = 110
    let PERMISSION_STATE_CHANGED = 111

    // BLE Scan Result
    let SCAN_TIMEOUT = 120
    let INVALID_DEVICE_NAME = 121
    let INVALID_RSSI = 122
    
    // Duplicated RFD Generation Service
    let DUPLICATE_SCAN_START = 130
}


// MARK: - Structs
public struct ReceivedForce: Encodable {
    public let user_id: String
    public let mobile_time: Int
    public let ble: [String: Double]
    public let pressure: Double

    public init(user_id: String, mobile_time: Int, ble: [String: Double], pressure: Double) {
        self.user_id = user_id
        self.mobile_time = mobile_time
        self.ble = ble
        self.pressure = pressure
    }
}

// MARK: - Protocol
public protocol RFDGeneratorDelegate: AnyObject {
    func onRfdResult(_ generator: RFDGenerator, receivedForce: ReceivedForce)
    func onRfdError(_ generator: RFDGenerator, code: Int, msg: String)
    func onRfdEmptyMillis(_ generator: RFDGenerator, time: Double)
}
