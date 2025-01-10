
import Foundation

public class UVDGenerator: NSObject {
    public weak var delegate: UVDGeneratorDelegate?
    var sensorManager = TJLabsSensorManager()
    var userVelocityTimer: DispatchSourceTimer?
    var timerInterval: TimeInterval = 1/40
    
    var user_id: String = "Unknown"
    var uvdGenerationTimeMillis: Double = 0
    var userMode = UserMode.MODE_PEDESTRIAN
    
    public init(id: String) {
        self.user_id = id
    }
    
    public func setUserMode(mode: UserMode) {
        self.userMode = mode
    }
    
    public func updateDrVelocityScale(scale: Double) {
        // TODO
    }
    
    
    func getZeroVelocityAfterSeconds() -> Double {
        return 0
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
        
    }
    
    func generatePedestrainUvd() {
        
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
            print("GG")
        case .MODE_VEHICLE:
            print("GG")
        case .MODE_AUTO:
            print("GG")
        }
//        delegate?.onRFDResult(self, receivedForce: data, info: info)
    }
}
