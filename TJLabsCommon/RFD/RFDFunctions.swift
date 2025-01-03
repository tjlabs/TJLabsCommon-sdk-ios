import Foundation

public class RFDFunctions: NSObject {
    public static let shared = RFDFunctions()

    public func getBleChannelNum(bleAvg: [String: Double]?, threshold: Double = -95.0) -> Int {
        var numChannels: Int = 0
        if let bleAvgData = bleAvg {
            for key in bleAvgData.keys {
                let bleRssi: Double = bleAvgData[key] ?? -100.0
                
                if (bleRssi > threshold) {
                    numChannels += 1
                }
            }
        }
        
        return numChannels
    }

//    public func getLatestBleData(bleDictionary: [String: [[Double]]]) -> [String: Double] {
//        var ble = [String: Double]()
//        
//        let keys: [String] = Array(bleDictionary.keys)
//        for index in 0..<keys.count {
//            let bleID: String = keys[index]
//            let bleData: [[Double]] = bleDictionary[bleID]!
//            
//            let rssiFinal: Double = bleData[bleData.count-1][0]
//            
//            ble.updateValue(rssiFinal, forKey: bleID)
//        }
//        return ble
//    }
}
