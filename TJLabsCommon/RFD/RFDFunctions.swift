import Foundation

public class RFDFunctions: NSObject {
    public static let shared = RFDFunctions()

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

//    func getLatestBleData(bleDictionary: [String: [[Double]]]) -> [String: Double] {
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
