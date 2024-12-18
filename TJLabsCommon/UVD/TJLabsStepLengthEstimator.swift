import Foundation

class TJLabsStepLengthEstimator: NSObject {
    
    override init() { }

    var preStepLength = UVDConstants.DEFAULT_STEP_LENGTH
    
    func estStepLength(accPeakQueue: LinkedList<TimestampDouble>, accValleyQueue: LinkedList<TimestampDouble>) -> Double {
        if (accPeakQueue.count < 1 || accValleyQueue.count < 1) {
            return UVDConstants.DEFAULT_STEP_LENGTH
        }
        
        let differencePV = accPeakQueue.last!.value.valuestamp - accValleyQueue.last!.value.valuestamp
        var stepLength = UVDConstants.DEFAULT_STEP_LENGTH
        
        if (differencePV > UVDConstants.DIFFERENCE_PV_THRESHOLD) {
            stepLength = calLongStepLength(differencePV: differencePV)
        } else {
            stepLength = calShortStepLength(differencePV: differencePV)
        }
        stepLength = limitStepLength(stepLength: stepLength)
        
        return compensateStepLength(curStepLength: stepLength)
    }
    
    func calLongStepLength(differencePV: Double) -> Double {
        return (UVDConstants.ALPHA * (differencePV - UVDConstants.DIFFERENCE_PV_STANDARD) + UVDConstants.DEFAULT_STEP_LENGTH)
    }
    
    func calShortStepLength(differencePV: Double) -> Double {
        return ((UVDConstants.MID_STEP_LENGTH - UVDConstants.MIN_STEP_LENGTH) / (UVDConstants.DIFFERENCE_PV_THRESHOLD - UVDConstants.MIN_DIFFERENCE_PV)) * (differencePV - UVDConstants.DIFFERENCE_PV_THRESHOLD) + UVDConstants.MID_STEP_LENGTH
    }
    
    func compensateStepLength(curStepLength: Double) -> Double {
        let compensateStepLength = UVDConstants.COMPENSATION_WEIGHT * (curStepLength) - (curStepLength - preStepLength) * (1 - UVDConstants.COMPENSATION_WEIGHT) + UVDConstants.COMPENSATION_BIAS
        preStepLength = compensateStepLength
        
        return compensateStepLength
    }
    
    func limitStepLength(stepLength: Double) -> Double {
        if (stepLength > UVDConstants.MAX_STEP_LENGTH) {
            return UVDConstants.MAX_STEP_LENGTH
        } else if (stepLength < UVDConstants.MIN_STEP_LENGTH) {
            return UVDConstants.MIN_STEP_LENGTH
        } else {
            return stepLength
        }
    }
}
