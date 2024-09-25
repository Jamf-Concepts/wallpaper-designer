//
//  Copyright 2024 Jamf. All rights reserved.
//

import Cocoa
import Foundation

let defaults   = UserDefaults.standard

var didRun          = false
let httpSuccess     = 200...299

struct AppInfo {
    static let dict        = Bundle.main.infoDictionary!
    static let version     = dict["CFBundleShortVersionString"] as! String
    static let build       = dict["CFBundleVersion"] as! String
    static let name        = dict["CFBundleExecutable"] as! String
    static let displayName = dict["CFBundleName"] as! String
    static var stopUpdates = false

    static let userAgentHeader = "\(String(describing: name.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!))/\(AppInfo.version)"
    
    static var bundlePath   = Bundle.main.bundleURL
    static var iconFile     = bundlePath.appendingPathComponent("Contents/Resources/AppIcon.icns")
    static let readme       = bundlePath.appendingPathComponent("Contents/Resources/README.html")
    static var targetScreen: Int?
    static var overlay: Int?
    static var defaultBackgroundColor: NSColor?
//    static var defaultBackgroundImage: NSImage? //unused?
    static var currentPreviewType = "iPad"
    static var defaultBackgroundImageURL = "green768x1024"
//    static var defaultBackgroundImageURL: String?
    static var defaultText: String?
    static var defaultFontName: String?
    static var defaultMenuItemFont = "Helvetica Neue"
    static var defaultFontSize: Float?
    static var defaultTextStyle = 0
    static var defaultTextStyleName = ""
    static var defaultTextColor: NSColor?
    static var defaultBackgroundIsColor = true
    
    static var textPosition   = 0   // 0 - above, 1 - below
    static var textAdjustment = 0.0
    static var qrCodeSize     = 3.0
    
    static var iPadQRCodeRect:   ObjectRect?
    static var iPadTextRect:     ObjectRect?
    static var iPhoneQRCodeRect: ObjectRect?
    static var iPhoneTextRect:   ObjectRect?
    static var qrCodeVertPos  = ["iPad":30, "iPhone":30]
    static var qrCodeHorizPos = ["iPad":50, "iPhone":50]
    static var textVertPos    = ["iPad":30, "iPhone":30]
    static var textHorizPos   = ["iPad":50, "iPhone":50]
    static var justification  = "center"
}

struct JamfProServer {
    static let settingsFile = "/Library/Managed Preferences/jamf.ie.jamfwallpaper.plist"
    static let maxThreads   = 5
    static var majorVersion = 0
    static var minorVersion = 0
    static var patchVersion = 0
    static var build        = ""
    static var authType     = "Basic"
    static var authCreds    = ""
    static var base64Creds  = ""
    static var validToken   = false
    static var version      = ""
    static var URL          = ""
    static var destination  = ""
    static var displayName  = ""
    static var username     = ""
    static var password     = ""
    static var tokenCreated = Date()
    static var authExpires  = 20.0
    static var currentCred  = ""
    static var accessToken  = ""
}

struct Log {
    static var path: String? = (NSHomeDirectory() + "/Library/Logs/")
    static var file          = "wallpaper.log"
    static var maxFiles      = 42
}
struct ObjectRect: Codable {
    var minX:    Double
    var minY:    Double
    var objectW: Double
    var objectH: Double
}

struct token {
    static var refreshInterval:UInt32 = 15*60  // 15 minutes
    static var sourceServer  = ""
    static var sourceExpires = ""
}

// get current time
func getCurrentTime() -> String {
    let current = Date()
    let localCalendar = Calendar.current
    let dateObjects: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second]
    let dateTime = localCalendar.dateComponents(dateObjects, from: current)
    let currentMonth  = leadingZero(value: dateTime.month!)
    let currentDay    = leadingZero(value: dateTime.day!)
    let currentHour   = leadingZero(value: dateTime.hour!)
    let currentMinute = leadingZero(value: dateTime.minute!)
    let currentSecond = leadingZero(value: dateTime.second!)
    let stringDate = "\(dateTime.year!)\(currentMonth)\(currentDay)_\(currentHour)\(currentMinute)\(currentSecond)"
    return stringDate
}

// add leading zero to single digit integers
func leadingZero(value: Int) -> String {
    var formattedValue = ""
    if value < 10 {
        formattedValue = "0\(value)"
    } else {
        formattedValue = "\(value)"
    }
    return formattedValue
}

public func timeDiff(startTime: Date) -> (Int, Int, Int, Double) {
    let endTime = Date()
//                    let components = Calendar.current.dateComponents([.second, .nanosecond], from: startTime, to: endTime)
//                    let timeDifference = Double(components.second!) + Double(components.nanosecond!)/1000000000
//                    WriteToLog.shared.message(stringOfText: "[ViewController.download] time difference: \(timeDifference) seconds")
    let components = Calendar.current.dateComponents([
        .hour, .minute, .second, .nanosecond], from: startTime, to: endTime)
    var diffInSeconds = Double(components.hour!)*3600 + Double(components.minute!)*60 + Double(components.second!) + Double(components.nanosecond!)/1000000000
    diffInSeconds = Double(round(diffInSeconds * 1000) / 1000)
//    let timeDifference = Int(components.second!) //+ Double(components.nanosecond!)/1000000000
//    let (h,r) = timeDifference.quotientAndRemainder(dividingBy: 3600)
//    let (m,s) = r.quotientAndRemainder(dividingBy: 60)
//    WriteToLog.shared.message(stringOfText: "[ViewController.download] download time: \(h):\(m):\(s) (h:m:s)")
    return (Int(components.hour!), Int(components.minute!), Int(components.second!), diffInSeconds)
//    return (h, m, s)
}
