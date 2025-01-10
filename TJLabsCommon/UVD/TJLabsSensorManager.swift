import CoreMotion
import CoreLocation
import simd
import Foundation

public class TJLabsSensorManager: NSObject {
    let GRAVITY: Double = 9.81
    let SENSOR_INTERVAL: TimeInterval = 1/100
    
    var sensorData = SensorData()
    
    let motionManager = CMMotionManager()
    let motionAltimeter = CMAltimeter()
    
    var pitch: Double = 0
    var roll: Double = 0
    var yaw: Double = 0
    
    var magX: Double = 0
    var magY: Double = 0
    var magZ: Double = 0
    var pressure: Double = 0
    
    var runMode: String = ""
    var abnormalMagCount: Int = 0
//    var isVenusMode: Bool = false {
//        didSet {
//            if isVenusMode {
//                NotificationCenter.default.post(name: .tjlabsDidEnterVenusMode, object: nil)
//            } else {
//                NotificationCenter.default.post(name: .tjlabsDidExitVenusMode, object: nil)
//            }
//        }
//    }
    
    override public init() {
        super.init()
    }
    
    public func initSensorManager() -> (Bool, String) {
        var isSuccess: Bool = false
        var message: String = ""
        var unavailableSensors = [String]()
        
        var sensorActive: Int = 0
        if motionManager.isAccelerometerAvailable {
            sensorActive += 1
            motionManager.accelerometerUpdateInterval = SENSOR_INTERVAL
            motionManager.startAccelerometerUpdates(to: .main) { [self] (data, error) in
                if let accX = data?.acceleration.x {
                    sensorData.acc[0] = -accX*GRAVITY
                }
                if let accY = data?.acceleration.y {
                    sensorData.acc[1] = -accY*GRAVITY
                }
                if let accZ = data?.acceleration.z {
                    sensorData.acc[2] = -accZ*GRAVITY
                }
            }
        } else {
            let localTime: String = TJLabsUtilFunctions.shared.getLocalTimeString()
            unavailableSensors.append("Acc")
            let log: String = localTime + " , " + CommonConstants.COMMON_HEADER + " Error : Fail to initialize accelerometer"
            print(log)
        }
        
        
        if motionManager.isMagnetometerAvailable {
            sensorActive += 1
            // Uncalibrated
            motionManager.magnetometerUpdateInterval = SENSOR_INTERVAL
            motionManager.startMagnetometerUpdates(to: .main) { [self] (data, error) in
                if let magX = data?.magneticField.x {
                    sensorData.mag[0] = magX
                }
                if let magY = data?.magneticField.y {
                    sensorData.mag[1] = magY
                }
                if let magZ = data?.magneticField.z {
                    sensorData.mag[2] = magZ
                }
                
//                let norm = sqrt(sensorData.mag.reduce(0) { $0 + $1 * $1 })
//                if (norm > UVDConstants.ABNORMAL_MAG_THRESHOLD || norm == 0) {
//                    self.abnormalMagCount += 1
//                } else {
//                    self.abnormalMagCount = 0
//                }
//                
//                if (self.abnormalMagCount >= UVDConstants.ABNORMAL_MAG_COUNT) {
//                    self.abnormalMagCount = UVDConstants.ABNORMAL_MAG_COUNT
//                    if (!self.isVenusMode && self.runMode == CommonConstants.MODE_DR) {
//                        self.isVenusMode = true
//                        NotificationCenter.default.post(name: .didBecomeVenus, object: nil, userInfo: nil)
//                    }
//                } else {
//                    if (self.isVenusMode) {
//                        self.isVenusMode = false
//                        NotificationCenter.default.post(name: .didBecomeJupiter, object: nil, userInfo: nil)
//                    }
//                }
            }
        } else {
            let localTime: String = TJLabsUtilFunctions.shared.getLocalTimeString()
            unavailableSensors.append("Mag")
            let log: String = localTime + " , " + CommonConstants.COMMON_HEADER + " Error : Fail to initialize magnetometer\n"
            print(log)
        }
        
        if CMAltimeter.isRelativeAltitudeAvailable() {
//            sensorActive += 1
            motionAltimeter.startRelativeAltitudeUpdates(to: .main) { [self] (data, error) in
                if let pressure = data?.pressure {
                    let pressure_: Double = round(Double(truncating: pressure)*10*100)/100
                    self.pressure = pressure_
                    sensorData.pressure[0] = pressure_
                }
            }
        } else {
            let localTime: String = TJLabsUtilFunctions.shared.getLocalTimeString()
            unavailableSensors.append("Pressure")
            let log: String = localTime + " , " + CommonConstants.COMMON_HEADER + " Error : Fail to initialize pressure sensor"
            print(log)
        }
        
        if motionManager.isDeviceMotionAvailable {
            sensorActive += 1
            motionManager.deviceMotionUpdateInterval = SENSOR_INTERVAL
            motionManager.startDeviceMotionUpdates(to: .main) { [self] (motion, error) in
                if let m = motion {
                    // Calibrated Gyro
                    sensorData.gyro[0] = m.rotationRate.x
                    sensorData.gyro[1] = m.rotationRate.y
                    sensorData.gyro[2] = m.rotationRate.z
                    
                    sensorData.userAcc[0] = -m.userAcceleration.x*GRAVITY
                    sensorData.userAcc[1] = -m.userAcceleration.y*GRAVITY
                    sensorData.userAcc[2] = -m.userAcceleration.z*GRAVITY
                    
                    sensorData.att[0] = m.attitude.roll
                    sensorData.att[1] = m.attitude.pitch
                    sensorData.att[2] = m.attitude.yaw
                    
                    
                    sensorData.grav[0] = m.gravity.x
                    sensorData.grav[1] = m.gravity.y
                    sensorData.grav[2] = m.gravity.z
                    
                    sensorData.rotationMatrix[0][0] = m.attitude.rotationMatrix.m11
                    sensorData.rotationMatrix[0][1] = m.attitude.rotationMatrix.m12
                    sensorData.rotationMatrix[0][2] = m.attitude.rotationMatrix.m13
                                    
                    sensorData.rotationMatrix[1][0] = m.attitude.rotationMatrix.m21
                    sensorData.rotationMatrix[1][1] = m.attitude.rotationMatrix.m22
                    sensorData.rotationMatrix[1][2] = m.attitude.rotationMatrix.m23
                                    
                    sensorData.rotationMatrix[2][0] = m.attitude.rotationMatrix.m31
                    sensorData.rotationMatrix[2][1] = m.attitude.rotationMatrix.m32
                    sensorData.rotationMatrix[2][2] = m.attitude.rotationMatrix.m33
                }
            }
        } else {
            let localTime: String = TJLabsUtilFunctions.shared.getLocalTimeString()
            unavailableSensors.append("Motion")
            let log: String = localTime + " , " + CommonConstants.COMMON_HEADER + " Error : Fail to initialize motion sensor"
            print(log)
        }
        
        let localTime: String = TJLabsUtilFunctions.shared.getLocalTimeString()
        if (sensorActive >= 3) {
            let log: String = localTime + " , " + CommonConstants.COMMON_HEADER + " Success : Sensor Initialization"
            
            isSuccess = true
            message = log
        } else {
            let log: String = localTime + " , " + CommonConstants.COMMON_HEADER + " Error : Sensor is not available \(unavailableSensors)"
            
            isSuccess = false
            message = log
        }
        return (isSuccess, message)
    }
    
    public func getSensorData() -> SensorData {
        return self.sensorData
    }
    
    public func setRunMode(mode: String) {
        self.runMode = mode
    }
}
