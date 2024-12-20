import Foundation

public struct TJLabsUtilFunctions {
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

    public func removeLevelDirectionString(levelName: String) -> String {
        return levelName.replacingOccurrences(of: "_D", with: "")
    }

    public func movingAverage(preMvalue: Double, curValue: Double, windowSize: Int) -> Double {
        let windowSizeDouble = Double(windowSize)
        return preMvalue * ((windowSizeDouble - 1) / windowSizeDouble) + (curValue / windowSizeDouble)
    }

    public func compensateHeading(heading: Double) -> Double {
        return fmod((heading + 360).truncatingRemainder(dividingBy: 360), 360)
    }

    public func flattenAndUniquify(_ array2D: [[Double]]) -> [Double] {
        return Array(Set(array2D.flatMap { $0 }))
    }

    public func normalizeAngle(_ angle: Double) -> Double {
        let normalizedAngle = angle.truncatingRemainder(dividingBy: 360)
        return normalizedAngle < 0 ? normalizedAngle + 360 : normalizedAngle
    }

    public func weightedAverageHeading(A: Double, B: Double, weightA: Double, weightB: Double) -> Double {
        let A_rad = degree2radian(degree: normalizeAngle(A))
        let B_rad = degree2radian(degree: normalizeAngle(B))

        let x = weightA * cos(A_rad) + weightB * cos(B_rad)
        let y = weightA * sin(A_rad) + weightB * sin(B_rad)

        return normalizeAngle(radian2degree(radian: atan2(y, x)))
    }

    public func determineClosestDirection(for angles: (Double, Double)) -> String? {
        let directions: [String: [Double]] = [
            "hor": [0.0, 180.0],
            "ver": [90.0, 270.0]
        ]

        func angularDifference(from angle1: Double, to angle2: Double) -> Double {
            let diff = abs(angle1 - angle2)
            return min(diff, 360 - diff)
        }

        for (directionName, referenceAngles) in directions {
            if referenceAngles.allSatisfy({ refAngle in
                angularDifference(from: angles.0, to: refAngle) <= 40 || angularDifference(from: angles.1, to: refAngle) <= 40
            }) {
                return directionName
            }
        }

        return nil
    }

    public func exponentialMovingAverage(preEMA: Double, curValue: Double, windowSize: Int) -> Double {
        return movingAverage(preMvalue: preEMA, curValue: curValue, windowSize: windowSize)
    }

    public func calAngleOfRotation(timeInterval: Double, angularVelocity: Double) -> Double {
        return angularVelocity * timeInterval * 1e-3
    }

    public func degree2radian(degree: Double) -> Double {
        return degree * .pi / 180
    }

    public func radian2degree(radian: Double) -> Double {
        return radian * 180 / .pi
    }

    // MARK: - private
    func callRollUsingAcc(acc: [Double]) -> Double {
        let (x, y, z) = (acc[0], acc[1], acc[2])
        return atan2(x, sqrt(y * y + z * z)) + (z < 0 ? (x > 0 ? -.pi : .pi) : 0)
    }

    func callPitchUsingAcc(acc: [Double]) -> Double {
        let (x, y, z) = (acc[0], acc[1], acc[2])
        return atan2(y, sqrt(x * x + z * z))
    }

    func calAttEMA(preAttEMA: Attitude, curAtt: Attitude, windowSize: Int) -> Attitude {
        return Attitude(
            Roll: exponentialMovingAverage(preEMA: preAttEMA.Roll, curValue: curAtt.Roll, windowSize: windowSize),
            Pitch: exponentialMovingAverage(preEMA: preAttEMA.Pitch, curValue: curAtt.Pitch, windowSize: windowSize),
            Yaw: exponentialMovingAverage(preEMA: preAttEMA.Yaw, curValue: curAtt.Yaw, windowSize: windowSize)
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

    func l2Normalize(originalVector: [Double]) -> Double {
        return sqrt(originalVector.reduce(0) { $0 + $1 * $1 })
    }
}
