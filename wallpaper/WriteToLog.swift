//
//  Copyright 2024 Jamf. All rights reserved.
//

import Foundation

// func cleanup - start
func cleanup() {
    var logArray: [String] = []
    var logCount: Int = 0
    do {
        let logFiles = try FileManager.default.contentsOfDirectory(atPath: Log.path!)
        
        for logFile in logFiles {
            let filePath: String = Log.path! + logFile
//            print("filePath: \(filePath)")
            logArray.append(filePath)
        }
        logArray.sort()
        logCount = logArray.count
        if didRun {
            // remove old history files
            if logCount > Log.maxFiles {
                for i in (0..<logCount-Log.maxFiles) {
//                    if LogLevel.debug { WriteToLog.shared.message(theMessage: "Deleting log file: " + logArray[i] + "\n") }
                    
                    do {
                        try FileManager.default.removeItem(atPath: logArray[i])
                    }
                    catch let error as NSError {
                        WriteToLog.shared.message(theMessage: "Error deleting log file:\n    " + logArray[i] + "\n    \(error)")
                    }
                }
            }
        } else {
            // delete empty log file
            if logCount > 0 {
                
            }
            do {
                try FileManager.default.removeItem(atPath: logArray[0])
            }
            catch let error as NSError {
                WriteToLog.shared.message(theMessage: "Error deleting log file:    \n" + Log.path! + logArray[0] + "    \(error)")
            }
        }
    } catch {
        WriteToLog.shared.message(theMessage: "no log files found")
    }
}

class WriteToLog {
    
    static let shared = WriteToLog()
    private init() { }
    
    var logFileW: FileHandle? = FileHandle(forUpdatingAtPath: "")
    let fm                    = FileManager()
    /*
    func logCleanup() {
//        print("[logCleanup] old log path: \(Log.path!)jamfcpr")
        
        if didRun {
            var logArray: [String] = []
            var logCount: Int = 0
            do {
                let logFiles = try fm.contentsOfDirectory(atPath: Log.path!)
                
                for logFile in logFiles {
                    let filePath: String = Log.path! + logFile
                    logArray.append(filePath)
                }
                logArray.sort()
                logCount = logArray.count
                // remove old log files
                if logCount-1 >= Log.maxFiles {
                    for i in (0..<logCount-Log.maxFiles) {
                        WriteToLog.shared.message(theMessage: "Deleting log file: " + logArray[i] + "\n")
                        do {
                            try fm.removeItem(atPath: logArray[i])
                        }
                        catch let error as NSError {
                            WriteToLog.shared.message(theMessage: "Error deleting log file:\n    " + logArray[i] + "\n    \(error)\n")
                        }
                    }
                }
            } catch {
                print("no history")
            }
        } else {
            // delete empty log file
            do {
                try fm.removeItem(atPath: Log.path! + Log.file)
            }
            catch let error as NSError {
                WriteToLog.shared.message(theMessage: "Error deleting log file:    \n" + Log.path! + Log.file + "\n    \(error)\n")
            }
        }
    }
    */

    func message(theMessage: String) {
        let logString = "\(getCurrentTime()) \(theMessage)\n"

        self.logFileW = FileHandle(forUpdatingAtPath: (Log.path! + Log.file))
//        let fullpath = Log.path! + Log.file
        
        let historyText = (logString as NSString).data(using: String.Encoding.utf8.rawValue)
        self.logFileW?.seekToEndOfFile()
        self.logFileW?.write(historyText!)
    }
}
