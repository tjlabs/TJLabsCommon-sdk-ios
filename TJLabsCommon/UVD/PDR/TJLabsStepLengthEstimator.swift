
import Foundation

class TJLabsStepLengthEstimator: NSObject {
    
    override init() {
        self.preStepLength = self.defaultStepLength
        self.differencePvThreshold = (self.midStepLength - self.defaultStepLength)/self.alpha + self.differencePvStandard
    }
    
    var defaultStepLength: Double = 0.6
    var minStepLength: Double = 0.5
    var maxStepLength: Double = 0.7
    
    var preStepLength: Double = 0.6
    var alpha: Double = 0.45
    var differencePvStandard: Double = 0.83
    var midStepLength: Double = 0.5
    var minDifferencePv: Double = 0.5
    var compensationWeight: Double = 0.85
    var compensationBias: Double = 0.1
    var differencePvThreshold: Double = 0
    
    func getDefaultStepLength() -> Double {
        return defaultStepLength
    }
    
    func getMinStepLength() -> Double {
        return minStepLength
    }
    
    func getMaxStepLength() -> Double {
        return maxStepLength
    }
    
    func setDefaultStepLength(length: Double) {
        self.defaultStepLength = length
    }
    
    func setMinStepLength(length: Double) {
        self.minStepLength = length
    }
    
    func setMaxStepLength(length: Double) {
        self.maxStepLength = length
    }
    
    func estStepLength(accPeakQueue: LinkedList<TimestampDouble>, accValleyQueue: LinkedList<TimestampDouble>) -> Double {
        if (accPeakQueue.count < 1 || accValleyQueue.count < 1) {
            return defaultStepLength
        }
        
        let differencePV = accPeakQueue.last!.value.valuestamp - accValleyQueue.last!.value.valuestamp
        var stepLength = differencePV > differencePvThreshold ? calLongStepLength(differencePV: differencePV) : calShortStepLength(differencePV: differencePV)
        stepLength = compensateStepLength(curStepLength: stepLength)
        return limitStepLength(stepLength: stepLength)
    }
    
    func calLongStepLength(differencePV: Double) -> Double {
        return (alpha * (differencePV - differencePvStandard) + defaultStepLength)
    }
    
    func calShortStepLength(differencePV: Double) -> Double {
        return ((midStepLength - minStepLength) / (differencePvStandard - minDifferencePv)) * (differencePV - differencePvThreshold) + midStepLength
    }
    
    func compensateStepLength(curStepLength: Double) -> Double {
        let compensateStepLength = compensationWeight * (curStepLength) - (curStepLength - preStepLength) * (1 - compensationWeight) + compensationBias
        preStepLength = compensateStepLength
        return compensateStepLength
    }
    
    func limitStepLength(stepLength: Double) -> Double {
        if (stepLength > maxStepLength) {
            return maxStepLength
        } else if (stepLength < minStepLength) {
            return minStepLength
        } else {
            return stepLength
        }
    }
}
