import CoreBluetooth
import Foundation

let UUIDService     = CBUUID(string: BLEConstants.NRF_UUID_SERVICE)
let UUIDRead        = CBUUID(string: BLEConstants.NRF_UUID_CHAR_READ)
let UUIDWrite       = CBUUID(string: BLEConstants.NRF_UUID_CHAR_WRITE)
let NIService       = CBUUID(string: BLEConstants.NI_UUID_SERVICE)
let oneServiceUUID  = CBUUID(string: BLEConstants.TJLABS_WARD_UUID)

class TJLabsBluetoothManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    var centralManager: CBCentralManager!
    var peripherals = [CBPeripheral]()
    var devices = [(name:String, device:CBPeripheral, RSSI:NSNumber)]()
    
    var discoveredPeripheral: CBPeripheral!
    var readCharacteristic: CBCharacteristic?
    var writeCharacteristic: CBCharacteristic?
    
    var identifier: String = ""
    
    var authorized: Bool = false
    var bluetoothReady:Bool = false
    var connected:Bool = false
    var isDeviceReady: Bool = false
    var isTransferring: Bool = false
    var isScanning: Bool = false
    var tryToConnect: Bool = false
    var foundDevices = [String]()
    
    var waitTimer: Timer? = nil
    var waitTimerCounter: Int = 0

    var scanFilters = [RFD_SCAN_FILTER]()
    var bleDictionary = [String: [[Double]]]()
    
    var bleLastScannedTime: Double = 0
    var wardLastScannedTime: Double = 0
    var bleScanWindowTime: Double = 1000
    var minRssiThreshold: Int = -100
    var maxRssiThreshold: Int = -40
    
    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: nil, options: nil)
        self.bleLastScannedTime = TJLabsUtilFunctions.shared.getCurrentTimeInMillisecondsDouble()
    }
    
    func setBleScanWindowTime(value: Double) {
        self.bleScanWindowTime = value
    }
    
    func getBleScanWindowTime() -> Double {
        return self.bleScanWindowTime
    }
    
    func getWardLastScanTime() -> Double {
        return self.wardLastScannedTime
    }
    
    func setMinRssiThreshold(value: Int) {
        self.minRssiThreshold = value
    }
    
    func setMaxRssiThreshold(value: Int) {
        self.maxRssiThreshold = value
    }
    
    func getBLEDictionary() -> [String: [[Double]]] {
        return self.bleDictionary
    }
    
    func startScan(scanFilter: [RFD_SCAN_FILTER]) -> (Bool, String) {
        let localTime: String = TJLabsUtilFunctions.shared.getLocalTimeString()
        let message: String = localTime + " , " + CommonConstants.COMMON_HEADER
        
        if centralManager.isScanning {
            stopScan()
        }
        
        if bluetoothReady {
            self.centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey : NSNumber(value: true as Bool)])
            self.isScanning = true
            self.scanFilters = scanFilter
            NotificationCenter.default.post(name: .tjlabsStartScan, object: nil)
            let succssMessage = message + " Success : Bluetooth Initialization"
            return (true, succssMessage)
        } else {
            let failMessage = message +  " Error : Bluetooth Initialization"
            return (false, failMessage)
        }
    }
    
    func stopScan() {
        self.centralManager.stopScan()
        self.isScanning = false
        self.bleDictionary = [String: [[Double]]]()
        self.scanFilters = [RFD_SCAN_FILTER]()
        NotificationCenter.default.post(name: .tjlabsStopScan, object: nil)
    }
    
    private func containsScanFilter(scanFilter: [RFD_SCAN_FILTER], bleName: String) -> Bool {
        if scanFilter.isEmpty {
            return true
        } else {
            return scanFilter.contains { bleName.contains($0.rawValue) }
        }
    }
    
    // MARK: - Bluetooth Permission
    var isBluetoothPermissionGranted: Bool {
        if #available(iOS 13.1, *) {
            return CBCentralManager.authorization == .allowedAlways
        }
        return true
    }
    
    // MARK: - CBCentralManagerDelegate
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch (central.state) {
        case .poweredOff:
            self.bluetoothReady = false
            break
        case .poweredOn:
            self.bluetoothReady = true
            NotificationCenter.default.post(name: .tjlabsBluetoothReady, object: nil, userInfo: nil)
            
            if self.centralManager.isScanning == false {
                _ = startScan(scanFilter: self.scanFilters)
            }
            break
        case .resetting:
            break
        case .unauthorized:
            break
        case .unknown:
            break
        case .unsupported:
            break
        @unknown default:
            print("CBCentralManage: unknown state")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        discoveredPeripheral = peripheral
        self.bleLastScannedTime = TJLabsUtilFunctions.shared.getCurrentTimeInMillisecondsDouble()
        if let bleName = discoveredPeripheral.name {
            if containsScanFilter(scanFilter: self.scanFilters, bleName: bleName) {
                if bleName.contains("TJ-") { self.wardLastScannedTime = self.bleLastScannedTime }
                
                let deviceIDString = bleName.substring(from: 8, to: 15)
                var userInfo = [String:String]()
                userInfo["Identifier"] = peripheral.identifier.uuidString
                userInfo["DeviceID"] = deviceIDString
                userInfo["RSSI"] = String(format: "%d", RSSI.intValue )
                
                let bleTime = TJLabsUtilFunctions.shared.getCurrentTimeInMillisecondsDouble()
                let validTime = self.bleScanWindowTime*2
                
                let RSSIIntValue = RSSI.intValue
                if RSSIIntValue != 127 && RSSIIntValue >= self.minRssiThreshold && RSSIIntValue <= self.maxRssiThreshold {
                    let condition: ((String, [[Double]])) -> Bool = {
                        $0.0.contains(bleName)
                    }
                    
                    var bleScanned = self.bleDictionary.mapValues { $0.map { $0 } }
                    let rssiValue = RSSI.doubleValue
                    if (bleScanned.contains(where: condition)) {
                        let data = bleScanned.filter(condition)
                        var value:[[Double]] = data[bleName]!
                        
                        let dataToAdd: [Double] = [rssiValue, bleTime]
                        value.append(dataToAdd)
                        
                        bleScanned.updateValue(value, forKey: bleName)
                    } else {
                        bleScanned.updateValue([[rssiValue, bleTime]], forKey: bleName)
                    }
                    let trimmedResult = TJLabsBluetoothFunctions.shared.trimBleData(bleInput: bleScanned, nowTime: bleTime, scanWindowTime: bleScanWindowTime)
                    switch trimmedResult {
                    case .success(let trimmedData):
                        self.bleDictionary = trimmedData
                    case .failure(let error):
                        print(TJLabsUtilFunctions.shared.getLocalTimeString() + " , " + CommonConstants.COMMON_HEADER + " Error : BluetoothManager \(error)")
                    }
                }
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to \(peripheral).(\(error!.localizedDescription))")
        self.connected = false
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        self.discoveredPeripheral.delegate = self
        self.connected = true
        
        var userInfo = [String:String]()
        userInfo["Identifier"] = peripheral.identifier.uuidString
        NotificationCenter.default.post(name: .tjlabsDeviceConnected, object: nil, userInfo: userInfo)
        discoveredPeripheral.discoverServices([UUIDService])
    }
    
    // MARK: - CBPeripheralDelegate
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Error discovering services: \(error.localizedDescription)")
            return
        }
        
        for service in (peripheral.services)! {
            discoveredPeripheral.discoverCharacteristics([UUIDRead, UUIDWrite], for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("Error discovering services: \(error.localizedDescription)")
            return
        }
        
        for characteristic in (service.characteristics)! {
            if characteristic.uuid.isEqual(UUIDRead) {
                readCharacteristic = characteristic
                if readCharacteristic!.isNotifying != true {
                    discoveredPeripheral.setNotifyValue(true, for: readCharacteristic!)
                }
            }
            if characteristic.uuid.isEqual(UUIDWrite) {
                writeCharacteristic = characteristic
                var userInfo = [String:String]()
                userInfo["Identifier"] = peripheral.identifier.uuidString
                NotificationCenter.default.post(name: .tjlabsDeviceReady, object: nil, userInfo: userInfo)
                isDeviceReady = true
            }
        }
    }
    
    func isConnected() -> Bool {
        return connected
    }
    
    func disconnectAll() {
        if discoveredPeripheral != nil {
            centralManager.cancelPeripheralConnection(discoveredPeripheral)
        }
    }
    
    // Eddystone parsing
    func parseURLFromFrame(frameData: NSData) -> NSURL? {
        if frameData.length > 0 {
            let count = frameData.length
            var frameBytes = [UInt8](repeating: 0, count: count)
            frameData.getBytes(&frameBytes, length: count)
            
            if let URLPrefix = URLPrefixFromByte(schemeID: frameBytes[2]) {
                var output = URLPrefix
                for i in 3..<frameBytes.count {
                    if let encoded = encodedStringFromByte(charVal: frameBytes[i]) {
                        output.append(encoded)
                    }
                }
                return NSURL(string: output)
            }
        }
        
        return nil
    }
    
    func URLPrefixFromByte(schemeID: UInt8) -> String? {
        switch schemeID {
        case 0x00:
            return "http://www."
        case 0x01:
            return "https://www."
        case 0x02:
            return "http://"
        case 0x03:
            return "https://"
        default:
            return nil
        }
    }
    
    func encodedStringFromByte(charVal: UInt8) -> String? {
        switch charVal {
        case 0x00:
            return ".com/"
        case 0x01:
            return ".org/"
        case 0x02:
            return ".edu/"
        case 0x03:
            return ".net/"
        case 0x04:
            return ".info/"
        case 0x05:
            return ".biz/"
        case 0x06:
            return ".gov/"
        case 0x07:
            return ".com"
        case 0x08:
            return ".org"
        case 0x09:
            return ".edu"
        case 0x0a:
            return ".net"
        case 0x0b:
            return ".info"
        case 0x0c:
            return ".biz"
        case 0x0d:
            return ".gov"
        default:
            return String(data: Data(bytes: [ charVal ] as [UInt8], count: 1), encoding: .utf8)
        }
    }
}
