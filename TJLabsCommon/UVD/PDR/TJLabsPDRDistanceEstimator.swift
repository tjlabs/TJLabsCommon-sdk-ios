import Foundation

class TJLabsPDRDistanceEstiamtor: NSObject {
    
    override init() { }
    
    var peakValleyDetector = TJLabsPeakValleyDetector()
    var stepLengthEstimator = TJLabsStepLengthEstimator()
    var preAccNormEMA: Double = 0
    var accNormEMAQueue = LinkedList<TimestampDouble>()
    var finalUnitResult = UnitDistance()
    
    var accPeakQueue = LinkedList<TimestampDouble>()
    var accValleyQueue = LinkedList<TimestampDouble>()
    var pastIndexChangedTime: Double = 0
    
    private let avgNormAccWindow: Int = 20
    private let accNormEmaQueueSize: Int = 3
    private let accPvQueueSize: Int = 3
    
    func getDefaultStepLength() -> Double {
        return stepLengthEstimator.getDefaultStepLength()
    }
    
    func getMinStepLength() -> Double {
        return stepLengthEstimator.getMinStepLength()
    }
    
    func getMaxStepLength() -> Double {
        return stepLengthEstimator.getMaxStepLength()
    }
    
    func setDefaultStepLength(length: Double) {
        self.stepLengthEstimator.setDefaultStepLength(length: length)
    }
    
    func setMinStepLength(length: Double) {
        self.stepLengthEstimator.setMinStepLength(length: length)
    }
    
    func setMaxStepLength(length: Double) {
        self.stepLengthEstimator.setMaxStepLength(length: length)
    }
    
    func estimateDistanceInfo(time: Double, sensorData: SensorData) -> UnitDistance {
        let accNorm = TJLabsUtilFunctions.shared.l2Normalize(originalVector: sensorData.acc)
        
        // EMA를 통해 센서의 노이즈를 줄임
        let accNormEMA = TJLabsUtilFunctions.shared.exponentialMovingAverage(preEMA: preAccNormEMA, curValue: accNorm, windowSize: avgNormAccWindow)
        preAccNormEMA = accNormEMA
        
        if (accNormEMAQueue.count < accNormEmaQueueSize) {
            accNormEMAQueue.append(TimestampDouble(timestamp: time, valuestamp: accNormEMA))
            return UnitDistance()
        } else {
            _ = accNormEMAQueue.pop()
            accNormEMAQueue.append(TimestampDouble(timestamp: time, valuestamp: accNormEMA))
        }
        
        let foundAccPV = peakValleyDetector.findPeakValley(smoothedNormAcc: accNormEMAQueue)
        updateAccQueue(pvStruct: foundAccPV)
        
        finalUnitResult.isIndexChanged = false
        if (foundAccPV.type == SensorPatternType.PEAK) {
            finalUnitResult.index += 1
            finalUnitResult.isIndexChanged = true
            
            var diffTime = foundAccPV.timestamp - pastIndexChangedTime
            if diffTime > 1000 {
                diffTime = 1000
            }
            pastIndexChangedTime = foundAccPV.timestamp
            finalUnitResult.length = stepLengthEstimator.estStepLength(accPeakQueue: accPeakQueue, accValleyQueue: accValleyQueue)
            
            var velocityKmph = (finalUnitResult.length / diffTime * 1000) * 3.6
            if velocityKmph >= 5.2 {
                velocityKmph = 5.2
            }
            finalUnitResult.velocity = velocityKmph
        }
        
        return finalUnitResult
    }
    
    func updateAccQueue(pvStruct: PeakValleyStruct) {
        if (pvStruct.type == SensorPatternType.PEAK) {
            updateAccPeakQueue(pvStruct: pvStruct)
        } else if (pvStruct.type == SensorPatternType.VALLEY) {
            updateAccValleyQueue(pvStruct: pvStruct)
        }
    }
    
    func updateAccPeakQueue(pvStruct: PeakValleyStruct) {
        if (accPeakQueue.count >= accPvQueueSize) {
            _ = accPeakQueue.pop()
        }
        accPeakQueue.append(TimestampDouble(timestamp: pvStruct.timestamp, valuestamp: pvStruct.pvValue))
    }
    
    func updateAccValleyQueue(pvStruct: PeakValleyStruct) {
        if (accValleyQueue.count >= accPvQueueSize) {
            _ = accValleyQueue.pop()
        }
        accValleyQueue.append(TimestampDouble(timestamp: pvStruct.timestamp, valuestamp: pvStruct.pvValue))
    }
}
