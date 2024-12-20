import Foundation

public struct TJLabsSensorData {
    public var time: Int
    public var acc: [Double]
    public var userAcc: [Double]
    public var gyro: [Double]
    public var mag: [Double]
    public var grav: [Double]
    public var att: [Double]
    public var quaternion: [Double]
    public var rotationMatrix: [[Double]]
    
    public var gameVector: [Float]
    public var rotVector: [Float]
    public var pressure: [Double]
    public var trueHeading: Double
    public var magneticHeading: Double

    public init() {
        self.time = 0
        self.acc = [Double](repeating: 0, count: 3)
        self.userAcc = [Double](repeating: 0, count: 3)
        self.gyro = [Double](repeating: 0, count: 3)
        self.mag = [Double](repeating: 0, count: 3)
        self.grav = [Double](repeating: 0, count: 3)
        self.att = [Double](repeating: 0, count: 3)
        self.quaternion = [Double](repeating: 0, count: 4)
        self.rotationMatrix = [[Double]](repeating: [Double](repeating: 0, count: 3), count: 3)
        self.gameVector = [Float](repeating: 0, count: 4)
        self.rotVector = [Float](repeating: 0, count: 5)
        self.pressure = [0]
        self.trueHeading = 0
        self.magneticHeading = 0
    }
}

public struct TJLabsCollectData {
    public var time: Int
    public var acc: [Double]
    public var userAcc: [Double]
    public var gyro: [Double]
    public var mag: [Double]
    public var grav: [Double]
    public var att: [Double]
    public var quaternion: [Double]
    public var rotationMatrix: [[Double]]
    
    public var gameVector: [Float]
    public var rotVector: [Float]
    public var pressure: [Double]
    public var trueHeading: Double
    public var magneticHeading: Double
    
    public var index: Int
    public var length: Double
    public var heading: Double
    public var lookingFlag: Bool
    public var isIndexChanged: Bool
    
    public var bleRaw: [String: Double]
    public var bleAvg: [String: Double]
    
    public init() {
        self.time = 0
        self.acc = [Double](repeating: 0, count: 3)
        self.userAcc = [Double](repeating: 0, count: 3)
        self.gyro = [Double](repeating: 0, count: 3)
        self.mag = [Double](repeating: 0, count: 3)
        self.grav = [Double](repeating: 0, count: 3)
        self.att = [Double](repeating: 0, count: 3)
        self.quaternion = [Double](repeating: 0, count: 4)
        self.rotationMatrix = [[Double]](repeating: [Double](repeating: 0, count: 3), count: 3)
        self.gameVector = [Float](repeating: 0, count: 4)
        self.rotVector = [Float](repeating: 0, count: 5)
        self.pressure = [0]
        self.trueHeading = 0
        self.magneticHeading = 0
        self.index = 0
        self.length = 0
        self.heading = 0
        self.lookingFlag = false
        self.isIndexChanged = false
        self.bleRaw = [String: Double]()
        self.bleAvg = [String: Double]()
    }
}

struct Attitude: Equatable {
    public var Roll: Double = 0
    public var Pitch: Double = 0
    public var Yaw: Double = 0
}

struct SensorAxisValue: Equatable {
    public var x: Double = 0
    public var y: Double = 0
    public var z: Double = 0
    
    public var norm: Double = 0
}

enum Type {
    case NONE, PEAK, VALLEY
}

struct PeakValleyStruct {
    public var type: Type = Type.NONE
    public var timestamp: Double = 0
    public var pvValue: Double = 0.0
}

struct StepResult: Equatable {
    public var count: Double = 0
    public var heading: Double = 0
    public var pressure: Double = 0
    public var stepLength: Double = 0
    public var isLooking: Bool = true
}

struct UnitDistance: Equatable {
    public var index: Int = 0
    public var length: Double = 0
    public var velocity: Double = 0
    public var isIndexChanged: Bool = false
}


struct TimestampDouble: Equatable {
    public var timestamp: Double = 0
    public var valuestamp: Double = 0
}


struct StepLengthWithTimestamp: Equatable {
    public var timestamp: Double = 0
    public var stepLength: Double = 0

}

struct DistanceInfo: Equatable {
    public var index: Int = 0
    public var length: Double = 0
    public var time: Double = 0
    public var isIndexChanged: Bool = true
}

public struct UnitDRInfo {
    public var time: Double = 0
    public var index: Int = 0
    public var length: Double = 0
    public var heading: Double = 0
    public var velocity: Double = 0
    public var lookingFlag: Bool = false
    public var isIndexChanged: Bool = false
    public var autoMode: Int = 0
    
    public init(time: Double, index: Int, length: Double, heading: Double, velocity: Double, lookingFlag: Bool, isIndexChanged: Bool, autoMode: Int) {
        self.time = time
        self.index = index
        self.length = length
        self.heading = heading
        self.velocity = velocity
        self.lookingFlag = lookingFlag
        self.isIndexChanged = isIndexChanged
        self.autoMode = autoMode
    }
}


public struct UserVelocity: Encodable {
    let user_id: String
    let mobile_time: Int
    let index: Int
    let length: Double
    let heading: Double
    let looking: Bool
    
    public init(user_id: String, mobile_time: Int, index: Int, length: Double, heading: Double, looking: Bool) {
        self.user_id = user_id
        self.mobile_time = mobile_time
        self.index = index
        self.length = length
        self.heading = heading
        self.looking = looking
    }
}
