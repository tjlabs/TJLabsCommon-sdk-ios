import Foundation

public enum BLEScanOption: Int {
    case Foreground = 1
    case Background
}

enum TrimBleDataError: Error {
    case invalidInput
    case noValidData
}

public struct ReceivedForce: Encodable {
    let user_id: String
    let mobile_time: Int
    let ble: [String: Double]
    let pressure: Double
    
    public init(user_id: String, mobile_time: Int, ble: [String : Double], pressure: Double) {
        self.user_id = user_id
        self.mobile_time = mobile_time
        self.ble = ble
        self.pressure = pressure
    }
}
