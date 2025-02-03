import Foundation

public class TJLabsUtilFunctions: NSObject {
    public static let shared = TJLabsUtilFunctions()
    
    override init() { }
    
    // MARK: - public
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()
    
    public func getLocalTimeString() -> String {
        return dateFormatter.string(from: Date())
    }

    public func getCurrentTimeInMilliseconds() -> Int {
        return Int(Date().timeIntervalSince1970 * 1000)
    }

    public func getCurrentTimeInMillisecondsDouble() -> Double {
        return Date().timeIntervalSince1970 * 1000
    }

    public func flattenAndUniquify(_ array2D: [[Double]]) -> [Double] {
        return Array(Set(array2D.flatMap { $0 }))
    }
    
    public func removeLevelDirectionString(levelName: String) -> String {
        return levelName.replacingOccurrences(of: "_D", with: "")
    }

    public func movingAverage(preAvgValue: Double, curValue: Double, windowSize: Int) -> Double {
        if windowSize == 1 {
            return curValue
        }
        let windowSizeDouble = Double(windowSize)
        return preAvgValue * ((windowSizeDouble - 1) / windowSizeDouble) + (curValue / windowSizeDouble)
    }

    public func compensateDegree(_ degree: Double) -> Double {
        return fmod((degree + 360).truncatingRemainder(dividingBy: 360), 360)
    }

    public func weightedAverageDegree(degreeA: Double, degreeB: Double, weightA: Double, weightB: Double) -> Double {
        let radianA = degree2radian(degree: compensateDegree(degreeA))
        let radianB = degree2radian(degree: compensateDegree(degreeB))

        let x = weightA * cos(radianA) + weightB * cos(radianB)
        let y = weightA * sin(radianA) + weightB * sin(radianB)

        return compensateDegree(radian2degree(radian: atan2(y, x)))
    }

    public func determineClosestDirection(for angles: (Double, Double)) -> String? {
        let directions: [String: [Double]] = [
            "hor": [0.0, 180.0],
            "ver": [90.0, 270.0]
        ]

        for (directionName, referenceAngles) in directions {
            if referenceAngles.allSatisfy({ refAngle in
                calDegreeDifference(from: angles.0, to: refAngle) <= 40 || calDegreeDifference(from: angles.1, to: refAngle) <= 40
            }) {
                return directionName
            }
        }

        return nil
    }
    
    public func calDegreeDifference(from angle1: Double, to angle2: Double) -> Double {
        let diff = abs(angle1 - angle2)
        return min(diff, 360 - diff)
    }

    public func exponentialMovingAverage(preEMA: Double, curValue: Double, windowSize: Int) -> Double {
        return movingAverage(preAvgValue: preEMA, curValue: curValue, windowSize: windowSize)
    }

    public func degree2radian(degree: Double) -> Double {
        return degree * .pi / 180
    }

    public func radian2degree(radian: Double) -> Double {
        return radian * 180 / .pi
    }

    public func sliceArrayFrom<T>(_ array: [T], startingFrom index: Int) -> [T] {
        guard index >= 0 && index < array.count else {
            return []
        }
        
        return Array(array[index...])
    }

    public func sliceArrayTo<T>(_ array: [T], endTo index: Int) -> [T] {
        guard index >= 0, index < array.count else {
            return []
        }

        return Array(array[0...index])
    }
    
    public func sliceArrayFromTo<T>(_ array: [T], startingFrom: Int, endTo: Int) -> [T] {
        guard startingFrom >= 0 && startingFrom < array.count else {
            return []
        }
        guard endTo >= 0, endTo < array.count else {
            return []
        }
        return Array(array[startingFrom...endTo])
    }
    
    public func calculateCircularMean(for array: [Double]) -> Double {
        guard !array.isEmpty else {
            return 0.0
        }
        
        var sinSum = 0.0
        var cosSum = 0.0
        
        for angle in array {
            sinSum += sin(angle * .pi / 180.0)
            cosSum += cos(angle * .pi / 180.0)
        }
        
        let meanSin = sinSum / Double(array.count)
        let meanCos = cosSum / Double(array.count)
        
        let meanAngle = atan2(meanSin, meanCos) * 180.0 / .pi
        
        return (meanAngle < 0) ? meanAngle + 360.0 : meanAngle
    }

    public func calculateCircularStd(for array: [Double]) -> Double {
        guard !array.isEmpty else {
            return 20.0
        }
        
        let meanAngle = calculateCircularMean(for: array)
        let circularDifferences = array.map { calDegreeDifference(from: $0, to: meanAngle) }
        
        var powSum: Double = 0
        for i in 0..<circularDifferences.count {
            powSum += circularDifferences[i]*circularDifferences[i]
        }
        let circularVariance = powSum / Double(circularDifferences.count)
        
        return sqrt(circularVariance)
    }
    
    public func subtractConstantInArray(from array: [Double], constant: Double) -> [Double] {
        let newArray = array.map { abs($0 - constant) }
        if let minIndex = newArray.enumerated().min(by: { $0.element < $1.element })?.offset {
            var mutableArray = array
            mutableArray.remove(at: minIndex)
            return mutableArray
        } else {
            return array
        }
    }
    
    // MARK: - private
    func calAttEMA(preAttEMA: Attitude, curAtt: Attitude, windowSize: Int) -> Attitude {
        return Attitude(
            roll: exponentialMovingAverage(preEMA: preAttEMA.roll, curValue: curAtt.roll, windowSize: windowSize),
            pitch: exponentialMovingAverage(preEMA: preAttEMA.pitch, curValue: curAtt.pitch, windowSize: windowSize),
            yaw: exponentialMovingAverage(preEMA: preAttEMA.yaw, curValue: curAtt.yaw, windowSize: windowSize)
        )
    }

    func calSensorAxisEMA(preArrayEMA: SensorAxisValue, curArray: SensorAxisValue, windowSize: Int) -> SensorAxisValue {
        return SensorAxisValue(
            x: exponentialMovingAverage(preEMA: preArrayEMA.x, curValue: curArray.x, windowSize: windowSize),
            y: exponentialMovingAverage(preEMA: preArrayEMA.y, curValue: curArray.y, windowSize: windowSize),
            z: exponentialMovingAverage(preEMA: preArrayEMA.z, curValue: curArray.z, windowSize: windowSize),
            norm: exponentialMovingAverage(preEMA: preArrayEMA.norm, curValue: curArray.norm, windowSize: windowSize)
        )
    }
    
    func getOrientation(rotationMatrix: [[Double]]) -> [Double] {
        var orientation = [Double](repeating: 0, count: 3)
        orientation[0] = atan2(rotationMatrix[0][1], rotationMatrix[1][1])
        orientation[1] = asin(-rotationMatrix[2][1])
        orientation[2] = atan2(-rotationMatrix[2][0], rotationMatrix[2][2])
        
        return orientation
    }
    
    func getRotationMatrixFromVector(rotationVector: [Double], returnSize: Int) -> [[Double]] {
        var rotationMatrix = [[Double]](repeating: [Double](repeating: 0, count: 4), count: 4)
        
        let q1: Double = rotationVector[0]
        let q2: Double = rotationVector[1]
        let q3: Double = rotationVector[2]
        let q0: Double = rotationVector[3]
        
        let sqq1 = 2 * q1 * q1
        let sqq2 = 2 * q2 * q2
        let sqq3 = 2 * q3 * q3
        let q1q2 = 2 * q1 * q2
        let q3q0 = 2 * q3 * q0
        let q1q3 = 2 * q1 * q3
        let q2q0 = 2 * q2 * q0
        let q2q3 = 2 * q2 * q3
        let q1q0 = 2 * q1 * q0
        
        if returnSize == 16 {
            rotationMatrix[0][0] = 1 - sqq2 - sqq3
            rotationMatrix[0][1] = q1q2 - q3q0
            rotationMatrix[0][2] = q1q3 + q2q0
            
            rotationMatrix[1][0] = q1q2 + q3q0
            rotationMatrix[1][1] = 1 - sqq1 - sqq3
            rotationMatrix[1][2] = q2q3 - q1q0
            
            rotationMatrix[2][0] = q1q3 - q2q0
            rotationMatrix[2][1] = q2q3 + q1q0
            rotationMatrix[2][2] = 1 - sqq1 - sqq2
            
            rotationMatrix[3][3] = 1
        } else if returnSize == 9 {
            rotationMatrix[0][0] = 1 - sqq2 - sqq3
            rotationMatrix[0][1] = q1q2 - q3q0
            rotationMatrix[0][2] = q1q3 + q2q0
            
            rotationMatrix[1][0] = q1q2 + q3q0
            rotationMatrix[1][1] = 1 - sqq1 - sqq3
            rotationMatrix[1][2] = q2q3 - q1q0
            
            rotationMatrix[2][0] = q1q3 - q2q0
            rotationMatrix[2][1] = q2q3 + q1q0
            rotationMatrix[2][2] = 1 - sqq1 - sqq2
        }
        
        return rotationMatrix
    }
    
    func l2Normalize(originalVector: [Double]) -> Double {
        return sqrt(originalVector.reduce(0) { $0 + $1 * $1 })
    }
    
    func calAngleOfRotation(timeInterval: Double, angularVelocity: Double) -> Double {
        return angularVelocity * Double(timeInterval) * 1e-3
    }
    
    func callRollUsingAcc(acc: [Double]) -> Double {
        let (x, y, z) = (acc[0], acc[1], acc[2])
        return atan2(x, sqrt(y * y + z * z)) + (z < 0 ? (x > 0 ? -.pi : .pi) : 0)
    }

    func callPitchUsingAcc(acc: [Double]) -> Double {
        let (x, y, z) = (acc[0], acc[1], acc[2])
        return atan2(y, sqrt(x * x + z * z))
    }
    
    func calAttitudeUsingGameVector(gameVec: [Double]) -> Attitude {
        let rotationMatrix = getRotationMatrixFromVector(rotationVector: gameVec, returnSize: 9)
        let vecOrientation = getOrientation(rotationMatrix: rotationMatrix)
        return Attitude(roll: vecOrientation[2], pitch: -vecOrientation[1], yaw: -vecOrientation[0])
    }
    
    func calAttitudeUsingRotMatrix(rotationMatrix: [[Double]]) -> Attitude {
        let vecOrientation = getOrientation(rotationMatrix: rotationMatrix)
        return Attitude(roll: vecOrientation[2], pitch: -vecOrientation[1], yaw: -vecOrientation[0])
    }
    
    func transBody2Nav(att: Attitude, data: [Double]) -> [Double] {
        return rotationXY(roll: -att.roll, pitch: -att.pitch, gyro: data)
    }
    
    func rotationXY(roll: Double, pitch: Double, gyro: [Double]) -> [Double] {
        var rotationMatrix = [[Double]](repeating: [Double](repeating: 0, count: 3), count: 3)
        var processedGyro = [Double](repeating: 0, count: 3)
        
        let gx = gyro[0]
        let gy = gyro[1]
        let gz = gyro[2]
        
        rotationMatrix[0][0] = cos(roll)
        rotationMatrix[0][1] = 0
        rotationMatrix[0][2] = -sin(roll)

        rotationMatrix[1][0] = sin(roll) * sin(pitch)
        rotationMatrix[1][1] = 0
        rotationMatrix[1][2] = cos(roll) * sin(pitch)

        rotationMatrix[2][0] = cos(pitch) * sin(roll)
        rotationMatrix[2][1] = -sin(pitch)
        rotationMatrix[2][2] = cos(pitch) * cos(roll)
        
        processedGyro[0] =
        (gx * rotationMatrix[0][0]) + (gy * rotationMatrix[0][1]) + (gz * rotationMatrix[0][2])
        processedGyro[1] =
        (gx * rotationMatrix[1][0]) + (gy * rotationMatrix[1][1]) + (gz * rotationMatrix[1][2])
        processedGyro[2] =
        (gx * rotationMatrix[2][0]) + (gy * rotationMatrix[2][1]) + (gz * rotationMatrix[2][2])
        
        return processedGyro
    }
}
