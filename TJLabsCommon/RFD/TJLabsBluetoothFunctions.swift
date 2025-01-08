
import Foundation

class TJLabsBluetoothFunctions: NSObject {
    static let shared = TJLabsBluetoothFunctions()
    
    func trimBleData(bleInput: [String: [[Double]]]?, nowTime: Double, scanWindowTime: Double) -> Result<[String: [[Double]]], Error> {
        guard let bleInput = bleInput else {
            return .failure(TrimBleDataError.invalidInput)
        }
            
        var trimmedData = [String: [[Double]]]()
            
        for (bleID, bleData) in bleInput {
            let newValue = bleData.filter { data in
                guard data.count >= 2 else { return false }
                let rssi = data[0]
                let time = data[1]
                
                return (nowTime - time <= scanWindowTime) && (rssi >= -100)
            }
            
            if !newValue.isEmpty {
                trimmedData[bleID] = newValue
            }
        }
        
        if trimmedData.isEmpty {
            return .failure(TrimBleDataError.noValidData)
        } else {
            return .success(trimmedData)
        }
    }

    func avgBleData(bleDictionary: [String: [[Double]]]) -> [String: Double] {
        let digit: Double = pow(10, 2)
        var ble = [String: Double]()
        
        let keys: [String] = Array(bleDictionary.keys)
        for index in 0..<keys.count {
            let bleID: String = keys[index]
            let bleData: [[Double]] = bleDictionary[bleID]!
            let bleCount = bleData.count
            
            var rssiSum: Double = 0
            
            for i in 0..<bleCount {
                let rssi = bleData[i][0]
                rssiSum += rssi
            }
            let rssiFinal: Double = floor(((rssiSum/Double(bleData.count))) * digit) / digit
            
            if ( rssiSum == 0 ) {
                ble.removeValue(forKey: bleID)
            } else {
                ble.updateValue(rssiFinal, forKey: bleID)
            }
        }
        return ble
    }
}
