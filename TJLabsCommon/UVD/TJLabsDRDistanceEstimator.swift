import Foundation

class TJLabsDRDistanceEstimator: NSObject {
    
    override init() { }
    
    var index = 0
    var finalUnitResult = UnitDistance()
    
    var accQueue = LinkedList<SensorAxisValue>()
    var magQueue = LinkedList<SensorAxisValue>()
    var navGyroZQueue = [Double]()
    var accNormQueue = [Double]()
    var magNormQueue = [Double]()
    var magNormSmoothingQueue = [Double]()
    var magNormVarQueue = [Double]()
    var velocityQueue = [Double]()
    
    var featureExtractionCount: Double = 0
    
    var preAccNormSmoothing: Double = 0
    var preNavGyroZSmoothing: Double = 0
    var preMagNormSmoothing: Double = 0
    var preMagVarFeature: Double = 0
    var preVelocitySmoothing: Double = 0
    
    var velocityScale: Double = 1.0
    var entranceVelocityScale: Double = 1.0
    
    var preTime: Double = 0
    var distance: Double = 0
    
    var preRoll: Double = 0
    var prePitch: Double = 0
    
    var rflow: Double = 0
    var rflowForVelocity: Double = 0
    var rflowForAutoMode: Double = 0
    var isSufficientRfdBuffer: Bool = false
    var isSufficientRfdVelocityBuffer: Bool = false
    var isSufficientRfdAutoModeBuffer: Bool = false
    var isStartRouteTrack: Bool = false
    
    func estDistanceInfo(time: Double, sensorData: TJLabsSensorData, isStopDetect: Bool) -> UnitDistance {
        // feature extraction
        // ACC X, Y, Z, Norm Smoothing
        // Use y, z, norm variance (2sec)

        let acc = sensorData.acc
        let gyro = sensorData.gyro
        
        var accRoll = TJLabsMathFunctions.shared.callRollUsingAcc(acc: acc)
        var accPitch = TJLabsMathFunctions.shared.callPitchUsingAcc(acc: acc)

        if (accRoll.isNaN) {
            accRoll = preRoll
        } else {
            preRoll = accRoll
        }

        if (accPitch.isNaN) {
            accPitch = prePitch
        } else {
            prePitch = accPitch
        }
        
        let accAttitude = Attitude(Roll: accRoll, Pitch: accPitch, Yaw: 0)
        let gyroNav = TJLabsMathFunctions.shared.transBody2Nav(att: accAttitude, data: gyro)[2]
        let gyroNavZ = abs(gyroNav)
        
        let accNorm = TJLabsMathFunctions.shared.l2Normalize(originalVector: sensorData.acc)
        let magNorm = TJLabsMathFunctions.shared.l2Normalize(originalVector: sensorData.mag)
        
        // ----- Acc ----- //
        var accNormSmoothing: Double = 0
        if (accNormQueue.count == 0) {
            accNormSmoothing = accNorm
        } else if (featureExtractionCount < 5) {
            accNormSmoothing = TJLabsMathFunctions.shared.exponentialMovingAverage(preEMA: preAccNormSmoothing, curValue: accNorm, windowSize: accNormQueue.count)
        } else {
            accNormSmoothing = TJLabsMathFunctions.shared.exponentialMovingAverage(preEMA: preAccNormSmoothing, curValue: accNorm, windowSize: 5)
        }
        preAccNormSmoothing = accNormSmoothing
        updateAccNormQueue(data: accNormSmoothing)
        // --------------- //
        
        // ----- Gyro ----- //
        updateNavGyroZQueue(data: gyroNavZ)
        var navGyroZSmoothing: Double = 0
        if (magNormVarQueue.count == 0) {
            navGyroZSmoothing = gyroNavZ
        } else if (featureExtractionCount < UVDConstants.FEATURE_EXTRACTION_SIZE) {
            navGyroZSmoothing = TJLabsMathFunctions.shared.exponentialMovingAverage(preEMA: preNavGyroZSmoothing, curValue: gyroNavZ, windowSize: navGyroZQueue.count)
        } else {
            navGyroZSmoothing = TJLabsMathFunctions.shared.exponentialMovingAverage(preEMA: preNavGyroZSmoothing, curValue: gyroNavZ, windowSize: Int(UVDConstants.FEATURE_EXTRACTION_SIZE))
        }
        preNavGyroZSmoothing = navGyroZSmoothing
        // --------------- //
        
        // ----- Mag ------ //
        updateMagNormQueue(data: magNorm)
        var magNormSmooting: Double = 0
        if (featureExtractionCount == 0) {
            magNormSmooting = magNorm
        } else if (featureExtractionCount < 5) {
            magNormSmooting = TJLabsMathFunctions.shared.exponentialMovingAverage(preEMA: preMagNormSmoothing, curValue: magNorm, windowSize: magNormQueue.count)
        } else {
            magNormSmooting = TJLabsMathFunctions.shared.exponentialMovingAverage(preEMA: preMagNormSmoothing, curValue: magNorm, windowSize: 5)
        }
        preMagNormSmoothing = magNormSmooting
        updateMagNormSmoothingQueue(data: magNormSmooting)

        var magNormVar = TJLabsMathFunctions.shared.calVariance(buffer: magNormSmoothingQueue, bufferMean: magNormSmoothingQueue.average)
        if (magNormVar > 7) {
            magNormVar = 7
        }
        updateMagNormVarQueue(data: magNormVar)

        var magVarFeature: Double = magNormVar
        if (magNormVarQueue.count == 1) {
            magVarFeature = magNormVar
        } else if (magNormVarQueue.count < Int(UVDConstants.SAMPLE_HZ*2)) {
            magVarFeature = TJLabsMathFunctions.shared.exponentialMovingAverage(preEMA: preMagVarFeature, curValue: magNormVar, windowSize: magNormVarQueue.count)
        } else {
            magVarFeature = TJLabsMathFunctions.shared.exponentialMovingAverage(preEMA: preMagVarFeature, curValue: magNormVar, windowSize: Int(UVDConstants.SAMPLE_HZ*2))
        }
        preMagVarFeature = magVarFeature
        // --------------- //
        
        let velocityRaw = log10(magVarFeature+1)/log10(1.1)
        let velocity = velocityRaw
        updateVelocityQueue(data: velocity)

        var velocitySmoothing: Double = 0
        if (velocityQueue.count == 1) {
            velocitySmoothing = velocity
        } else if (velocityQueue.count < Int(UVDConstants.SAMPLE_HZ)) {
            velocitySmoothing = TJLabsMathFunctions.shared.exponentialMovingAverage(preEMA: preVelocitySmoothing, curValue: velocity, windowSize: velocityQueue.count)
        } else {
            velocitySmoothing = TJLabsMathFunctions.shared.exponentialMovingAverage(preEMA: preVelocitySmoothing, curValue: velocity, windowSize: Int(UVDConstants.SAMPLE_HZ))
        }
        preVelocitySmoothing = velocitySmoothing
        var turnScale = exp(-navGyroZSmoothing/2) // Default 1.6
        if (turnScale > 0.87) {
            turnScale = 1.0
        }
        
        var velocityInput = velocitySmoothing
        if velocityInput < UVDConstants.VELOCITY_MIN {
            velocityInput = 0
        } else if velocityInput > UVDConstants.VELOCITY_MAX {
            velocityInput = UVDConstants.VELOCITY_MAX
        }
        
        let rflowScale: Double = calRflowVelocityScale(rflowForVelocity: self.rflowForVelocity, isSufficientForVelocity: self.isSufficientRfdVelocityBuffer)
        
        let velocityNotStop = velocityInput*self.velocityScale*self.entranceVelocityScale
        var velocityInputScale = velocityNotStop
        
        if velocityInputScale < UVDConstants.VELOCITY_MIN {
            velocityInputScale = 0
            if (self.isSufficientRfdBuffer && self.rflow < 0.4) {
                velocityInputScale = UVDConstants.VELOCITY_MAX*rflowScale
            }
        } else if velocityInputScale > UVDConstants.VELOCITY_MAX {
            velocityInputScale = UVDConstants.VELOCITY_MAX
        }
        
        // RFlow Stop Detection
        if (self.isSufficientRfdBuffer && self.rflow >= UVDConstants.RF_SC_THRESHOLD_DR) {
            velocityInputScale = 0
        }
        
        let delT = self.preTime == 0 ? 1/UVDConstants.SAMPLE_HZ : (time-self.preTime)*1e-3
        if (velocityInputScale == 0 && self.isStartRouteTrack) {
            velocityInputScale = UVDConstants.VELOCITY_MIN
        }
        
        let velocityMps = (velocityInputScale/3.6)*turnScale
        let velocityFinal = velocityMps
        
        finalUnitResult.isIndexChanged = false
        finalUnitResult.velocity = velocityFinal
        
        distance += velocityMps*delT
        if (distance > Double(UVDConstants.OUTPUT_DISTANCE_SETTING)) {
            index += 1
            finalUnitResult.length = distance
            finalUnitResult.index = index
            finalUnitResult.isIndexChanged = true

            distance = 0
        }
        
        featureExtractionCount += 1
        preTime = time
        return finalUnitResult
    }
    
    func updateAccQueue(data: SensorAxisValue) {
        if (accQueue.count >= Int(UVDConstants.FEATURE_EXTRACTION_SIZE)) {
            _ = accQueue.pop()
        }
        accQueue.append(data)
    }
    
    func updateMagQueue(data: SensorAxisValue) {
        if (magQueue.count >= Int(UVDConstants.FEATURE_EXTRACTION_SIZE)) {
            _ = magQueue.pop()
        }
        magQueue.append(data)
    }
    
    func updateNavGyroZQueue(data: Double) {
        if (navGyroZQueue.count >= Int(UVDConstants.FEATURE_EXTRACTION_SIZE)) {
            navGyroZQueue.removeFirst()
        }
        navGyroZQueue.append(data)
    }
    
    func updateAccNormQueue(data: Double) {
        if (accNormQueue.count >= Int(UVDConstants.SAMPLE_HZ)) {
            accNormQueue.removeFirst()
        }
        accNormQueue.append(data)
    }
    
    func updateMagNormQueue(data: Double) {
        if (magNormQueue.count >= 5) {
            magNormQueue.remove(at: 0)
        }
        magNormQueue.append(data)
    }
    
    func updateMagNormSmoothingQueue(data: Double) {
        if (magNormSmoothingQueue.count >= Int(UVDConstants.SAMPLE_HZ)) {
            magNormSmoothingQueue.removeFirst()
        }
        magNormSmoothingQueue.append(data)
    }
    
    func updateMagNormVarQueue(data: Double) {
        if (magNormVarQueue.count >= Int(UVDConstants.SAMPLE_HZ*2)) {
            magNormVarQueue.removeFirst()
        }
        magNormVarQueue.append(data)
    }
    
    func updateVelocityQueue(data: Double) {
        if (velocityQueue.count >= Int(UVDConstants.SAMPLE_HZ)) {
            velocityQueue.removeFirst()
        }
        velocityQueue.append(data)
    }
    
    func setRflow(rflow: Double, rflowForVelocity: Double, rflowForAutoMode: Double, isSufficient: Bool, isSufficientForVelocity: Bool, isSufficientForAutoMode: Bool) {
        self.rflow = rflow
        self.rflowForVelocity = rflowForVelocity
        self.rflowForAutoMode = rflowForAutoMode
        
        self.isSufficientRfdBuffer = isSufficient
        self.isSufficientRfdVelocityBuffer = isSufficientForVelocity
        self.isSufficientRfdAutoModeBuffer = isSufficientForAutoMode
    }
    
    func calRflowVelocityScale(rflowForVelocity: Double, isSufficientForVelocity: Bool) -> Double {
        var scale: Double = 1.0
        if (isSufficientForVelocity) {
            scale = (-1/(1+exp(10*(-rflowForVelocity+0.66)))) + 1
            if (scale < 0.5) {
                scale = 0.5
            }
        }
        
        return scale
    }
    
    func setIsStartRouteTrack(isStartRouteTrack: Bool) {
        self.isStartRouteTrack = isStartRouteTrack
    }
}
