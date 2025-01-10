import Foundation

private let sensorFrequency: Double = 40

public class UVDGenerator: NSObject {
    public weak var delegate: UVDGeneratorDelegate?
    
    var userVelocityTimer: DispatchSourceTimer?
    var timerInterval: TimeInterval = 1/sensorFrequency
    var userId: String = "Unknown"
    
    var sensorManager = TJLabsSensorManager()
    var attitudeEstimator = TJLabsAttitudeEstimator(frequency: sensorFrequency)
    var pdrDistanceEstimator = TJLabsPDRDistanceEstiamtor()
    var unitStatusEstimator = TJLabsUnitStatusEstimator()
    var uvdGenerationTimeMillis: Double = 0
    var userMode = UserMode.MODE_PEDESTRIAN
    var drVelocityScale: Double = 1.0
    
    public init(userId: String) {
        self.userId = userId
    }
    
    public func setUserMode(mode: UserMode) {
        self.userMode = mode
    }
    
    public func updateDrVelocityScale(scale: Double) {
        // TODO
    }
    
    func resetVelocityAfterSeconds(velocity: Double, sec: Double = 2) -> Double {
        return TJLabsUtilFunctions.shared.getCurrentTimeInMillisecondsDouble() - self.uvdGenerationTimeMillis < sec*1000 ? velocity : 0
    }
    
    public func generateUvd(defaultPDRStepLength: Double = 0.5, minPDRStepLength: Double = 0.5, maxPDRStepLength: Double = 0.7) -> (Bool, String) {
        let initSensors = sensorManager.initSensorManager()
        if initSensors.0 {
            startTimer()
            return initSensors
        } else  {
            return initSensors
        }
    }
    
    public func stopUvdGeneration() {
        stopTimer()
        attitudeEstimator = TJLabsAttitudeEstimator(frequency: sensorFrequency)
        pdrDistanceEstimator = TJLabsPDRDistanceEstiamtor()
        unitStatusEstimator = TJLabsUnitStatusEstimator()
        uvdGenerationTimeMillis = 0
        userMode = UserMode.MODE_PEDESTRIAN
        drVelocityScale = 1.0
    }
    
    func generatePedestrainUvd(sensorData: SensorData) {
        let currentTime = TJLabsUtilFunctions.shared.getCurrentTimeInMillisecondsDouble()
        let pdrUnit = pdrDistanceEstimator.estimateDistanceInfo(time: currentTime, sensorData: sensorData)
        let attDegree = attitudeEstimator.estimateAttitudeRadian(time: currentTime, acc: sensorData.acc, gyro: sensorData.gyro, rotMatrix: sensorData.rotationMatrix).toDegree()
        let isLookingStatus = unitStatusEstimator.estimateStatus(attDegree: attDegree, isIndexChanged: pdrUnit.isIndexChanged)
        
        if pdrUnit.isIndexChanged {
            let userVelocity = UserVelocity(user_id: self.userId, mobile_time: TJLabsUtilFunctions.shared.getCurrentTimeInMilliseconds(), index: pdrUnit.index, length: pdrUnit.length, heading: attDegree.yaw, looking: isLookingStatus)
            delegate?.onUvdResult(self, userVelocity: userVelocity)
            uvdGenerationTimeMillis = currentTime
        } else {
            delegate?.onUvdPauseMillis(self, time: currentTime - uvdGenerationTimeMillis)
        }
        delegate?.onVelocityResult(self, kmPh: resetVelocityAfterSeconds(velocity: pdrUnit.velocity))
    }
    
    func generateVehicleUvd() {
        // TODO
    }
    
    func generateAutoUvd() {
        // TODO
    }
    
    func startTimer() {
        if (self.userVelocityTimer == nil) {
            let queueUvd = DispatchQueue(label: Bundle.main.bundleIdentifier! + ".userVelocityTimer")
            self.userVelocityTimer = DispatchSource.makeTimerSource(queue: queueUvd)
            self.userVelocityTimer!.schedule(deadline: .now(), repeating: timerInterval)
            self.userVelocityTimer!.setEventHandler { [weak self] in
                guard let self = self else { return }
                self.userVelocityTimerUpdate()
            }
            self.userVelocityTimer!.resume()
        }
    }
    
    func stopTimer() {
        self.userVelocityTimer?.cancel()
        self.userVelocityTimer = nil
    }
    
    func userVelocityTimerUpdate() {
        let currentTime = TJLabsUtilFunctions.shared.getCurrentTimeInMillisecondsDouble()
        let sensorData = sensorManager.getSensorData()
        switch self.userMode {
        case .MODE_PEDESTRIAN:
            self.generatePedestrainUvd(sensorData: sensorData)
        case .MODE_VEHICLE:
            print("GG")
        case .MODE_AUTO:
            print("GG")
        }
    }
}
