
import Foundation

public class RFDGenerator: NSObject {
    let bleManager = TJLabsBluetoothManager()
    var receivedForceTimer: DispatchSourceTimer?
    
    var userId: String = "Unknown"
    var scanFilters: [RfdScanFilter] = [RfdScanFilter.TJ]
    var timerInterval: TimeInterval = 1/2
    var bleScanWindowTime: Double = 0
    
    public weak var delegate: RFDGeneratorDelegate?
    public var pressureProvider: () -> Double = { 0 }
    
    public init(userId: String) {
        self.userId = userId
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
    
    public func generateRfd(rfdIntervalMillis: TimeInterval = 1/2, bleScanWindowTimeMillis: Double = 1000, minRssiThreshold: Int = -100, maxRssiThreshold: Int = -40) {
        let initBLE = bleManager.checkPermission()
        if !initBLE.hasPermission {
            delegate?.onRfdError(self, code: RFDErrorCode().PERMISSION_DENIED, msg: initBLE.message)
            return
        }
        
        let startScanBLE = bleManager.startScan(scanFilter: self.scanFilters)
        if startScanBLE.0 {
            self.timerInterval = rfdIntervalMillis
            self.bleScanWindowTime = bleScanWindowTimeMillis
            
            bleManager.setBleScanWindowTime(value: bleScanWindowTimeMillis)
            bleManager.setMinRssiThreshold(value: minRssiThreshold)
            bleManager.setMaxRssiThreshold(value: maxRssiThreshold)
            
            startTimer()
        } else {
            delegate?.onRfdError(self, code: RFDErrorCode().BLUETOOTH_DISABLED, msg: "??")
        }
    }
    
    public func stopRfdGeneration() {
        bleManager.stopScan()
        stopTimer()
    }
    
    // Hide //
//    public func getBleScanWindowTime() -> Double {
//        return self.bleManager.getBleScanWindowTime()
//    }
//    
//    public func getWardLastScanTime() -> Double {
//        return self.bleManager.getWardLastScanTime()
//    }
    
    func startTimer() {
        if (self.receivedForceTimer == nil) {
            let queueRfd = DispatchQueue(label: Bundle.main.bundleIdentifier! + ".receivedForceTimer")
            self.receivedForceTimer = DispatchSource.makeTimerSource(queue: queueRfd)
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
        let rfdTime = currentTime - (bleScanWindowTime/2)
        
        let bleDictionary = bleManager.getBLEDictionary()
        let trimmedResult = TJLabsBluetoothFunctions.shared.trimBleData(bleInput: bleDictionary, nowTime: currentTime, scanWindowTime: self.bleScanWindowTime)
        
        let data: ReceivedForce
        switch trimmedResult {
        case .success(let trimmedBLE):
            let bleAvg = TJLabsBluetoothFunctions.shared.avgBleData(bleDictionary: trimmedBLE)
            let pressureValue = pressureProvider()
            data = ReceivedForce(user_id: self.userId, mobile_time: Int(rfdTime), ble: bleAvg, pressure: pressureValue)
        case .failure(let error):
            data = ReceivedForce(user_id: self.userId, mobile_time: Int(rfdTime), ble: [String: Double](), pressure: 0)
            switch error {
            case TrimBleDataError.invalidInput:
                delegate?.onRfdError(self, code: RFDErrorCode().INVALID_RSSI, msg: TJLabsUtilFunctions.shared.getLocalTimeString() + " , " + CommonConstants.COMMON_HEADER + " Error : invalidInput in RFD trmming")
            case TrimBleDataError.noValidData:
                delegate?.onRfdError(self, code: RFDErrorCode().INVALID_RSSI, msg: TJLabsUtilFunctions.shared.getLocalTimeString() + " , " + CommonConstants.COMMON_HEADER + " Error : noValidData in RFD trmming")
            default:
                delegate?.onRfdError(self, code: RFDErrorCode().INVALID_RSSI, msg: TJLabsUtilFunctions.shared.getLocalTimeString() + " , " + CommonConstants.COMMON_HEADER + " Error : default in RFD trmming")
            }
        }
        
        delegate?.onRfdResult(self, receivedForce: data)
    }
}
