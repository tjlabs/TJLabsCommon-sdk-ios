
import Foundation

public class RFDGenerator: NSObject {
    let bleManager = TJLabsBluetoothManager()
    var receivedForceTimer: DispatchSourceTimer?
    
    var userId: String = "Unknown"
    var scanFilters: [RfdScanFilter] = [RfdScanFilter.TJ]
    var timerInterval: TimeInterval = 1/2
    var bleScanWindowTime: Double = 0
    private var rfdGenerationTimeMillis: Double = 0
    
    // Bluetooth Observing Variables
    let BLE_OFF_THRESHOLD: Double = 4
    private var timeBleOff: Double = 0
    private var isBleOff: Bool = false
    
    public weak var delegate: RFDGeneratorDelegate?
    public var pressureProvider: () -> Double = { 0 }
    
    public init(userId: String) {
        self.userId = userId
        self.scanFilters = [RfdScanFilter.TJ]
        bleManager.setScanFilters(scanFilter: self.scanFilters)
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
        print(TJLabsUtilFunctions.shared.getLocalTimeString() + " , " + CommonConstants.COMMON_HEADER + " setScanMode : scanMode = \(scanMode)")
    }
    
    public func generateRfd(rfdIntervalMillis: TimeInterval = 1/2, bleScanWindowTimeMillis: Double = 1000, minRssiThreshold: Int = -100, maxRssiThreshold: Int = -40) {
        self.timerInterval = rfdIntervalMillis
        self.bleScanWindowTime = bleScanWindowTimeMillis
        bleManager.setBleScanWindowTime(value: bleScanWindowTimeMillis)
        bleManager.setMinRssiThreshold(value: minRssiThreshold)
        bleManager.setMaxRssiThreshold(value: maxRssiThreshold)
        startTimer()
        print(TJLabsUtilFunctions.shared.getLocalTimeString() + " , " + CommonConstants.COMMON_HEADER + " Info : start RFD generation")
    }
    
    public func stopRfdGeneration() {
        bleManager.stopScan()
        stopTimer()
        print(TJLabsUtilFunctions.shared.getLocalTimeString() + " , " + CommonConstants.COMMON_HEADER + " Info : stop RFD generation")
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
            self.rfdGenerationTimeMillis = TJLabsUtilFunctions.shared.getCurrentTimeInMillisecondsDouble()
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
    
    func checkBluetoothState() {
        let currentTime: Double = TJLabsUtilFunctions.shared.getCurrentTimeInMillisecondsDouble()
        if !bleManager.bluetoothReady {
            let permission = bleManager.checkPermission()
            if !permission.hasPermission {
                // No Permmission
                delegate?.onRfdError(self, code: RFDErrorCode().PERMISSION_DENIED, msg: permission.message)
            } else {
                // Check BLE OFF
                self.timeBleOff += self.timerInterval
                if (self.timeBleOff >= BLE_OFF_THRESHOLD) {
                    if (!self.isBleOff) {
                        self.isBleOff = true
                        self.timeBleOff = 0
                        delegate?.onRfdError(self, code: RFDErrorCode().BLUETOOTH_DISABLED, msg: TJLabsUtilFunctions.shared.getLocalTimeString() + " , " + CommonConstants.COMMON_HEADER + " Bluetooth OFF")
                    }
                }
            }
        } else {
            let bleLastScannedTime = (currentTime - bleManager.bleLastScannedTime)*1e-3
            if (bleLastScannedTime >= 6) {
                // 스캔이 동작안한지 6초 이상 지남
                delegate?.onRfdError(self, code: RFDErrorCode().SCAN_TIMEOUT, msg: TJLabsUtilFunctions.shared.getLocalTimeString() + " , " + CommonConstants.COMMON_HEADER + " Bluetooth Scan Stop")
            }
        }
    }
    
    func receivedForceTimerUpdate() {
        self.checkBluetoothState()
        let currentTime = TJLabsUtilFunctions.shared.getCurrentTimeInMillisecondsDouble()
        let rfdTime = currentTime - (bleScanWindowTime/2)
        
        let bleDictionary = bleManager.getBLEDictionary()
        let trimmedResult = TJLabsBluetoothFunctions.shared.trimBleData(bleInput: bleDictionary, nowTime: currentTime, scanWindowTime: self.bleScanWindowTime)
        
        let data: ReceivedForce
        switch trimmedResult {
        case .success(let trimmedBLE):
            let bleAvg = TJLabsBluetoothFunctions.shared.avgBleData(bleDictionary: trimmedBLE)
            let pressureValue = pressureProvider()
            if bleAvg.isEmpty {
                delegate?.onRfdEmptyMillis(self, time: currentTime - self.rfdGenerationTimeMillis)
            } else {
                self.rfdGenerationTimeMillis = currentTime
            }
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
