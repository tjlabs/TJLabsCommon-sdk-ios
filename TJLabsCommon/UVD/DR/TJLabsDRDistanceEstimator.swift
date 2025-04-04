import Foundation

class TJLabsDRDistanceEstimator: NSObject {
    
    private let VELOCITY_MIN: Double = 4
    private let VELOCITY_MAX: Double = 18
    private let RF_SC_THRESHOLD_DR: Double = 0.67
    private let OUTPUT_DISTANCE_SETTING: Double = 1.0
    private let FEATURE_EXTRACTION_SIZE: Int = Int(UVDGenerator.sensorFrequency / 2)
    
    var index = 0
    var finalUnitResult = UnitDistance()
    
    var accQueue = LinkedList<SensorAxisValue>()
    var magQueue = LinkedList<SensorAxisValue>()
    
    var navGyroZQueue = [Double]()
    var magNormQueue = [Double]()
    var magNormSmoothingQueue = [Double]()
    var magNormVarQueue = [Double]()
    var velocityQueue = [Double]()
    
    var featureExtractionCount = 0
    
    var preNavGyroZSmoothing = 0.0
    var preMagNormSmoothing = 0.0
    var preMagVarFeature = 0.0
    var preVelocitySmoothing = 0.0
    
    var velocityScale = 1.0
    var entranceVelocityScale = 1.0
    var scCompensation = 1.0
    
    var preTime = 0.0
    var distance = 0.0
    
    var preRoll = 0.0
    var prePitch = 0.0

    override init() { }
    
    func estimateDistanceInfo(time: Double, sensorData: SensorData) -> (UnitDistance, Double) {
        let acc = sensorData.acc
        let gyro = sensorData.gyro
        let mag = sensorData.mag
        
        var accRoll = TJLabsUtilFunctions.shared.callRollUsingAcc(acc: acc)
        var accPitch = TJLabsUtilFunctions.shared.callPitchUsingAcc(acc: acc)

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

        let accAttitude = Attitude(roll: accRoll, pitch: accPitch, yaw: 0)
        let gyroNavZ = abs(TJLabsUtilFunctions.shared.transBody2Nav(att: accAttitude, data: gyro)[2])
        let magNorm = TJLabsUtilFunctions.shared.l2Normalize(originalVector: sensorData.mag)

        // Gyro
        updateQueue(&navGyroZQueue, with: gyroNavZ, maxSize: FEATURE_EXTRACTION_SIZE)
        let navGyroZSmoothing = applyEMA(preEMA: preNavGyroZSmoothing, curValue: gyroNavZ, windowSize: min(FEATURE_EXTRACTION_SIZE, navGyroZQueue.count))
        preNavGyroZSmoothing = navGyroZSmoothing

        // Magnetic Field
        updateQueue(&magNormQueue, with: magNorm, maxSize: 5)
        let magNormSmoothing = applyEMA(preEMA: preMagNormSmoothing, curValue: magNorm, windowSize: min(5, featureExtractionCount))
        preMagNormSmoothing = magNormSmoothing
        updateQueue(&magNormSmoothingQueue, with: magNormSmoothing, maxSize: Int(UVDGenerator.sensorFrequency))
        let magNormSmoothingVar = min(magNormSmoothingQueue.variance, 7)

        updateQueue(&magNormVarQueue, with: magNormSmoothingVar, maxSize: Int(UVDGenerator.sensorFrequency * 2))
        let magVarFeature = applyEMA(preEMA: preMagVarFeature, curValue: magNormSmoothingVar, windowSize: min(Int(UVDGenerator.sensorFrequency * 2), magNormVarQueue.count))
        preMagVarFeature = magVarFeature
        
        let velocityRaw = log10(magVarFeature + 1) / log10(1.1)
        updateQueue(&velocityQueue, with: velocityRaw, maxSize: Int(UVDGenerator.sensorFrequency))
        
        let velocitySmoothing = applyEMA(preEMA: preVelocitySmoothing, curValue: velocityRaw, windowSize: min(Int(UVDGenerator.sensorFrequency), velocityQueue.count))
        preVelocitySmoothing = velocitySmoothing

        var turnScale = exp(-navGyroZSmoothing / 2)
        turnScale = turnScale > 0.87 ? 1.0 : turnScale
        
        var velocityInput = velocitySmoothing
        if velocityInput < VELOCITY_MIN {
            velocityInput = 0
        } else if velocityInput > VELOCITY_MAX {
            velocityInput = VELOCITY_MAX
        }
        
        let velocityNotStop = velocityInput * velocityScale * entranceVelocityScale
        var velocityInputScale = velocityNotStop
        if velocityInputScale < VELOCITY_MIN {
            velocityInputScale = 0
        } else if velocityInputScale > VELOCITY_MAX {
            velocityInputScale = VELOCITY_MAX
        }
        
        let delT = preTime == 0 ? 1 / UVDGenerator.sensorFrequency : (time - preTime) * 1e-3
        let velocityMps = (velocityInputScale / 3.6) * turnScale
        finalUnitResult.isIndexChanged = false
        finalUnitResult.velocity = velocityMps * 3.6

        distance += velocityMps * delT
        if distance > OUTPUT_DISTANCE_SETTING {
            index += 1
            finalUnitResult.length = distance
            finalUnitResult.index = index
            finalUnitResult.isIndexChanged = true
            distance = 0
        }
        
        featureExtractionCount += 1
        preTime = time
        return (finalUnitResult, magNormSmoothingVar)
    }
    
    private func applyEMA(preEMA: Double, curValue: Double, windowSize: Int) -> Double {
        return TJLabsUtilFunctions.shared.exponentialMovingAverage(preEMA: preEMA, curValue: curValue, windowSize: windowSize)
    }
    
    private func updateQueue(_ queue: inout [Double], with data: Double, maxSize: Int) {
        if queue.count >= maxSize {
            queue.removeFirst()
        }
        queue.append(data)
    }
    
    func setVelocityScale(scale: Double) {
        velocityScale = scale
    }
}
