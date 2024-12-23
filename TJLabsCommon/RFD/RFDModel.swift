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

// MARK: - Enums
enum TrimBleDataError: Error {
    case invalidInput
    case noValidData
}

// MARK: - Structs
public struct ReceivedForce: Encodable {
    let userID: String
    let mobileTime: Int
    let ble: [String: Double]
    let pressure: Double

    public init(userID: String, mobileTime: Int, ble: [String: Double], pressure: Double) {
        self.userID = userID
        self.mobileTime = mobileTime
        self.ble = ble
        self.pressure = pressure
    }
}
