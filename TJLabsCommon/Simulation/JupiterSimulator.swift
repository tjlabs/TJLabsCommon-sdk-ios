
import Foundation

public class JupiterSimulator {
    public static let shared = JupiterSimulator()
    init() { }
    
    var isSimulationMode: Bool = false
    var bleFileName: String = ""
    var sensorFileName: String = ""
    
    var simulationBleData = [[String: Double]]()
    var simulationSensorData = [SensorData]()
    var simulationTime: Double = 0
    var bleLineCount: Int = 0
    var sensorLineCount: Int = 0
    
    public func initailize() {
        isSimulationMode = false
        bleFileName = ""
        sensorFileName = ""
        simulationBleData = [[String: Double]]()
        simulationSensorData = [SensorData]()
        simulationTime = 0
        bleLineCount = 0
        sensorLineCount = 0
    }
    
    public func setSimulationMode(flag: Bool, bleFileName: String, sensorFileName: String) {
        self.isSimulationMode = flag
        self.bleFileName = bleFileName
        self.sensorFileName = sensorFileName
        
        if (self.isSimulationMode) {
            let result = JupiterFileManager.shared.loadFilesForSimulation(bleFile: self.bleFileName, sensorFile: self.sensorFileName)
            simulationBleData = result.0
            simulationSensorData = result.1
            simulationTime = TJLabsUtilFunctions.shared.getCurrentTimeInMillisecondsDouble()
        }
    }
    
    public func getSimulationBleData() -> [String: Double] {
        var bleAvg = [String: Double]()
        if bleLineCount < simulationBleData.count-1 {
            bleAvg = simulationBleData[bleLineCount]
            bleLineCount += 1
        }
        return bleAvg
    }
    
    public func getSimulationSensorData() -> SensorData {
        var sensorData = SensorData()
        if sensorLineCount < simulationSensorData.count-1 {
            sensorData = simulationSensorData[sensorLineCount]
            sensorLineCount += 1
        }
        return sensorData
    }
}
