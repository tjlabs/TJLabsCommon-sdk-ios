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
    var accNormQueue = [Double]()
    var magNormQueue = [Double]()
    var magNormSmoothingQueue = [Double]()
    var magNormVarQueue = [Double]()
    var velocityQueue = [Double]()
    
    var featureExtractionCount = 0
    
    var preAccNormSmoothing = 0.0
    var preNavGyroZSmoothing = 0.0
    var preMagNormSmoothing = 0.0
    var preMagVarFeature = 0.0
    var preVelocitySmoothing = 0.0
    
    var velocityScale = 1.0
    var entranceVelocityScale = 1.0
    var scCompensation = 1.0
    
    var preTime = 0.0
    var velocityAcc = 0.0
    var distance = 0.0
    
    var preRoll = 0.0
    var prePitch = 0.0

    override init() { }
    
    func estimateDistanceInfo(time: Double, sensorData: SensorData) -> UnitDistance {
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
        let accMovingDirection = TJLabsUtilFunctions.shared.transBody2Nav(att: accAttitude, data: acc)[1]
        let gyroNavZ = abs(TJLabsUtilFunctions.shared.transBody2Nav(att: accAttitude, data: gyro)[2])
        
        let accNorm = TJLabsUtilFunctions.shared.l2Normalize(originalVector: sensorData.acc)
        let magNorm = TJLabsUtilFunctions.shared.l2Normalize(originalVector: sensorData.mag)
        
        // Acceleration
        let accNormSmoothing = applyEMA(preEMA: preAccNormSmoothing, curValue: accNorm, windowSize: max(5, accNormQueue.count))
        preAccNormSmoothing = accNormSmoothing
        updateQueue(&accNormQueue, with: accNormSmoothing, maxSize: Int(UVDGenerator.sensorFrequency))
        let accNormVar = accNormQueue.variance

        // Gyro
        updateQueue(&navGyroZQueue, with: gyroNavZ, maxSize: FEATURE_EXTRACTION_SIZE)
        let navGyroZSmoothing = applyEMA(preEMA: preNavGyroZSmoothing, curValue: gyroNavZ, windowSize: max(FEATURE_EXTRACTION_SIZE, navGyroZQueue.count))
        preNavGyroZSmoothing = navGyroZSmoothing

        // Magnetic Field
        updateQueue(&magNormQueue, with: magNorm, maxSize: 5)
        let magNormSmoothing = applyEMA(preEMA: preMagNormSmoothing, curValue: magNorm, windowSize: max(5, featureExtractionCount))
        preMagNormSmoothing = magNormSmoothing
        updateQueue(&magNormSmoothingQueue, with: magNormSmoothing, maxSize: Int(UVDGenerator.sensorFrequency))

        var magNormVar = min(magNormSmoothingQueue.variance, 7)
        updateQueue(&magNormVarQueue, with: magNormVar, maxSize: Int(UVDGenerator.sensorFrequency * 2))
        
        let magVarFeature = applyEMA(preEMA: preMagVarFeature, curValue: magNormVar, windowSize: max(Int(UVDGenerator.sensorFrequency * 2), magNormVarQueue.count))
        preMagVarFeature = magVarFeature

        let velocityRaw = log10(magVarFeature + 1) / log10(1.1)
        updateQueue(&velocityQueue, with: velocityRaw, maxSize: Int(UVDGenerator.sensorFrequency))

        let velocitySmoothing = applyEMA(preEMA: preVelocitySmoothing, curValue: velocityRaw, windowSize: max(Int(UVDGenerator.sensorFrequency), velocityQueue.count))
        preVelocitySmoothing = velocitySmoothing

        var turnScale = exp(-navGyroZSmoothing / 2)
        turnScale = turnScale > 0.87 ? 1.0 : turnScale
        
        let velocityInput = min(max(velocitySmoothing, VELOCITY_MIN), VELOCITY_MAX)
        let velocityNotStop = velocityInput * velocityScale * entranceVelocityScale
        let velocityInputScale = min(max(velocityNotStop, VELOCITY_MIN), VELOCITY_MAX)

        let delT = preTime == 0 ? 1 / UVDGenerator.sensorFrequency : (time - preTime) * 1e-3
        let velocityMps = (velocityInputScale / 3.6) * turnScale
        finalUnitResult.velocity = velocityMps

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
        return finalUnitResult
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
}
