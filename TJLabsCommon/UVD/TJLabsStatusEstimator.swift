import Foundation

class TJLabsStatusEstimator: NSObject {
    
    override init() { }
    
    var lookingFlagStepQueue = LinkedList<Bool>()
    
    func estStatus(Attitude: Attitude, isIndexChanged: Bool, unitMode: String) -> Bool {
        if (unitMode == CommonConstants.MODE_PDR) {
            if (isIndexChanged) {
                let isLookingAttitude = (abs(Attitude.Roll) < TJLabsMathFunctions.shared.degree2radian(degree: 25) && Attitude.Pitch > TJLabsMathFunctions.shared.degree2radian(degree: -20) && Attitude.Pitch < TJLabsMathFunctions.shared.degree2radian(degree: 80))
                
                updateIsLookingAttitudeQueue(lookingFlag: isLookingAttitude)
                let flag: Bool = checkLookingAttitude(lookingFlagStepQueue: lookingFlagStepQueue)
                
                return flag
            } else {
                return false
            }
        } else {
            return true
        }
    }
    
    func checkLookingAttitude(lookingFlagStepQueue: LinkedList<Bool>) -> Bool {
        if (lookingFlagStepQueue.count <= 2) {
            return true
        } else {
            var bufferSum = 0
            for i in 0..<lookingFlagStepQueue.count {
                let value = lookingFlagStepQueue.node(at: i)!.value
                if (value) { bufferSum += 1 }
            }
            
            if (bufferSum >= 2) {
                return true
            } else {
                return false
            }
        }
    }
    
    func updateIsLookingAttitudeQueue(lookingFlag: Bool) {
        if (lookingFlagStepQueue.count >= UVDConstants.LOOKING_FLAG_STEP_CHECK_SIZE) {
            _ = lookingFlagStepQueue.pop()
        }
        lookingFlagStepQueue.append(lookingFlag)
    }
}
