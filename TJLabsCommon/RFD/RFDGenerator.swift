
import Foundation

public class RFDGenerator: NSObject {
    let bleManager = TJLabsBluetoothManager()
    var receivedForceTimer: DispatchSourceTimer?
    
    var user_id: String = "Unknown"
    var scanFilters: [RfdScanFilter] = [RfdScanFilter.TJ]
    var timerInterval: TimeInterval = 1/2
    var bleScanWindowTime: Double = 0
    
    public weak var delegate: RFDGeneratorDelegate?
    public var pressureProvider: () -> Double = { 0 }
    
    public init(id: String) {
        self.user_id = id
    }
    
    public func setScanMode(scanMode: ScanMode) {
        switch (scanMode) {
        case .NO_FILTER_SCAN:
            self.scanFilters = []
        case .ONLY_WARD_SCAN:
            self.scanFilters = [RfdScanFilter.TJ]
        case .ONLY_SEI_SCAN:
            self.scanFilters = [RfdScanFilter.NI]
        case .WARD_SEI_SCAN:
            self.scanFilters = [RfdScanFilter.TJ, RfdScanFilter.NI]
        }
    }
    
    public func generateRFD(RFDInterval: TimeInterval = 1/2, bleScanWindowTimeMillis: Double = 1000, minRssiThreshold: Int = -100, maxRssiThreshold: Int = -40) -> (Bool, String) {
        let initBLE = bleManager.startScan(scanFilter: self.scanFilters)
        if initBLE.0 {
            self.timerInterval = RFDInterval
            self.bleScanWindowTime = bleScanWindowTimeMillis
            
            bleManager.setBleScanWindowTime(value: bleScanWindowTimeMillis)
            bleManager.setMinRssiThreshold(value: minRssiThreshold)
            bleManager.setMaxRssiThreshold(value: maxRssiThreshold)
            
            startTimer()
            return initBLE
        } else {
            return initBLE
        }
    }
    
    public func stopRFDGeneration() {
        bleManager.stopScan()
        stopTimer()
    }
    
    public func setBleScanWindowTime(value: Double) {
        self.bleManager.setBleScanWindowTime(value: value)
    }
    
    public func getBleScanWindowTime() -> Double {
        return self.bleManager.getBleScanWindowTime()
    }
    
    public func getWardLastScanTime() -> Double {
        return self.bleManager.getWardLastScanTime()
    }
    
    func startTimer() {
        if (self.receivedForceTimer == nil) {
            let queueRFD = DispatchQueue(label: Bundle.main.bundleIdentifier! + ".receivedForceTimer")
            self.receivedForceTimer = DispatchSource.makeTimerSource(queue: queueRFD)
            self.receivedForceTimer!.schedule(deadline: .now(), repeating: timerInterval)
            self.receivedForceTimer!.setEventHandler { [weak self] in
                guard let self = self else { return }
                self.receivedForceTimerUpdate()
            }
            self.receivedForceTimer!.resume()
        }
    }
    
    func stopTimer() {
        self.receivedForceTimer?.cancel()
        self.receivedForceTimer = nil
    }
    
    func receivedForceTimerUpdate() {
        let currentTime = TJLabsUtilFunctions.shared.getCurrentTimeInMillisecondsDouble()
        let bleDictionary = bleManager.getBLEDictionary()
        let trimmedResult = TJLabsBluetoothFunctions.shared.trimBleData(bleInput: bleDictionary, nowTime: currentTime, scanWindowTime: self.bleScanWindowTime)
        
        let data: ReceivedForce
        var info = RFDInfo.success
        switch trimmedResult {
        case .success(let trimmedBLE):
            let bleAvg = TJLabsBluetoothFunctions.shared.avgBleData(bleDictionary: trimmedBLE)
            let pressureValue = pressureProvider()
            data = ReceivedForce(user_id: self.user_id, mobile_time: Int(currentTime), ble: bleAvg, pressure: pressureValue)
        case .failure(_):
            data = ReceivedForce(user_id: self.user_id, mobile_time: Int(currentTime), ble: [String: Double](), pressure: 0)
            info = .fail
        }
        
        delegate?.onRFDResult(self, receivedForce: data, info: info)
    }
}
