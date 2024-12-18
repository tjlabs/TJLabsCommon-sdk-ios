import CoreMotion
import CoreLocation
import simd
import Foundation

public class TJLabsSensorManager: NSObject, CLLocationManagerDelegate {
    var sensorData = TJLabsSensorData()
    var collectData = TJLabsCollectData()
    
//    let magField = CMMagneticField()
    let locationManager = CLLocationManager()
    let motionManager = CMMotionManager()
    let motionAltimeter = CMAltimeter()
    
    var pitch: Double  = 0
    var roll: Double = 0
    var yaw: Double = 0
    
    var magX: Double = 0
    var magY: Double = 0
    var magZ: Double = 0
    var pressure: Double = 0
    
    var runMode: String = ""
    
    var heading: Double?
    var magneticDeclination: Double = 0
    var headingQueue = [Double]()
    var curMagneticHeading: Double = 0
    var preMagneticHeading: Double = 0
    
    var abnormalMagCount: Int = 0
    var isVenusMode: Bool = false {
        didSet {
            if isVenusMode {
                NotificationCenter.default.post(name: .tjlabsDidEnterVenusMode, object: nil)
            } else {
                NotificationCenter.default.post(name: .tjlabsDidExitVenusMode, object: nil)
            }
        }
    }
    
    override public init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingHeading()
    }
    
    public func initSensors() -> (Bool, String) {
        var isSuccess: Bool = false
        var message: String = ""
        var unavailableSensors = [String]()
        
        var sensorActive: Int = 0
        if motionManager.isAccelerometerAvailable {
            sensorActive += 1
            motionManager.accelerometerUpdateInterval = UVDConstants.SENSOR_INTERVAL
            motionManager.startAccelerometerUpdates(to: .main) { [self] (data, error) in
                if let accX = data?.acceleration.x {
                    sensorData.acc[0] = -accX*UVDConstants.G
                    collectData.acc[0] = -accX*UVDConstants.G
                }
                if let accY = data?.acceleration.y {
                    sensorData.acc[1] = -accY*UVDConstants.G
                    collectData.acc[1] = -accY*UVDConstants.G
                }
                if let accZ = data?.acceleration.z {
                    sensorData.acc[2] = -accZ*UVDConstants.G
                    collectData.acc[2] = -accZ*UVDConstants.G
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
            motionManager.magnetometerUpdateInterval = UVDConstants.SENSOR_INTERVAL
            motionManager.startMagnetometerUpdates(to: .main) { [self] (data, error) in
                if let magX = data?.magneticField.x {
                    sensorData.mag[0] = magX
                    collectData.mag[0] = magX
                }
                if let magY = data?.magneticField.y {
                    sensorData.mag[1] = magY
                    collectData.mag[1] = magY
                }
                if let magZ = data?.magneticField.z {
                    sensorData.mag[2] = magZ
                    collectData.mag[2] = magZ
                }
                
                let norm = sqrt(sensorData.mag.reduce(0) { $0 + $1 * $1 })
                if (norm > UVDConstants.ABNORMAL_MAG_THRESHOLD || norm == 0) {
                    self.abnormalMagCount += 1
                } else {
                    self.abnormalMagCount = 0
                }
                
                if (self.abnormalMagCount >= UVDConstants.ABNORMAL_MAG_COUNT) {
                    self.abnormalMagCount = UVDConstants.ABNORMAL_MAG_COUNT
                    if (!self.isVenusMode && self.runMode == CommonConstants.MODE_DR) {
                        self.isVenusMode = true
//                        NotificationCenter.default.post(name: .didBecomeVenus, object: nil, userInfo: nil)
                    }
                } else {
                    if (self.isVenusMode) {
                        self.isVenusMode = false
//                        NotificationCenter.default.post(name: .didBecomeJupiter, object: nil, userInfo: nil)
                    }
                }
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
                    collectData.pressure[0] = pressure_
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
            motionManager.deviceMotionUpdateInterval = UVDConstants.SENSOR_INTERVAL
            motionManager.startDeviceMotionUpdates(to: .main) { [self] (motion, error) in
                if let m = motion {
                    // Calibrated Gyro
                    sensorData.gyro[0] = m.rotationRate.x
                    sensorData.gyro[1] = m.rotationRate.y
                    sensorData.gyro[2] = m.rotationRate.z
                    
                    collectData.gyro[0] = m.rotationRate.x
                    collectData.gyro[1] = m.rotationRate.y
                    collectData.gyro[2] = m.rotationRate.z
                    
                    sensorData.userAcc[0] = -m.userAcceleration.x*UVDConstants.G
                    sensorData.userAcc[1] = -m.userAcceleration.y*UVDConstants.G
                    sensorData.userAcc[2] = -m.userAcceleration.z*UVDConstants.G
                    
                    collectData.userAcc[0] = -m.userAcceleration.x*UVDConstants.G
                    collectData.userAcc[1] = -m.userAcceleration.y*UVDConstants.G
                    collectData.userAcc[2] = -m.userAcceleration.z*UVDConstants.G
                    
                    sensorData.att[0] = m.attitude.roll
                    sensorData.att[1] = m.attitude.pitch
                    sensorData.att[2] = m.attitude.yaw
                    
                    collectData.att[0] = m.attitude.roll
                    collectData.att[1] = m.attitude.pitch
                    collectData.att[2] = m.attitude.yaw
                    
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
                    
                    collectData.rotationMatrix[0][0] = m.attitude.rotationMatrix.m11
                    collectData.rotationMatrix[0][1] = m.attitude.rotationMatrix.m12
                    collectData.rotationMatrix[0][2] = m.attitude.rotationMatrix.m13
                                    
                    collectData.rotationMatrix[1][0] = m.attitude.rotationMatrix.m21
                    collectData.rotationMatrix[1][1] = m.attitude.rotationMatrix.m22
                    collectData.rotationMatrix[1][2] = m.attitude.rotationMatrix.m23
                                    
                    collectData.rotationMatrix[2][0] = m.attitude.rotationMatrix.m31
                    collectData.rotationMatrix[2][1] = m.attitude.rotationMatrix.m32
                    collectData.rotationMatrix[2][2] = m.attitude.rotationMatrix.m33
                    
                    collectData.quaternion[0] = m.attitude.quaternion.x
                    collectData.quaternion[1] = m.attitude.quaternion.y
                    collectData.quaternion[2] = m.attitude.quaternion.z
                    collectData.quaternion[3] = m.attitude.quaternion.w
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
    
    public func getSensorData() -> TJLabsSensorData {
        return self.sensorData
    }
    
    public func getCollecttData() -> TJLabsCollectData {
        return self.collectData
    }
    
    public func setRunMode(mode: String) {
        self.runMode = mode
    }
    
    public func getTrueHeading() -> Double? {
        return self.heading
    }
    
    public func getAzimuthHeading() -> Double? {
        return calculateAzimuthHeading()
    }
    
    public func getMagneticHeading() -> Double {
        return self.curMagneticHeading
    }
    
    public func getSmoothedMagneticHeading() -> Double {
        return self.preMagneticHeading
    }
    
    func updateHeadingQueue(data: Double) {
        if (self.headingQueue.count >= 10) {
            self.headingQueue.remove(at: 0)
        }
        self.headingQueue.append(data)
    }
    
    func smoothMagneticHeading(heading: Double) -> Double {
        var smoothedHeading: Double = 1.0
        if (self.headingQueue.count == 1) {
            smoothedHeading = heading
        } else {
            smoothedHeading = TJLabsUtilFunctions.shared.movingAverage(preMvalue: preMagneticHeading, curValue: heading, windowSize: headingQueue.count)
        }
        return smoothedHeading
    }
    
    func calculateAzimuthHeading() -> Double? {
        let mx = sensorData.mag[0]
        let my = sensorData.mag[1]
        let mz = sensorData.mag[2]
        
        let ax = sensorData.acc[0]
        let ay = sensorData.acc[1]
        let az = sensorData.acc[2]
        
//        let gravity = simd_double3(ax, ay, az)
//        let gravity = simd_double3(sensorData.grav[0], sensorData.grav[1], sensorData.grav[2])
        let gravity = simd_double3(ax, ay, az)
        let magnetic = simd_double3(mx, my, mz)
        
        // Calculate east and north vectors
        let east = simd_cross(magnetic, gravity)
        let north = simd_cross(gravity, east)
        
        // Normalize vectors
        let normalizedEast = simd_normalize(east)
        let normalizedNorth = simd_normalize(north)
        
        // Compute azimuth (in radians)
        let azimuth = atan2(normalizedEast.y, normalizedNorth.y)
        
        // Convert azimuth to degrees
        var azimuthDegrees = azimuth * (180 / .pi)
        azimuthDegrees = (azimuthDegrees + 360).truncatingRemainder(dividingBy: 360)
        
        return azimuthDegrees
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
//        self.heading = newHeading.magneticHeading
        self.heading = newHeading.trueHeading
        
        sensorData.trueHeading = newHeading.trueHeading
        sensorData.magneticHeading = newHeading.magneticHeading
        
        collectData.trueHeading = newHeading.trueHeading
        collectData.magneticHeading = newHeading.magneticHeading
        
//        print(getLocalTimeString() + " , (Heading Info) : True = \(self.heading) // Mag = \(newHeading.magneticHeading) // Azimuth = \(getAzimuthHeading())")
        
//        let magneticHeading = newHeading.magneticHeading
//        curMagneticHeading = magneticHeading
//        updateHeadingQueue(data: magneticHeading)
//        let smoothedHeading = smoothMagneticHeading(heading: magneticHeading)
//        preMagneticHeading = smoothedHeading
//
//        print(getLocalTimeString() + " , (Olympus) SensorData : Smoothed = \(preMagneticHeading) // Raw = \(magneticHeading)")
    }
}
