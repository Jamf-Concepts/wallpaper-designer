//
//  Copyright 2024 Jamf. All rights reserved.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    @objc func notificationsAction(_ sender: NSMenuItem) {
//        print("\(sender.identifier!.rawValue)")
//        WriteToLog.shared.message(theMessage: ["\(sender.identifier!.rawValue)"])
    }
    @IBAction func showAbout(_ sender: Any) {
        
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let helpWindowController = storyboard.instantiateController(withIdentifier: "aboutWC") as! NSWindowController
        if !windowIsVisible(windowName: "About") {
            helpWindowController.window?.hidesOnDeactivate = false
            helpWindowController.showWindow(self)
        } else {
            let windowsCount = NSApp.windows.count
            for i in (0..<windowsCount) {
                if NSApp.windows[i].title == "About" {
                    NSApp.windows[i].makeKeyAndOrderFront(self)
                    break
                }
            }
        }
    }
    
    @IBAction func showLogFolder(_ sender: Any) {
        if (FileManager.default.fileExists(atPath: Log.path!)) {
            NSWorkspace.shared.open(URL(fileURLWithPath: Log.path!))
        } else {
            _ = Alert.shared.display(header: "Alert", message: "There are currently no log files to display.")
        }
    }
    
    func windowIsVisible(windowName: String) -> Bool {
        let options = CGWindowListOption(arrayLiteral: CGWindowListOption.excludeDesktopElements, CGWindowListOption.optionOnScreenOnly)
        let windowListInfo = CGWindowListCopyWindowInfo(options, CGWindowID(0))
        let infoList = windowListInfo as NSArray? as? [[String: AnyObject]]
        for item in infoList! {
            if let _ = item["kCGWindowOwnerName"], let _ = item["kCGWindowName"] {
                if "\(item["kCGWindowOwnerName"]!)" == "Jamf Wallpaper" && "\(item["kCGWindowName"]!)" == windowName {
                    return true
                }
            }
        }
        return false
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        let encoder  = JSONEncoder()
        
        defaults.set(AppInfo.currentPreviewType, forKey: "currentPreviewType")
        defaults.set(AppInfo.textPosition, forKey: "textPosition")
        defaults.set(AppInfo.textHorizPos, forKey: "textHorizPos")
        defaults.set(AppInfo.textVertPos, forKey: "textVertPos")
        defaults.set(AppInfo.qrCodeSize, forKey: "qrCodeSize")
        defaults.set(AppInfo.qrCodeHorizPos, forKey: "qrCodeHorizPos")
        defaults.set(AppInfo.qrCodeVertPos, forKey: "qrCodeVertPos")
        defaults.set(AppInfo.overlay, forKey: "overlay")
        defaults.set(AppInfo.targetScreen, forKey: "targetScreen")
        
        if let encoded = try? encoder.encode(AppInfo.iPadQRCodeRect) {
            defaults.set(encoded, forKey: "iPadQRCodeRect")
        }
        if let encoded = try? encoder.encode(AppInfo.iPadTextRect) {
            defaults.set(encoded, forKey: "iPadTextRect")
        }
        if let encoded = try? encoder.encode(AppInfo.iPhoneQRCodeRect) {
            defaults.set(encoded, forKey: "iPhoneQRCodeRect")
        }
        if let encoded = try? encoder.encode(AppInfo.iPhoneTextRect) {
            defaults.set(encoded, forKey: "iPhoneTextRect")
        }
        
        defaults.set(AppInfo.defaultText, forKey: "defaultText")
        defaults.set(AppInfo.defaultFontName, forKey: "defaultFontName")
        defaults.set(AppInfo.defaultMenuItemFont, forKey: "defaultMenuItemFont")
        defaults.set(AppInfo.defaultFontSize, forKey: "defaultFontSize")
        defaults.set(AppInfo.defaultTextStyle, forKey: "defaultTextStyle")
        defaults.set(AppInfo.defaultBackgroundImageURL, forKey: "defaultBackgroundImageURL")

        if let _ = AppInfo.defaultTextColor {
            do {
                let colorData = try NSKeyedArchiver.archivedData(withRootObject: AppInfo.defaultTextColor!, requiringSecureCoding: false)
                defaults.set(colorData, forKey: "defaultTextColor")
            } catch {
                WriteToLog.shared.message(theMessage: "error saving text color")
            }
        }
        defaults.set(AppInfo.defaultBackgroundIsColor, forKey: "defaultBackgroundIsColor")
        if AppInfo.defaultBackgroundIsColor {
            do {
                let colorData = try NSKeyedArchiver.archivedData(withRootObject: AppInfo.defaultBackgroundColor!, requiringSecureCoding: false)
                defaults.set(colorData, forKey: "defaultBackgroundColor")
            } catch {
                WriteToLog.shared.message(theMessage: "error saving background color")
            }
        }
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    // quit the app if the window is closed - start
    func applicationShouldTerminateAfterLastWindowClosed(_ app: NSApplication) -> Bool {
        return true
    }


}

