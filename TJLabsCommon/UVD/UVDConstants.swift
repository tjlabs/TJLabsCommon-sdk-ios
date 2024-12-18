class UVDConstants {
    static let SAMPLE_HZ: Double = 40

    static let G: Double = 9.81
    static let SENSOR_INTERVAL: TimeInterval = 1/100
    static let ABNORMAL_MAG_THRESHOLD: Double = 2000
    static let ABNORMAL_MAG_COUNT = 500
    
    // UVD //
    static var UVD_INTERVAL: TimeInterval = 1/40 // seconds
    
    // DR & PDR //
    static let LOOKING_FLAG_STEP_CHECK_SIZE: Int = 3
    static let AVG_ATTITUDE_WINDOW: Int = 20
    static let AVG_NORM_ACC_WINDOW: Int = 20
    static let ACC_PV_QUEUE_SIZE: Int = 3
    static let ACC_NORM_EMA_QUEUE_SIZE: Int = 3
    static let STEP_LENGTH_QUEUE_SIZE: Int = 5
    static let NORMAL_STEP_LOSS_CHECK_SIZE: Int = 3
    static let MODE_AUTO_NORMAL_STEP_COUNT_SET = 19
    static let AUTO_MODE_NORMAL_STEP_LOSS_CHECK_SIZE: Int = MODE_AUTO_NORMAL_STEP_COUNT_SET + 1
    
    static let ALPHA: Double = 0.45
    static let DIFFERENCE_PV_STANDARD: Double = 0.83
    static let MID_STEP_LENGTH: Double = 0.5
    static let DEFAULT_STEP_LENGTH: Double = 0.625
    static let MIN_STEP_LENGTH: Double = 0.01
    static let MAX_STEP_LENGTH: Double = 0.93
    static let MIN_DIFFERENCE_PV: Double = 0.2
    static let COMPENSATION_WEIGHT: Double = 0.85
    static let COMPENSATION_BIAS: Double = 0.1
    static let DIFFERENCE_PV_THRESHOLD: Double = (MID_STEP_LENGTH - DEFAULT_STEP_LENGTH) / ALPHA + DIFFERENCE_PV_STANDARD
    static let STEP_LENGTH_RANGE_BOTTOM: Double = 0.5
    static let STEP_LENGTH_RANGE_TOP: Double = 0.7
    
    static let OUTPUT_SAMPLE_HZ: Double = 10
    static let OUTPUT_SAMPLE_TIME: Double = 1 / OUTPUT_SAMPLE_HZ
    static let MODE_QUEUE_SIZE: Double = 15
    static let VELOCITY_QUEUE_SIZE: Double = 10
    static let VELOCITY_SETTING: Double = 4.7 / VELOCITY_QUEUE_SIZE
    static let OUTPUT_SAMPLE_EPOCH: Double = SAMPLE_HZ / Double(OUTPUT_SAMPLE_HZ)
    static let FEATURE_EXTRACTION_SIZE: Double = SAMPLE_HZ/2
    static let OUTPUT_DISTANCE_SETTING: Double = 1
    static let SEND_INTERVAL_SECOND: Double = 1 / VELOCITY_QUEUE_SIZE
    static let VELOCITY_MIN: Double = 4
    static let VELOCITY_MAX: Double = 18
    static let RF_SC_THRESHOLD_DR: Double = 0.67
    
    static let AMP_THRESHOLD: Double = 0.18
    static let TIME_THRESHOLD: Double = 100.0
    static let STOP_TIME_THRESHOLD: Double = 2000
    static let STEP_VALID_TIME: Double = 1000
    static let RF_SC_THRESHOLD_PDR: Double = 0.55
    
    static let MODE_CHANGE_TIME_CONDITION: Double = 10*1000
    static let MODE_CHANGE_RFLOW_TIME_OVER: Double = 0.1
    static let MODE_CHANGE_RFLOW_FORCE: Double = 0.065
    static let MODE_CHANGE_TIME_AFTER_ROUTE_TRACK: Double = 30*1000 // 30 seconds
}
