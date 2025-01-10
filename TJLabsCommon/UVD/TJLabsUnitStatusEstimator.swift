
import Foundation

class TJLabsUnitStatusEstimator: NSObject {
    override init() { }
    
    var lookingFlagStepQueue = LinkedList<Bool>()
    let lookingFlagCheckIndexSize: Int = 3
    
    func estimateStatus(attDegree: Attitude, isIndexChanged: Bool) -> Bool {
        if (isIndexChanged) {
            let isLookingAttitude = (abs(attDegree.roll) < 25 && attDegree.pitch > -20 && attDegree.pitch < 80)
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

            return bufferSum >= (lookingFlagCheckIndexSize-1) ? true : false
        }
    }
    
    func updateIsLookingAttitudeQueue(lookingFlag: Bool) {
        if (lookingFlagStepQueue.count >= lookingFlagCheckIndexSize) {
            _ = lookingFlagStepQueue.pop()
        }
        lookingFlagStepQueue.append(lookingFlag)
    }
}
