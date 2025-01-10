
import Foundation

class TJLabsUnitStatusEstimator: NSObject {
    override init() { }
    
    var lookingFlagStepQueue = LinkedList<Bool>()
    let lookingFlagCheckIndexSize: Int = 3
    
    func estimateStatus(Attitude: Attitude, isIndexChanged: Bool) -> Bool {
        if (isIndexChanged) {
            let isLookingAttitude = (abs(Attitude.roll) < TJLabsUtilFunctions.shared.degree2radian(degree: 25) && Attitude.pitch > TJLabsUtilFunctions.shared.degree2radian(degree: -20) && Attitude.pitch < TJLabsUtilFunctions.shared.degree2radian(degree: 80))
            updateIsLookingAttitudeQueue(lookingFlag: isLookingAttitude)
            return checkLookingAttitude(lookingFlagStepQueue: lookingFlagStepQueue)
        } else {
            return false
        }
    }
    
    func checkLookingAttitude(lookingFlagStepQueue: LinkedList<Bool>) -> Bool {
        if (lookingFlagStepQueue.count < lookingFlagCheckIndexSize) {
            return true
        } else {
            var bufferSum = 0
            for i in 0..<lookingFlagStepQueue.count {
                let value = lookingFlagStepQueue.node(at: i)!.value
                if (value) { bufferSum += 1 }
            }

            if bufferSum < lookingFlagCheckIndexSize {
                return false
            } else {
                return true
            }
        }
    }
    
    func updateIsLookingAttitudeQueue(lookingFlag: Bool) {
        if (lookingFlagStepQueue.count >= lookingFlagCheckIndexSize) {
            _ = lookingFlagStepQueue.pop()
        }
        lookingFlagStepQueue.append(lookingFlag)
    }
}
