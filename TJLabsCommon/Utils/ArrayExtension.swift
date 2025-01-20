import Foundation

public extension Array where Element: BinaryInteger {
    var average: Double {
        if self.isEmpty {
            return 0.0
        } else {
            let sum = self.reduce(0, +)
            return Double(sum) / Double(self.count)
        }
    }

}

public extension Array where Element: BinaryFloatingPoint {
    var average: Double {
        if self.isEmpty {
            return 0.0
        } else {
            let sum = self.reduce(0, +)
            return Double(sum) / Double(self.count)
        }
    }

}

public extension Array where Element == Double {
    var mean: Double {
        return reduce(0, +) / Double(count)
    }
    
    var variance: Double {
        let meanValue = mean
        let squareSum = reduce(0, {$0 + pow($1 - meanValue, 2)})
        
        return squareSum/Double(self.count-1)
    }
    
    var standardDeviation: Double {
        let meanValue = mean
        let squareSum = reduce(0, {$0 + pow($1 - meanValue, 2)})
        return sqrt(squareSum / Double(count))
    }
}

public func += <V> ( left: inout [V], right: V) {
    left.append(right)
}

public func + <V>(left: Array<V>, right: V) -> Array<V>
{
    var map = Array<V>()
    for (v) in left {
        map.append(v)
    }

    map.append(right)

    return map
}
