import Foundation

public func getLocalTimeString() -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
    dateFormatter.locale = Locale(identifier:"ko_KR")
    let nowDate = Date()
    let convertNowStr = dateFormatter.string(from: nowDate)
    
    return convertNowStr
}

public func getCurrentTimeInMilliseconds() -> Int
{
    return Int(Date().timeIntervalSince1970 * 1000)
}

public func getCurrentTimeInMillisecondsDouble() -> Double
{
    return Double(Date().timeIntervalSince1970 * 1000)
}

public func removeLevelDirectionString(levelName: String) -> String {
    var levelToReturn: String = levelName
    if (levelToReturn.contains("_D")) {
        levelToReturn = levelName.replacingOccurrences(of: "_D", with: "")
    }
    return levelToReturn
}

public func movingAverage(preMvalue: Double, curValue: Double, windowSize: Int) -> Double {
    let windowSizeDouble: Double = Double(windowSize)
    return preMvalue*((windowSizeDouble - 1)/windowSizeDouble) + (curValue/windowSizeDouble)
}

public func compensateHeading(heading: Double) -> Double {
    var headingToReturn: Double = heading
    
    if (headingToReturn < 0) {
        headingToReturn = headingToReturn + 360
    }
    headingToReturn = headingToReturn - floor(headingToReturn/360)*360

    return headingToReturn
}

public func flattenAndUniquify(_ array2D: [[Double]]) -> [Double] {
    var uniqueElements: Set<Double> = Set()
    
    for subArray in array2D {
        uniqueElements.formUnion(subArray)
    }
    
    return Array(uniqueElements)
}

func normalizeAngle(_ angle: Double) -> Double {
    let normalizedAngle = fmod(angle, 360)
    return normalizedAngle < 0 ? normalizedAngle + 360 : normalizedAngle
}

public func weightedAverageHeading(A: Double, B: Double, weightA: Double, weightB: Double) -> Double {
    let A_rad = normalizeAngle(A)*CommonConstants.D2R
    let B_rad = normalizeAngle(B)*CommonConstants.D2R
    
    let x = weightA * cos(A_rad) + weightB * cos(B_rad)
    let y = weightA * sin(A_rad) + weightB * sin(B_rad)
    
    let result_rad = atan2(y, x)

    var result_deg = result_rad*CommonConstants.R2D

    if result_deg < 0 {
        result_deg += 360
    }
    
    return result_deg
}

public func determineClosestDirection(for angles: (Double, Double)) -> String? {
    let normalizedAngles = (
        angles.0.truncatingRemainder(dividingBy: 360),
        angles.1.truncatingRemainder(dividingBy: 360)
    )

    let directions: [String: [Double]] = [
        "hor": [0.0, 180.0],
        "ver": [90.0, 270.0]
    ]

    func angularDifference(from angle1: Double, to angle2: Double) -> Double {
        let diff = abs(angle1 - angle2)
        return min(diff, 360 - diff)
    }

    for (directionName, referenceAngles) in directions {
            let isBothClose = referenceAngles.contains { refAngle1 in
                angularDifference(from: normalizedAngles.0, to: refAngle1) <= 40
            } && referenceAngles.contains { refAngle2 in
                angularDifference(from: normalizedAngles.1, to: refAngle2) <= 40
            }

            if isBothClose {
                return directionName
            }
        }

    return nil
}

