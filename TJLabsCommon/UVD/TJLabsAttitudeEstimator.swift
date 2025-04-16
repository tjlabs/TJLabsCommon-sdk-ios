import Foundation

class TJLabsAttitudeEstimator: NSObject {
    
    init(frequency: Double) {
        self.frequency = frequency
        self.avgAttitudeWindow = Int(frequency/2)
    }
    
    var frequency: Double = 40
    var avgAttitudeWindow: Int = 20
    
    var timeBefore: Double = 0
    var headingGyroGame: Double = 0
    var headingGyroAcc: Double = 0
    var preGameVecAttEMA = Attitude(roll: 0, pitch: 0, yaw: 0)
    var preAccAttEMA = Attitude(roll: 0, pitch: 0, yaw: 0)
    var preRoll: Double = 0
    var prePitch: Double = 0
    
    func estimateAttitudeRadian(time: Double, sensorData: SensorData) -> Attitude {
        let acc = sensorData.acc
        let gyro = sensorData.gyro
        let rotMatrix = sensorData.rotationMatrix
        
        // 휴대폰의 자세(기울어짐 정도)를 계산하여 각도(Radian)로 저장
        let attFromRotMatrix = TJLabsUtilFunctions.shared.calAttitudeUsingRotMatrix(rotationMatrix: rotMatrix)
        let gyroNavGame = TJLabsUtilFunctions.shared.transBody2Nav(att: attFromRotMatrix, data: gyro)
        
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
        
        var accAttEMA = Attitude(roll: accRoll, pitch: accPitch, yaw: 0)
        let gyroNavEMAAcc = TJLabsUtilFunctions.shared.transBody2Nav(att: accAttEMA, data: gyro)
        
        // timeBefore 이 null 이면 초기화, 아니면 회전 값 누적
        if (timeBefore == 0) {
            headingGyroGame = gyroNavGame[2] * (1/frequency)
            headingGyroAcc = gyroNavEMAAcc[2] * (1/frequency)
        } else {
            let delT: Double = JupiterSimulator.shared.isSimulationMode ? (Double(sensorData.time) - timeBefore) : (time - timeBefore)
            let angleOfRotation = TJLabsUtilFunctions.shared.calAngleOfRotation(timeInterval: delT, angularVelocity: gyroNavGame[2])
            headingGyroGame += angleOfRotation
            
            let accAngleOfRotation = TJLabsUtilFunctions.shared.calAngleOfRotation(timeInterval: delT, angularVelocity: gyroNavEMAAcc[2])
            headingGyroAcc += accAngleOfRotation
        }
        
        var gameVecAttEMA: Attitude
        if (preGameVecAttEMA == Attitude(roll: 0, pitch: 0, yaw: 0)) {
            gameVecAttEMA = attFromRotMatrix
            accAttEMA = accAttitude
        } else {
            gameVecAttEMA = TJLabsUtilFunctions.shared.calAttEMA(preAttEMA: preGameVecAttEMA, curAtt: attFromRotMatrix, windowSize: avgAttitudeWindow)
            accAttEMA = TJLabsUtilFunctions.shared.calAttEMA(preAttEMA: preAccAttEMA, curAtt: accAttEMA, windowSize: avgAttitudeWindow)
        }
        
        // 누적된 회줜 값으로 현재 Attitude 계산
        let curAttitude = Attitude(roll: accAttEMA.roll, pitch: accAttEMA.pitch, yaw: headingGyroAcc)
        preGameVecAttEMA = gameVecAttEMA
        preAccAttEMA = accAttEMA
        timeBefore = JupiterSimulator.shared.isSimulationMode ? Double(sensorData.time) : time
        
        return curAttitude
    }
    
    func estimateAccAttitudeRadian(time: Double, sensorData: SensorData) -> Attitude {
        let acc = sensorData.acc
        let gyro = sensorData.gyro
        // 휴대폰의 자세(기울어짐 정도)를 계산하여 각도(Radian)로 저장
        let accRoll = TJLabsUtilFunctions.shared.callRollUsingAcc(acc: acc)
        let accPitch = TJLabsUtilFunctions.shared.callPitchUsingAcc(acc: acc)
        let accAttitude = Attitude(roll: accRoll, pitch: accPitch, yaw: 0)
        
        var accAttEMA = Attitude(roll: accRoll, pitch: accPitch, yaw: 0)
        let gyroNavEMAAcc = TJLabsUtilFunctions.shared.transBody2Nav(att: accAttEMA, data: gyro)
        
        // timeBefore 이 null 이면 초기화, 아니면 회전 값 누적
        if (timeBefore == 0) {
            headingGyroAcc = gyroNavEMAAcc[2] * (1/frequency)
        } else {
            let delT = JupiterSimulator.shared.isSimulationMode ? (Double(sensorData.time) - timeBefore) : (time - timeBefore)
            let accAngleOfRotation = TJLabsUtilFunctions.shared.calAngleOfRotation(timeInterval: delT, angularVelocity: gyroNavEMAAcc[2])
            headingGyroAcc += accAngleOfRotation
        }
        
        if (preAccAttEMA == Attitude(roll: 0, pitch: 0, yaw: 0)) {
            accAttEMA = accAttitude
        } else {
            accAttEMA = TJLabsUtilFunctions.shared.calAttEMA(preAttEMA: preAccAttEMA, curAtt: accAttEMA, windowSize: avgAttitudeWindow)
        }
        
        // 누적된 회줜 값으로 현재 Attitude 계산
        let curAttitude = Attitude(roll: accAttEMA.roll, pitch: accAttEMA.pitch, yaw: headingGyroAcc)
        preAccAttEMA = accAttEMA
        timeBefore = JupiterSimulator.shared.isSimulationMode ? Double(sensorData.time) : time
        
        return curAttitude
    }
}
