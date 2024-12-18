import Foundation

class TJLabsPDRDistanceEstiamtor: NSObject {
    
    override init() { }
    
    var pacingDetector = TJlabsPacingDetector()
    var peakValleyDetector = TJLabsPeakValleyDetector()
    var stepLengthEstimator = TJLabsStepLengthEstimator()
    var preAccNormEMA: Double = 0
    var accNormEMAQueue = LinkedList<TimestampDouble>()
    var finalUnitResult = UnitDistance()
    
    var accPeakQueue = LinkedList<TimestampDouble>()
    var accValleyQueue = LinkedList<TimestampDouble>()
    var stepLengthQueue = LinkedList<StepLengthWithTimestamp>()
    
    var normalStepCheckCount = -1
    var normalStepLossCheckQueue = LinkedList<Int>()
    
    var normalStepCountSetting: Int = 2
    var normalStepCountFlag: Bool = false
    var autoMode: Bool = false
    var isModeDrToPdr: Bool = false
    
    var useFixedStep: Bool = false
    var fixedStepLength: Double = UVDConstants.DEFAULT_STEP_LENGTH
    
    var pastIndexChangedTime: Double = 0
    
    func normalStepCountSet(normalStepCountSet: Int) {
        self.normalStepCountSetting = normalStepCountSet
    }

    func setAutoMode(flag: Bool) {
        self.autoMode = flag
    }
    
    func setModeDrToPdr(isModeDrToPdr: Bool) {
        self.isModeDrToPdr = isModeDrToPdr
        self.normalStepCheckCount = -1
        self.normalStepLossCheckQueue = LinkedList<Int>()
    }
    
    func setUseFixedStep(flag: Bool) {
        self.useFixedStep = flag
    }
    
    func setFixedStepLength(value: Double) {
        self.fixedStepLength = value
    }
    
    func estDistanceInfo(time: Double, sensorData: TJLabsSensorData) -> UnitDistance {
        let accNorm = TJLabsMathFunctions.shared.l2Normalize(originalVector: sensorData.acc)
        
        // EMA를 통해 센서의 노이즈를 줄임
        let accNormEMA = TJLabsMathFunctions.shared.exponentialMovingAverage(preEMA: preAccNormEMA, curValue: accNorm, windowSize: UVDConstants.AVG_NORM_ACC_WINDOW)
        preAccNormEMA = accNormEMA
        
        if (accNormEMAQueue.count < UVDConstants.ACC_NORM_EMA_QUEUE_SIZE) {
            accNormEMAQueue.append(TimestampDouble(timestamp: time, valuestamp: accNormEMA))
            return UnitDistance()
        } else {
            _ = accNormEMAQueue.pop()
            accNormEMAQueue.append(TimestampDouble(timestamp: time, valuestamp: accNormEMA))
        }
        
        let foundAccPV = peakValleyDetector.findPeakValley(smoothedNormAcc: accNormEMAQueue)
        updateAccQueue(pvStruct: foundAccPV)
        
        finalUnitResult.isIndexChanged = false
        
        if (foundAccPV.type == Type.PEAK) {
            normalStepCheckCount = pacingDetector.updateNormalStepCheckCount(accPeakQueue: accPeakQueue, accValleyQueue: accValleyQueue, normalStepCheckCount: normalStepCheckCount)
            var isLossStep = false
            if (!self.autoMode) {
                isLossStep = checkIsLossStep(normalStepCount: normalStepCheckCount)
            } else {
                if (self.isModeDrToPdr) {
                    isLossStep = checkIsLossStep(normalStepCount: normalStepCheckCount)
                } else {
                    isLossStep = checkAutoModeIsLossStep(normalStepCount: normalStepCheckCount)
                }
            }
            
            normalStepCountFlag = pacingDetector.isNormalStep(normalStepCount: normalStepCheckCount, normalStepCountSet: normalStepCountSetting)
            
            if ( normalStepCountFlag || finalUnitResult.index <= UVDConstants.MODE_AUTO_NORMAL_STEP_COUNT_SET ) {
                finalUnitResult.index += 1
                finalUnitResult.isIndexChanged = true
                
                let isIndexChangedTime = foundAccPV.timestamp
                var diffTime: Double = (isIndexChangedTime - self.pastIndexChangedTime)*1e-3
                if (diffTime > 1000) {
                    diffTime = 1000
                }
                self.pastIndexChangedTime = isIndexChangedTime
                
                // Step Length Setting
                if self.useFixedStep {
                    finalUnitResult.length = self.fixedStepLength
                } else {
                    finalUnitResult.length = stepLengthEstimator.estStepLength(accPeakQueue: accPeakQueue, accValleyQueue: accValleyQueue)
                    updateStepLengthQueue(stepLengthWithTimeStamp: StepLengthWithTimestamp(timestamp: foundAccPV.timestamp, stepLength: finalUnitResult.length))
                    
                    if (finalUnitResult.length > UVDConstants.STEP_LENGTH_RANGE_TOP) {
                        finalUnitResult.length = UVDConstants.STEP_LENGTH_RANGE_TOP
                    } else if (finalUnitResult.length < UVDConstants.STEP_LENGTH_RANGE_BOTTOM) {
                        finalUnitResult.length = UVDConstants.STEP_LENGTH_RANGE_BOTTOM
                    }
                }
                
                if (!self.autoMode) {
                    if (isLossStep && finalUnitResult.index > UVDConstants.NORMAL_STEP_LOSS_CHECK_SIZE) {
                        if self.useFixedStep {
                            finalUnitResult.length = self.fixedStepLength * Double(UVDConstants.NORMAL_STEP_LOSS_CHECK_SIZE)
                        } else {
                            finalUnitResult.length = UVDConstants.DEFAULT_STEP_LENGTH * Double(UVDConstants.NORMAL_STEP_LOSS_CHECK_SIZE)
                        }
                    }
                } else {
                    if (finalUnitResult.index > UVDConstants.AUTO_MODE_NORMAL_STEP_LOSS_CHECK_SIZE) {
                        if (isLossStep) {
                            if (self.isModeDrToPdr) {
                                finalUnitResult.length = UVDConstants.DEFAULT_STEP_LENGTH * Double(UVDConstants.NORMAL_STEP_LOSS_CHECK_SIZE)
                            } else {
                                finalUnitResult.length = UVDConstants.DEFAULT_STEP_LENGTH*Double(UVDConstants.AUTO_MODE_NORMAL_STEP_LOSS_CHECK_SIZE)
                            }
                        }
                    }
                }
                
                var tempVelocity: Double = (finalUnitResult.length/diffTime)
                if (tempVelocity > 1.45) {
                    tempVelocity = 1.45
                }
                finalUnitResult.velocity = tempVelocity
            }
        }
        
        return finalUnitResult
    }
    
    func updateAccQueue(pvStruct: PeakValleyStruct) {
        if (pvStruct.type == Type.PEAK) {
            updateAccPeakQueue(pvStruct: pvStruct)
        } else if (pvStruct.type == Type.VALLEY) {
            updateAccValleyQueue(pvStruct: pvStruct)
        }
    }
    
    func updateAccPeakQueue(pvStruct: PeakValleyStruct) {
        if (accPeakQueue.count >= UVDConstants.ACC_PV_QUEUE_SIZE) {
            _ = accPeakQueue.pop()
        }
        accPeakQueue.append(TimestampDouble(timestamp: pvStruct.timestamp, valuestamp: pvStruct.pvValue))
    }
    
    func updateAccValleyQueue(pvStruct: PeakValleyStruct) {
        if (accValleyQueue.count >= UVDConstants.ACC_PV_QUEUE_SIZE) {
            _ = accValleyQueue.pop()
        }
        accValleyQueue.append(TimestampDouble(timestamp: pvStruct.timestamp, valuestamp: pvStruct.pvValue))
    }
    
    func updateStepLengthQueue(stepLengthWithTimeStamp: StepLengthWithTimestamp) {
        if (stepLengthQueue.count >= UVDConstants.STEP_LENGTH_QUEUE_SIZE) {
            _ = stepLengthQueue.pop()
        }
        stepLengthQueue.append(stepLengthWithTimeStamp)
    }
    
    func checkIsLossStep(normalStepCount: Int) -> Bool {
        if (normalStepLossCheckQueue.count >= UVDConstants.NORMAL_STEP_LOSS_CHECK_SIZE) {
            _ = normalStepLossCheckQueue.pop()
        }
        normalStepLossCheckQueue.append(normalStepCount)
        
        return pacingDetector.checkLossStep(normalStepCountBuffer: normalStepLossCheckQueue)
    }
    
    func checkAutoModeIsLossStep(normalStepCount: Int) -> Bool {
        if (normalStepLossCheckQueue.count >= UVDConstants.AUTO_MODE_NORMAL_STEP_LOSS_CHECK_SIZE) {
            _ = normalStepLossCheckQueue.pop()
        }
        normalStepLossCheckQueue.append(normalStepCount)
        
        return pacingDetector.checkAutoModeLossStep(normalStepCountBuffer: normalStepLossCheckQueue)
    }
}
