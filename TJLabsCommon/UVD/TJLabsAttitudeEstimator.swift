import Foundation

class TJLabsAttitudeEstimator: NSObject {
    
    override init() { }
    
    var timeBefore: Double = 0
    var headingGyroGame: Double = 0
    var headingGyroAcc: Double = 0
    var preGameVecAttEMA = Attitude(Roll: 0, Pitch: 0, Yaw: 0)
    var preAccAttEMA = Attitude(Roll: 0, Pitch: 0, Yaw: 0)
    
    var preRoll: Double = 0
    var prePitch: Double = 0
    
    func estAttitude(time: Double, acc:[Double], gyro: [Double], rotMatrix: [[Double]]) -> Attitude {
        // 휴대폰의 자세(기울어짐 정도)를 계산하여 각도(Radian)로 저장
        let attFromRotMatrix = TJLabsMathFunctions.shared.calAttitudeUsingRotMatrix(rotationMatrix: rotMatrix)
        let gyroNavGame = TJLabsMathFunctions.shared.transBody2Nav(att: attFromRotMatrix, data: gyro)
        
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
        
        var accAttEMA = Attitude(Roll: accRoll, Pitch: accPitch, Yaw: 0)
        let gyroNavEMAAcc = TJLabsMathFunctions.shared.transBody2Nav(att: accAttEMA, data: gyro)
        
        // timeBefore 이 null 이면 초기화, 아니면 회전 값 누적
        if (timeBefore == 0) {
            headingGyroGame = gyroNavGame[2] * (1 / UVDConstants.SAMPLE_HZ)
            headingGyroAcc = gyroNavEMAAcc[2] * (1 / UVDConstants.SAMPLE_HZ)
        } else {
            let angleOfRotation = TJLabsMathFunctions.shared.calAngleOfRotation(timeInterval: time - timeBefore, angularVelocity: gyroNavGame[2])
            headingGyroGame += angleOfRotation
            
            let accAngleOfRotation = TJLabsMathFunctions.shared.calAngleOfRotation(timeInterval: time - timeBefore, angularVelocity: gyroNavEMAAcc[2])
            headingGyroAcc += accAngleOfRotation
        }
        
        var gameVecAttEMA: Attitude
        if (preGameVecAttEMA == Attitude(Roll: 0, Pitch: 0, Yaw: 0)) {
            gameVecAttEMA = attFromRotMatrix
            accAttEMA = accAttitude
        } else {
            gameVecAttEMA = TJLabsMathFunctions.shared.calAttEMA(preAttEMA: preGameVecAttEMA, curAtt: attFromRotMatrix, windowSize: UVDConstants.AVG_ATTITUDE_WINDOW)
            accAttEMA = TJLabsMathFunctions.shared.calAttEMA(preAttEMA: preAccAttEMA, curAtt: accAttEMA, windowSize: UVDConstants.AVG_ATTITUDE_WINDOW)
        }
        
        // 누적된 회줜 값으로 현재 Attitude 계산
        let curAttitudeOrigin = Attitude(Roll: gameVecAttEMA.Roll, Pitch: gameVecAttEMA.Pitch, Yaw: headingGyroGame)
        let curAttitude = Attitude(Roll: accAttEMA.Roll, Pitch: accAttEMA.Pitch, Yaw: headingGyroAcc)
        
        let rollA = TJLabsMathFunctions.shared.radian2degree(radian: curAttitude.Roll)
        let PitchA = TJLabsMathFunctions.shared.radian2degree(radian: curAttitude.Pitch)
        let YawA = TJLabsMathFunctions.shared.radian2degree(radian: curAttitude.Yaw)
        
        preGameVecAttEMA = gameVecAttEMA
        preAccAttEMA = accAttEMA
        
        timeBefore = time
        return curAttitude
    }
    
    func estAccAttitude(time: Double, acc:[Double], gyro: [Double]) -> Attitude {
        // 휴대폰의 자세(기울어짐 정도)를 계산하여 각도(Radian)로 저장
        let accRoll = TJLabsMathFunctions.shared.callRollUsingAcc(acc: acc)
        let accPitch = TJLabsMathFunctions.shared.callPitchUsingAcc(acc: acc)
        let accAttitude = Attitude(Roll: accRoll, Pitch: accPitch, Yaw: 0)
        
        var accAttEMA = Attitude(Roll: accRoll, Pitch: accPitch, Yaw: 0)
        let gyroNavEMAAcc = TJLabsMathFunctions.shared.transBody2Nav(att: accAttEMA, data: gyro)
        
        // timeBefore 이 null 이면 초기화, 아니면 회전 값 누적
        if (timeBefore == 0) {
            headingGyroAcc = gyroNavEMAAcc[2] * (1 / UVDConstants.SAMPLE_HZ)
        } else {
            let accAngleOfRotation = TJLabsMathFunctions.shared.calAngleOfRotation(timeInterval: time - timeBefore, angularVelocity: gyroNavEMAAcc[2])
            headingGyroAcc += accAngleOfRotation
        }
        
        if (preAccAttEMA == Attitude(Roll: 0, Pitch: 0, Yaw: 0)) {
            accAttEMA = accAttitude
        } else {
            accAttEMA = TJLabsMathFunctions.shared.calAttEMA(preAttEMA: preAccAttEMA, curAtt: accAttEMA, windowSize: UVDConstants.AVG_ATTITUDE_WINDOW)
        }
        
        // 누적된 회줜 값으로 현재 Attitude 계산
        let curAttitude = Attitude(Roll: accAttEMA.Roll, Pitch: accAttEMA.Pitch, Yaw: headingGyroAcc)
        preAccAttEMA = accAttEMA
        timeBefore = time
        
        return curAttitude
    }
}
