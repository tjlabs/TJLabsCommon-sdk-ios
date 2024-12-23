
import Foundation

public class RFDGenerator: NSObject {
    let bleManager = TJLabsBluetoothManager()
    var receivedForceTimer: DispatchSourceTimer?
    
    var user_id: String = "Unknown"
    var scanFilters = [RFD_SCAN_FILTER]()
    var timerInterval: TimeInterval = 1/2
    var bleValidTime: Double = 0
    
    public weak var delegate: RFDGeneratorDelegate?
    
    public init(id: String, scanFilter: [RFD_SCAN_FILTER], interval: TimeInterval) {
        self.user_id = id
        self.scanFilters = scanFilter
        self.timerInterval = interval
        self.bleValidTime = bleManager.getBluetoothValidTime()
    }
    
    public func start() -> (Bool, String) {
        let initBLE = bleManager.startScan(scanFilter: self.scanFilters)
        if initBLE.0 {
            startTimer()
            return initBLE
        } else {
            return initBLE
        }
    }
    
    public func stop() {
        stopTimer()
    }
    
    public func setBluetoothValidTime(value: Double) {
        self.bleManager.setBluetoothValidTime(value: value)
    }
    
    public func getBluetoothValidTime() -> Double {
        return self.bleManager.getBluetoothValidTime()
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
        let trimmedResult = RFDFunctions.shared.trimBleData(bleInput: bleDictionary, nowTime: currentTime, validTime: self.bleValidTime)
        
        let data: ReceivedForce
        var info = RFDInfo.success
        switch trimmedResult {
        case .success(let trimmedBLE):
            let bleAvg = RFDFunctions.shared.avgBleData(bleDictionary: trimmedBLE)
            data = ReceivedForce(user_id: self.user_id, mobile_time: Int(currentTime), ble: bleAvg, pressure: 0)
        case .failure(_):
            data = ReceivedForce(user_id: self.user_id, mobile_time: Int(currentTime), ble: [String: Double](), pressure: 0)
            info = .fail
        }
        
        delegate?.didGenerateReceivedForce(self, receivedForce: data, info: info)
    }
}
