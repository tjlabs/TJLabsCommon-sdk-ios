import Foundation

public class RFDFunctions: NSObject {
    static let shared = RFDFunctions()
    
    public func trimBleData(bleInput: [String: [[Double]]]?, nowTime: Double, validTime: Double) -> Result<[String: [[Double]]], Error> {
        guard let bleInput = bleInput else {
            return .failure(TrimBleDataError.invalidInput)
        }
            
        var trimmedData = [String: [[Double]]]()
            
        for (bleID, bleData) in bleInput {
            let newValue = bleData.filter { data in
                guard data.count >= 2 else { return false }
                let rssi = data[0]
                let time = data[1]
                
                return (nowTime - time <= validTime) && (rssi >= -100)
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

    public func avgBleData(bleDictionary: [String: [[Double]]]) -> [String: Double] {
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

    public func getBleChannelNum(bleAvg: [String: Double]?) -> Int {
        var numChannels: Int = 0
        if let bleAvgData = bleAvg {
            for key in bleAvgData.keys {
                let bleRssi: Double = bleAvgData[key] ?? -100.0
                
                if (bleRssi > -95.0) {
                    numChannels += 1
                }
            }
        }
        
        return numChannels
    }

    public func getLatestBleData(bleDictionary: [String: [[Double]]]) -> [String: Double] {
        var ble = [String: Double]()
        
        let keys: [String] = Array(bleDictionary.keys)
        for index in 0..<keys.count {
            let bleID: String = keys[index]
            let bleData: [[Double]] = bleDictionary[bleID]!
            
            let rssiFinal: Double = bleData[bleData.count-1][0]
            
            ble.updateValue(rssiFinal, forKey: bleID)
        }
        return ble
    }

}
