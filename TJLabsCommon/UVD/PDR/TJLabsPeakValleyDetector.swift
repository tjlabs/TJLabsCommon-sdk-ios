import Darwin
import Foundation

class TJLabsPeakValleyDetector: NSObject {
    
    var amplitudeThreshold: Double = 0.18
    var timeThreshold: Double = 100
    
    init(amplitudeThreshold: Double = 0.18, timeThreshold: Double = 100) {
        self.amplitudeThreshold = amplitudeThreshold
        self.timeThreshold = timeThreshold
    }
    
    func updatePeakValley(localPeakValley: PeakValleyStruct, lastPeakValley: PeakValleyStruct) -> PeakValleyStruct {
        var updatePeakValley: PeakValleyStruct = lastPeakValley
        if (lastPeakValley.type == SensorPatternType.PEAK && localPeakValley.type == SensorPatternType.PEAK) {
            updatePeakValley = updatePeakIfBigger(localPeak: localPeakValley, lastPeak: lastPeakValley)
        } else if (lastPeakValley.type == SensorPatternType.VALLEY && localPeakValley.type == SensorPatternType.VALLEY) {
            updatePeakValley = updateValleyIfSmaller(localValley: localPeakValley, lastValley: lastPeakValley)
        }
        return updatePeakValley
    }
    
    func updatePeakIfBigger(localPeak: PeakValleyStruct, lastPeak: PeakValleyStruct) -> PeakValleyStruct {
        var updatePeakValley: PeakValleyStruct = lastPeak
        
        if (localPeak.pvValue > lastPeak.pvValue) {
            updatePeakValley.timestamp = localPeak.timestamp
            updatePeakValley.pvValue = localPeak.pvValue
        }
        
        return updatePeakValley
    }
    
    func updateValleyIfSmaller(localValley: PeakValleyStruct, lastValley: PeakValleyStruct) -> PeakValleyStruct {
        var updatePeakValley: PeakValleyStruct = lastValley
        
        if (localValley.pvValue < lastValley.pvValue) {
            updatePeakValley.timestamp = localValley.timestamp
            updatePeakValley.pvValue = localValley.pvValue
        }
        
        return updatePeakValley
    }
    
    
    var lastPeakValley: PeakValleyStruct = PeakValleyStruct(type: SensorPatternType.PEAK, timestamp: Double.greatestFiniteMagnitude, pvValue: Double.leastNormalMagnitude)
    
    func findLocalPeakValley(queue: LinkedList<TimestampDouble>) -> PeakValleyStruct {
        guard queue.count > 1 else {
            return PeakValleyStruct()
        }

        if let node = queue.node(at: 1) {
            if isLocalPeak(data: queue) {
                return PeakValleyStruct(type: .PEAK, timestamp: node.value.timestamp, pvValue: node.value.valuestamp)
            } else if isLocalValley(data: queue) {
                return PeakValleyStruct(type: .VALLEY, timestamp: node.value.timestamp, pvValue: node.value.valuestamp)
            }
        }
        
        return PeakValleyStruct()
    }
    
    func isLocalPeak(data: LinkedList<TimestampDouble>) -> Bool {
        let valuestamp0 = data.node(at: 0)!.value.valuestamp
        let valuestamp1 = data.node(at: 1)!.value.valuestamp
        let valuestamp2 = data.node(at: 2)!.value.valuestamp
        
        return (valuestamp0 < valuestamp1) && (valuestamp1 >= valuestamp2)
    }
    
    func isLocalValley(data: LinkedList<TimestampDouble>) -> Bool {
        let valuestamp0 = data.node(at: 0)!.value.valuestamp
        let valuestamp1 = data.node(at: 1)!.value.valuestamp
        let valuestamp2 = data.node(at: 2)!.value.valuestamp
        
        return (valuestamp0 > valuestamp1) && (valuestamp1 <= valuestamp2)
    }
    
    func findGlobalPeakValley(localPeakValley: PeakValleyStruct) -> PeakValleyStruct {
        var foundPeakValley = PeakValleyStruct()
        if (lastPeakValley.type == SensorPatternType.PEAK && localPeakValley.type == SensorPatternType.VALLEY) {
            if (isGlobalPeak(lastPeak: lastPeakValley, localValley: localPeakValley)) {
                foundPeakValley = lastPeakValley
                lastPeakValley = localPeakValley
            }
        } else if (lastPeakValley.type == SensorPatternType.VALLEY && localPeakValley.type == SensorPatternType.PEAK) {
            if (isGlobalValley(lastValley: lastPeakValley, localPeak: localPeakValley)) {
                foundPeakValley = lastPeakValley
                lastPeakValley = localPeakValley
            }
        }
        
        return foundPeakValley
    }
    
    func isGlobalPeak(lastPeak: PeakValleyStruct, localValley: PeakValleyStruct) -> Bool {
        let amp = lastPeak.pvValue - localValley.pvValue
        let time = localValley.timestamp - lastPeak.timestamp
        
        return (amp > amplitudeThreshold) && (time > timeThreshold)
    }
    
    func isGlobalValley(lastValley: PeakValleyStruct, localPeak: PeakValleyStruct) -> Bool {
        let amp = localPeak.pvValue - lastValley.pvValue
        let time = localPeak.timestamp - lastValley.timestamp
        
        return (amp > amplitudeThreshold) && (time > timeThreshold)
    }
    
    func findPeakValley(smoothedNormAcc: LinkedList<TimestampDouble>) -> PeakValleyStruct {
        let localPeakValley = findLocalPeakValley(queue: smoothedNormAcc)
        let foundGlobalPeakValley = findGlobalPeakValley(localPeakValley: localPeakValley)
        
        lastPeakValley = updatePeakValley(localPeakValley: localPeakValley, lastPeakValley: lastPeakValley)
        return foundGlobalPeakValley
    }
}
