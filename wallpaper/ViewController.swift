//
//  Copyright 2024 Jamf. All rights reserved.
//

import AppKit
import Cocoa
import Foundation

class ViewController: NSViewController, NSTextFieldDelegate, NSTextViewDelegate, SendingLoginCompleteDelegate, SendingTextFormatDelegate, NSImageDelegate, SendingStringDelegate {
    
    struct LoginWindow {
        static var show = true
    }
    
    @IBAction func showReadme_button(_ sender: Any) {
        // Open the link in the external browser.
        NSWorkspace.shared.open(AppInfo.readme)
//        NSWorkspace.shared.open([appInfo.readme], withApplicationAt: URL(string: "/Applications/Safari.app")!, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
    }
    
    
    let colorPanel = NSColorWell()
    let decoder    = JSONDecoder()
    
    @IBOutlet weak var yPos_label: NSTextField!
    @IBOutlet weak var xPos_label: NSTextField!
    
    @IBOutlet weak var templateTime_textfield: NSTextField!
    @IBOutlet weak var templateDate_textfield: NSTextField!
    
    
    @IBOutlet weak var selectWallpaper_button: NSPopUpButton!
    @IBOutlet weak var iPhonePreview_button: NSButton!
    @IBOutlet weak var iPadPreview_button: NSButton!
    @IBOutlet weak var previewFrame_imageview: NSImageView!
    @IBOutlet weak var backgroundImage_imageview: NSImageView!
        
    @IBOutlet weak var overlay_button: NSPopUpButton!
    
    @IBOutlet weak var qrCodeSize_slider: NSSlider!
    @IBOutlet weak var qrCodeType_button: NSPopUpButton!
    @IBOutlet weak var qrCodeStringEdit_button: NSButton!
    
    @IBOutlet weak var target_button: NSPopUpButton!
    
    @IBOutlet var addText_textview: NSTextView!
    @IBOutlet weak var selectScope_button: NSPopUpButton!
    @IBOutlet weak var scopeLabel_label: NSTextField!
    @IBOutlet weak var scopeValue_textfield: NSTextField!
    
    @IBOutlet weak var fetching_label: NSTextField!
    @IBOutlet weak var spinner_indicator: NSProgressIndicator!
    
    @IBOutlet weak var scopeMatches_scrollview: NSScrollView!
    @IBOutlet weak var scopeMatches_tableview: NSTableView!
    
    @IBOutlet weak var currentProgress_indicator: NSProgressIndicator!
    
    @IBOutlet weak var stop_button: NSButton!
    
    @IBOutlet weak var setBackground_button: NSButton!
    @IBOutlet weak var iPadWallpaper_menuItem: NSMenuItem!
    @IBOutlet weak var iPhoneWallpaper_menuItem: NSMenuItem!
    
    var iPadWallpapers:[NSImage] = [NSImage(named: "iPad-healthcare-1")!,
                                NSImage(named: "iPad-healthcare-2")!,
                                NSImage(named: "iPad-high-ed-1")!,
                                NSImage(named: "iPad-high-ed-2")!,
                                NSImage(named: "iPad-k-12-1")!,
                                NSImage(named: "iPad-k-12-2")!]
    var iPhoneWallpapers:[NSImage] = [NSImage(named: "iPhone-healthcare-1")!,
                                NSImage(named: "iPhone-healthcare-2")!,
                                NSImage(named: "iPhone-high-ed-1")!,
                                NSImage(named: "iPhone-high-ed-2")!,
                                NSImage(named: "iPhone-k-12-1")!,
                                NSImage(named: "iPhone-k-12-2")!]
    
    var deviceInfo   = [String:String]()    // payloadVar:value
    var serialToName = [String:String]()    // serial number:device name
    
    var backgroundOrText  = "background"
    var stopMsgDisplayed  = false
    
    var origBackgroundW   = 0.0
    var origBackgroundH   = 0.0
    var wallpaperFilename = ""
    var qrCodeType        = "Serial Number"
    
//    var jamfUser          = ""
//    var jamfPassword      = ""
    var jamfBase64Creds   = ""
    var endpointNameId    = [String:Int]()
    var currentScope      = ""
    var whichEndpoint     = "mobiledevices"
    let whichEndpointDict = ["mobiledevicegroups":"mobile_device_groups","mobiledevices":"mobile_devices"]
    var textIsBold        = false
    var textIsItalic      = false
    var textIsUnderlined  = false
    
    var scopeArray      = [String]()
    var allObjects      = [[String:Any]]()
    var allDevices      = [[String:Any]]()
    var allItemsArray:    [String]?      // all groups or devices (filtered list)
    var rawScopeArray   = [String]()     // all groups or devices
    var identifierText  = "This is a test"
    var backgroundImage = NSImage(named: "green768x1024")!
    var qrCodeImage:         NSImage?
    var qrCodeImageDeployed: NSImage?
    var textImage:           NSImage?
    var finishedBackground:  NSImage?
    var wallpaperToPublish:  NSImage?
    
    var startTime: Date?
    var endTime:   Date?
    var deployDateTime = ""
    
    @IBOutlet weak var connectedTo_label: NSTextField!
    
    var progressScale    = 1.0
    var commandsComplete = 0
    var successCount     = 0
    var failCount        = 0
    
    // image positions - start
    var newImage:NSImage?
    var startX       = 0.0
    var startY       = 0.0
    var cropWidth    = 0.0
    var cropHeight   = 0.0
    var startQRCodeX = 0.0
    var startQRCodeY = 0.0
    var startTextX   = 0.0
    var startTextY   = 0.0
    var bivX   = 0.0    // backgroundImage_imageview minX
    var bivY   = 0.0    // backgroundImage_imageview minY
    var dx     = 0.0  // distance between image.minX and mouseDown.x
    var dy     = 0.0  // distance between image.minY and mouseDown.y
    var qrImageRect     = CGRect(x: 0, y: 0, width: 0, height: 0)
    var    textRect     = CGRect(x: 0, y: 0, width: 0, height: 0)
    var positionOffsetX = 0.0   // distance between mouse and object minX
    var positionOffsetY = 0.0   // distance between mouse and objest minY
    var objectToMove    = ""
    var deployScaleAdj  = 1.0
    var withShiftKey    = false
    
    var loadURL: URL? {
        didSet {
            do {
                let bookmark = try loadURL?.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
                defaults.set(bookmark, forKey: "bookmark")
            } catch let error as NSError {
                print("[PreferencesViewController] Set Bookmark Fails: \(error.description)")
            }
        }
    }
    
    @IBOutlet weak var dragShadow_button: NSButton!
    // image positions - end
    
    @IBAction func selectedRow_action(_ sender: Any) {
        if scopeMatches_tableview.selectedRow < allItemsArray?.count ?? 0 {
            scopeValue_textfield.stringValue = allItemsArray![scopeMatches_tableview.selectedRow]
            scopeMatches_scrollview.isHidden = true
        } else {
            scopeValue_textfield.stringValue = ""
        }
    }
    
    @objc func updateWallpaper(_ sender: NSMenuItem) {
        AppInfo.defaultBackgroundIsColor = false
        backgroundImage = NSImage(named: sender.title)!
        AppInfo.defaultBackgroundImageURL = sender.title
        
        wallpaperFilename = AppInfo.defaultBackgroundImageURL
        print("\n selected walllpaper: \(sender.title)")
        print("selected wallpaper W: \(backgroundImage.size.width)")
        print("selected wallpaper H: \(backgroundImage.size.height)")
        preview_action(deviceType: AppInfo.currentPreviewType, deviceInfo: [:], action: "preview")
    }
    @IBAction func selectWallpaper_action(_ sender: NSButton) {
//        print("[selectWallpaper_action] \(sender.title)")
        if sender.title == "Browse..." {
            selectImage_action(sender)
        }
        selectWallpaper_button.selectItem(at: 0)
        preview_action(deviceType: AppInfo.currentPreviewType, deviceInfo: [:], action: "preview")
    }
    @IBAction func overlay_action(_ sender: NSButton) {
        switch overlay_button.titleOfSelectedItem! {
        case "Text":
            AppInfo.overlay = 1
        case "QR Code":
            AppInfo.overlay = 2
        case "None":
            AppInfo.overlay = 3
        default:
            AppInfo.overlay = 0
        }
        preview_action(deviceType: AppInfo.currentPreviewType, deviceInfo: [:], action: "preview")
    }
    @IBAction func targetScreen_action(_ sender: NSButton) {
        switch target_button.titleOfSelectedItem! {
        case "Home Screen":
            AppInfo.targetScreen = 2
        case "Both":
            AppInfo.targetScreen = 3
        default:
            AppInfo.targetScreen = 1
        }
    }
    
    @IBAction func stop_action(_ sender: Any) {
        stop_button.isEnabled = false
        AppInfo.stopUpdates = true
    }
    
    @IBAction func qrCodeSize_action(_ sender: Any) {
        AppInfo.qrCodeSize = qrCodeSize_slider.doubleValue
        generateQRCode(from: identifierText, scale: 1.0, purpose: "preview")
        preview_action(deviceType: AppInfo.currentPreviewType, deviceInfo: [:], action: "preview")
    }
    
    @IBAction func qrCodeType_action(_ sender: NSPopUpButton) {
//        print("qr code type: \(sender.titleOfSelectedItem)")
        defaults.set(sender.titleOfSelectedItem!, forKey: "qrCodeType")
        if sender.titleOfSelectedItem! == "Custom Text" {
            performSegue(withIdentifier: "qrCodeType", sender: nil)
            qrCodeStringEdit_button.isHidden = false
        } else {
            qrCodeStringEdit_button.isHidden = true
            qrCodeType_button.toolTip = ""
        }
    }
    @IBAction func qrCodeStringEdit_action(_ sender: NSButton) {
        performSegue(withIdentifier: "qrCodeType", sender: nil)
    }
    
    
    @IBAction func previewType_action(_ sender: NSButton) {
        AppInfo.currentPreviewType = sender.toolTip!
        
        setPreviewButton(deviceType: AppInfo.currentPreviewType)
        preview_action(deviceType: AppInfo.currentPreviewType, deviceInfo: [:], action: "preview")
    }
    func setPreviewButton(deviceType: String) {
        if deviceType == "iPad" {
            iPhonePreview_button.isBordered = false
            iPadPreview_button.bezelColor = .blue
            iPadPreview_button.isBordered = true
        } else {
            iPadPreview_button.isBordered = false
            iPhonePreview_button.bezelColor = .blue
            iPhonePreview_button.isBordered = true
        }
    }
    
    @IBAction func selectScope_action(_ sender: NSButton) {
        scopeMatches_scrollview.isHidden   = true
        scopeMatches_tableview.stringValue = ""
        rawScopeArray.removeAll()
        allItemsArray?.removeAll()
        allObjects.removeAll()
        allDevices.removeAll()
        endpointNameId.removeAll()
        let selectedScope = sender.title
        var objectName    = ""
        switch selectedScope {
        case "Group":
            scopeLabel_label.stringValue = "Group Name:"
            whichEndpoint                = "mobiledevicegroups"
        case "One Device":
            scopeLabel_label.stringValue = "Device Serial Number:"
            whichEndpoint                = "mobiledevices"
        default:
            scopeLabel_label.stringValue       = ""
            scopeLabel_label.isHidden          = true
            scopeValue_textfield.stringValue   = ""
            scopeValue_textfield.isHidden      = true
            if selectedScope == "Select" {
                self.setBackground_button.isEnabled = false
                return
                
            }
            whichEndpoint = "mobiledevices"
        }
        scopeValue_textfield.stringValue = (currentScope == selectedScope) ? scopeValue_textfield.stringValue:""
        currentScope = selectedScope
//        print("selectedScope: \(selectedScope)")
//        print("whichEndpoint: \(whichEndpoint)")
//        if selectedScope == "Group" || selectedScope == "One Device" {
            let skip = (selectedScope == "Group") ? 0:-1
            fetching_label.isHidden = false
            spinner_indicator.startAnimation(self)
            print("lookup mobiledevices")
            JamfPro.shared.jsonAction(theServer: JamfProServer.destination, theEndpoint: "mobiledevices", theMethod: "GET", retryCount: 0) { [self]
                (result: ([String:AnyObject],Int)) in
                let (jsonResults,_) = result
//                print("mobile devices: \(jsonResults)")
                if let _ = jsonResults[whichEndpointDict["mobiledevices"]!] as? [[String:Any]] {
//                    scopeMatches_scrollview.isHidden = false
                    allDevices = jsonResults[whichEndpointDict["mobiledevices"]!] as! [[String:Any]]
                    
                    JamfPro.shared.jsonAction(theServer: JamfProServer.destination, theEndpoint: "mobiledevicegroups", theMethod: "GET", retryCount: skip) { [self]
                        (result: ([String:AnyObject],Int)) in
                        let (jsonResults,_) = result
                        print("mobiledevice group count: \(jsonResults.count)")
                        switch selectedScope {
                        case "Group":
                            if let _ = jsonResults[whichEndpointDict[whichEndpoint]!] as? [[String:Any]] {
                                allObjects = jsonResults[whichEndpointDict[whichEndpoint]!] as! [[String:Any]]
                            }
                        default:
                            allObjects = allDevices
                        }
//                        print("allObjects: \(allObjects)")
                        if allObjects.count == 0 {
                            let theObject = (selectedScope == "Group") ? "groups":"devices"
                            fetching_label.isHidden = true
                            spinner_indicator.stopAnimation(self)
                            _ = Alert.shared.display(header: "No \(theObject) found", message: "")
                            return
                        }
                        
                        if selectedScope != "All Devices" {
                            scopeMatches_scrollview.isHidden = false
                        }
                        WriteToLog.shared.message(theMessage: "found \(allObjects.count) mobile devices on the server")
                        for oneObject in allObjects {
                            if let objectId = oneObject["id"] as? Int {
                                switch selectedScope {
                                case "Group":
                                    objectName = oneObject["name"] as! String
                                case "One Device", "All Devices":
                                    objectName = oneObject["serial_number"] as! String
                                    serialToName[objectName] = oneObject["name"] as? String ?? "unknown"
                                default:
                                    objectName = "Unknown"
                                }
                                endpointNameId["\(objectName.lowercased())"] = objectId
                                rawScopeArray.append("\(objectName)")
                                allItemsArray = rawScopeArray.sorted()
                                scopeMatches_tableview.reloadData()
                            }
                        }
                        fetching_label.isHidden = true
                        spinner_indicator.stopAnimation(self)
                        if selectedScope != "All Devices" {
                            scopeLabel_label.isHidden     = false
                            scopeValue_textfield.isHidden = false
                            scopeMatches_tableview.selectRowIndexes(.init(integer: 0), byExtendingSelection: false)
                            scopeValue_textfield.becomeFirstResponder()
                        }
                        self.setBackground_button.isEnabled = true
                    }   // JamfPro.shared.jsonAction(theServer: JamfProServer.destination, theEndpoint: "mobiledevicegroups" - end

                } else {   // if let _ = jsonResults[whichEndpointDict["mobiledevices"]!] - end
                    fetching_label.isHidden = true
                    spinner_indicator.stopAnimation(self)
                    selectScope_button.selectItem(at: 0)
                }
                
            }   // JamfPro.shared.jsonAction(theServer: JamfProServer.destination, theEndpoint: "mobiledevices" - end
//        }
    }
    
    func generateQRCode(from string: String, scale: Double, purpose: String) {
        let data = string.data(using: String.Encoding.ascii)

        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: AppInfo.qrCodeSize*scale, y: AppInfo.qrCodeSize*scale)

            if let output = filter.outputImage?.transformed(by: transform) {
                let rep = NSCIImageRep(ciImage: output)
                let nsImage = NSImage(size: rep.size)
                nsImage.addRepresentation(rep)
                if purpose == "preview" {
                    qrCodeImage = nsImage
                } else {
                    qrCodeImageDeployed = nsImage
                    generateQRCode(from: identifierText, scale: 1.0, purpose: "preview")
                }
            }
//            if purpose == "deploy" {
//                let transform = CGAffineTransform(scaleX: appInfo.qrCodeSize*scale, y: appInfo.qrCodeSize*scale)
//
//                if let output = filter.outputImage?.transformed(by: transform) {
//                    let rep = NSCIImageRep(ciImage: output)
//                    let nsImage = NSImage(size: rep.size)
//                    nsImage.addRepresentation(rep)
//                    qrCodeImageDeployed = nsImage
//                }
//            }
        }
    }
    
    
    func selectImage_action(_ sender: NSButton) {
        let openPanel = NSOpenPanel()
        openPanel.allowedFileTypes = ["jpeg","jpg","png"]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        let response = openPanel.runModal()
        guard response == .OK else { return }
        loadURL = openPanel.url 
        backgroundImage = NSImage(contentsOf: loadURL!)!
        wallpaperFilename = loadURL!.lastPathComponent

        backgroundImage_imageview.image = backgroundImage
        origBackgroundW = (backgroundImage.size.width)
        origBackgroundH = (backgroundImage.size.height)
        
        AppInfo.defaultBackgroundImageURL = loadURL!.absoluteString.removingPercentEncoding!.replacingOccurrences(of: "file://", with: "")
        
        defaults.set(false, forKey: "defaultBackgroundIsColor")
        AppInfo.defaultBackgroundIsColor = false
        preview_action(deviceType: AppInfo.currentPreviewType, deviceInfo: [:], action: "preview")
    }
    
    func scaleFilter(input:CIImage, aspectRatio : Double, scale : Double) -> CIImage
    {
        let scaleFilter = CIFilter(name:"CILanczosScaleTransform")!
        scaleFilter.setValue(input, forKey: kCIInputImageKey)
        scaleFilter.setValue(scale, forKey: kCIInputScaleKey)
        scaleFilter.setValue(aspectRatio, forKey: kCIInputAspectRatioKey)
        return scaleFilter.outputImage!
    }
    func preview_action(deviceType: String, deviceInfo: [String:String], action: String) {
                
        var origBackground: NSImage?
        var origBkgndPixelW = 0.0
        var origBkgndPixelH = 0.0
        
        var fontScale       = 1.0
        
        origBackground = backgroundImage
        backgroundImage_imageview.toolTip = wallpaperFilename
        
        let imageRep = NSCIImageRep(ciImage: ciImage(theImage: backgroundImage)!)
        origBkgndPixelW = Double(imageRep.pixelsWide)
        origBkgndPixelH = Double(imageRep.pixelsHigh)
        
        // pixel dimensions
//        print("      origBkgndPixelW: \(origBkgndPixelW)")
//        print("      origBkgndPixelH: \(origBkgndPixelH)")
//        print(" origBackground width: \(backgroundImage.size.width)")
//        print("origBackground height: \(backgroundImage.size.height)")
        
//        let dpi = (origBkgndPixelH/backgroundImage.size.height)*72.0
//        print("dpi: \(Int(dpi))")
//        print("scale: \(backgroundImage.scal)")
        
        if deviceType != "iPad" {
            fontScale = 0.75
        }
        
        let standardW = (deviceType == "iPad" ) ? 768.0:414.0   //390.0
        let standardH = (deviceType == "iPad" ) ? 1024.0:896.0  //844.0
        
        // determine if cropping is based on width or heigth
        if origBkgndPixelW/origBkgndPixelH > standardW/standardH {
            // crop based on height
//            print("crop based on height, scale: \(standardW/standardH)")
            cropHeight = origBkgndPixelH    //*0.8
            cropWidth  = cropHeight*(standardW/standardH)
        } else {
            // crop based on width
//            print("crop based on width, scale: \(standardH/standardW)")
            cropWidth = origBkgndPixelW
            cropHeight = cropWidth*standardH/standardW
        }
        
//        let rectScaleW = 2*origBackground!.size.width/standardW
//        let rectScaleH = 2*origBackground!.size.height/standardH
//        print("(rectScaleW, rectScaleH): (\(rectScaleW), \(rectScaleH))")
        
        deployScaleAdj = min(2*origBackground!.size.width/standardW, 2*origBackground!.size.height/standardH)
        
        // Crop the image to approximate device dimensions
        let cropZone = CGRect(x:(origBkgndPixelW-cropWidth)/2.0,
                              y:(origBkgndPixelH-cropHeight)/2.0,
                              width:cropWidth,
                              height:cropHeight)
        
//        print("cropZoneW: \(cropWidth)")
//        print("cropZoneH: \(cropHeight)")

           // Perform cropping in Core Graphics
        let theScale      = standardW/(cropWidth*2)
//        let ciBackground2 = scaleFilter(input: ciImage(theImage: backgroundImage)!.cropped(to: cropZone), aspectRatio: 1.0, scale: theScale)
        
        let ciBackground2 = ciImage(theImage: backgroundImage)!.cropped(to: cropZone)
//        let croppedImageRep = NSCIImageRep(ciImage: ciBackground2)
//        let croppedBackgroundW = Double(croppedImageRep.pixelsWide)
//        let croppedBackgroundH = Double(croppedImageRep.pixelsHigh)
        
        let context = CIContext()
        let cgImage = context.createCGImage(ciBackground2, from: ciBackground2.extent)!
        // need cgImage
        let ciBackground4 = NSImage(cgImage: cgImage, size: .zero)    //NSImage(cgImage: ciBackground2.cgImage!, size: cropZone.size)
        var ciBackground = ciImage(theImage: ciBackground4)!
        ciBackground = scaleFilter(input: ciBackground, aspectRatio: 1.0, scale: theScale)
        
        let rep = NSCIImageRep(ciImage: ciBackground)
        let background    = NSImage(size: rep.size)
        background.addRepresentation(rep)
        let backgroundW   = (background.size.width)
//        let backgroundH   = (background.size.height)
//        print("[resize] backgroundW: \(backgroundW)")
//        print("[resize] backgroundH: \(backgroundH)\n")
        // resize - end
        
        if let _ = qrCodeImage {
//            print("\naction: \(action), qrCode exists\n")
        } else {
            generateQRCode(from: identifierText, scale: 1.0, purpose: "preview")
        }

        if let qrCodeOverlay = qrCodeImage {

            var lines = (AppInfo.defaultText!.occurrencesOf(string: "\n"))+1
            
            // payload variables
            var displayedText = AppInfo.defaultText
            
            if deviceType == "iPad" {
                templateTime_textfield.setFrameOrigin(NSPoint(x: 212, y: 503))
                templateDate_textfield.setFrameOrigin(NSPoint(x: 186, y: 480))
            } else {
                templateTime_textfield.setFrameOrigin(NSPoint(x: 212, y: 467))
                templateDate_textfield.setFrameOrigin(NSPoint(x: 186, y: 444))
            }
            
            if action == "deploy" {
                for (key, value) in deviceInfo {
                    displayedText = displayedText!.replacingOccurrences(of: "$\(key)", with: "\(value)", options: .caseInsensitive)
                }
            }
            
            let paragraphStyle       = NSMutableParagraphStyle()
            switch AppInfo.justification {
            case "left":
                paragraphStyle.alignment = .left
            case "right":
                paragraphStyle.alignment = .right
            default:
                paragraphStyle.alignment = .center
            }
             
            let currentFont    = NSFont(name: AppInfo.defaultFontName!, size: CGFloat(AppInfo.defaultFontSize!)*fontScale)
            
            paragraphStyle.minimumLineHeight = CGFloat((currentFont!.xHeight*1.1)*2.0)
//            paragraphStyle.minimumLineHeight = (deviceType == "iPad") ? CGFloat((currentFont!.xHeight)*2.0):CGFloat((currentFont!.xHeight*1.1)*2.0)
            
            let textAttributes = [NSAttributedString.Key.foregroundColor: AppInfo.defaultTextColor ?? NSColor.black, NSAttributedString.Key.font: currentFont!, NSAttributedString.Key.paragraphStyle: paragraphStyle]

            let attributedText = NSMutableAttributedString(string: displayedText!, attributes: textAttributes)

            if AppInfo.defaultTextStyle >= 4 {
                attributedText.addAttribute(.underlineStyle, value: 1, range: NSRange(location: 0, length: displayedText!.count))
            }
            
            newImage    = NSImage(size: background.size)
            let qrImage = NSImage(size: qrCodeOverlay.size)
            
            var newImageRect: CGRect = .zero
                        
//            print("paragraphStyle.minimumLineHeight: \(paragraphStyle.minimumLineHeight)")
//            print("                     backgroundH: \(backgroundH)")
//            print("                CGFloat(vertPos): \(CGFloat(vertPos))")
//            print("          appInfo.textAdjustment: \(appInfo.textAdjustment)")
            
            let fontAttributes: [NSAttributedString.Key : Any] = [NSAttributedString.Key.font: NSFont(name: AppInfo.defaultFontName!, size: CGFloat(AppInfo.defaultFontSize!)) as Any]
            
            let lineArray = displayedText!.split(separator: "\n")
            for theLine in lineArray {
                let longString    = theLine.replacingOccurrences(of: "\n", with: " ")
                var displayedLine = ""
                
                let wordArray = longString.split(separator: " ")
                for i in 0..<wordArray.count {
                    if i == 0 {
                        displayedLine = String(wordArray[i])
                    } else {
                        displayedLine = displayedLine + " " + String(wordArray[i])
                    }
//                    print("displayedLine.size: \(displayedLine.size(withAttributes: fontAttributes).width) \t \(backgroundW)")
                    if displayedLine.size(withAttributes: fontAttributes).width*0.8 > backgroundW {
                        lines += 1
//                        print("text wrapped")
                        displayedLine = String(wordArray[i])
                    }
                }
            }
            lines += 1
            switch action {
            case "dragged-qrCode":
                let currentQrcX = qrImageRect.minX
                let currentQrcY = qrImageRect.minY
                qrImageRect = CGRect(origin: .init(x: currentQrcX+dx, y: currentQrcY+dy), size: qrImage.size)
                dx = 0.0
                dy = 0.0
            case "dragged-text":
                let currentTextX = textRect.minX
                let currentTextY = textRect.minY
                textRect = CGRect(origin: .init(x: currentTextX+dx, y: currentTextY+dy), size: textRect.size)
                dx = 0.0
                dy = 0.0
            default:
                if deviceType == "iPad" {
                    if AppInfo.iPadTextRect!.objectW == 0 || AppInfo.iPadTextRect!.objectH == 0 {
                        AppInfo.iPadTextRect!.minX    = 10
                        AppInfo.iPhoneTextRect!.minY  = (AppInfo.iPadQRCodeRect!.minY+AppInfo.iPadQRCodeRect!.objectH+10)
                        AppInfo.iPadTextRect!.objectW = backgroundW-20
                        AppInfo.iPadTextRect!.objectH = CGFloat((Int(paragraphStyle.minimumLineHeight))*lines)
                    }
                    qrImageRect = CGRect(x: AppInfo.iPadQRCodeRect!.minX, y: AppInfo.iPadQRCodeRect!.minY, width: qrImage.size.width, height: qrImage.size.width)
                    textRect = CGRect(x: AppInfo.iPadTextRect!.minX, y: AppInfo.iPadTextRect!.minY, width: AppInfo.iPadTextRect!.objectW, height: CGFloat((Int(paragraphStyle.minimumLineHeight))*lines))
                } else {
                    if AppInfo.iPhoneTextRect!.objectW == 0 || AppInfo.iPhoneTextRect!.objectH == 0 {
                        AppInfo.iPhoneTextRect!.minX    = 10
                        AppInfo.iPhoneTextRect!.minY  = (AppInfo.iPhoneQRCodeRect!.minY+AppInfo.iPhoneQRCodeRect!.objectH+10)
                        AppInfo.iPhoneTextRect!.objectW = backgroundW-20
                        AppInfo.iPhoneTextRect!.objectH = CGFloat((Int(paragraphStyle.minimumLineHeight))*lines)
                    }
                    qrImageRect = CGRect(x: AppInfo.iPhoneQRCodeRect!.minX, y: AppInfo.iPhoneQRCodeRect!.minY, width: qrImage.size.width, height: qrImage.size.width)
                    textRect = CGRect(x: AppInfo.iPhoneTextRect!.minX, y: AppInfo.iPhoneTextRect!.minY, width: AppInfo.iPhoneTextRect!.objectW, height: CGFloat((Int(paragraphStyle.minimumLineHeight))*lines))
                }
            }
            
            textImage = NSImage(size: textRect.size)
            var textImageRect: CGRect = .zero
                    
            if textImage!.size.width != 0 && textImage!.size.height != 0 {
                textImage?.lockFocus()
                    textImageRect.size = textImage!.size
                    attributedText.draw(in: textImageRect)
                textImage?.unlockFocus()
            }
            
            // for preview - start
            newImage!.lockFocus()
            newImageRect.size        = newImage!.size
            ciBackground4.draw(in: newImageRect)
            
            if AppInfo.overlay! < 2 {
                attributedText.draw(in: textRect)
            }
            if AppInfo.overlay == 0 || AppInfo.overlay == 2 {
                qrCodeOverlay.draw(in: qrImageRect)
            }
            newImage!.unlockFocus()
            finishedBackground = newImage
            backgroundImage_imageview.image = finishedBackground
            
//            print("[preview]                 view size: \(self.view.frame)")
//            print("[preview]    previewFrame_imageview: \(previewFrame_imageview.frame)")
//            print("[preview] backgroundImage_imageview: \(backgroundImage_imageview.frame)")
//            print("[preview]        finishedBackground: \(finishedBackground!.size)")
//            print("[preview]               qrImageRect: \(qrImageRect)")
//            print("[preview]                  textRect: \(textRect)")
//            print("[preview]                  newImage: \(newImage!.size)")
            
            var qrFromCenterX   = 0.0       // minX to center
            var textFromCenterX = 0.0      // minY to center
            var qrFromCenterY   = 0.0       // maxX to center
            var textFromCenterY = 0.0       // maxY to center
            if deviceType == "iPad" {
                AppInfo.iPadQRCodeRect = ObjectRect(minX: qrImageRect.minX, minY: qrImageRect.minY, objectW: qrImageRect.width, objectH: qrImageRect.height)
                AppInfo.iPadTextRect = ObjectRect(minX: textRect.minX, minY: textRect.minY, objectW: textRect.width, objectH: textRect.height)
            } else {
                AppInfo.iPhoneQRCodeRect = ObjectRect(minX: qrImageRect.minX, minY: qrImageRect.minY, objectW: qrImageRect.width, objectH: qrImageRect.height)
                AppInfo.iPhoneTextRect = ObjectRect(minX: textRect.minX, minY: textRect.minY, objectW: textRect.width, objectH: textRect.height)
            }
            qrFromCenterX   = finishedBackground!.size.width/2 - qrImageRect.minX
            qrFromCenterY   = finishedBackground!.size.height/2 - qrImageRect.minY
            textFromCenterX = finishedBackground!.size.width/2 - textRect.minX
            textFromCenterY = finishedBackground!.size.height/2 - textRect.maxY
            // for preview - end
            
          
            // for deployment - start
            if action == "deploy" {
                // get date / time
                let today            = NSDate()
                let formatter        = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
//                formatter.dateFormat = "HH:mm E, d MMM y"
                deployDateTime       = formatter.string(from: today as Date)
                
                let publishedImage = NSImage(size: origBackground!.size)
                
//                print("publishedImage size: \(publishedImage.size)")
                
                let deployFontAdj = (deviceType == "iPad") ? 1.0:0.75
                
                let deployedFont   = NSFont(name: AppInfo.defaultFontName!, size: CGFloat(AppInfo.defaultFontSize!)*(fontScale+deployFontAdj)*origBackground!.size.height/standardH)
               
//                paragraphStyle.minimumLineHeight = CGFloat((deployedFont?.xHeight ?? 24)*2.0)
               
                let textAttributes = [NSAttributedString.Key.foregroundColor: AppInfo.defaultTextColor ?? NSColor.black, NSAttributedString.Key.font: deployedFont!, NSAttributedString.Key.paragraphStyle: paragraphStyle]

                let deployedText  = NSMutableAttributedString(string: displayedText!, attributes: textAttributes)
//                let deployedText  = NSMutableAttributedString(string: timeDate + "\n" + displayedText!, attributes: textAttributes)

                if AppInfo.defaultTextStyle >= 4 {
                   deployedText.addAttribute(.underlineStyle, value: 1, range: NSRange(location: 0, length: displayedText!.count))
                }
                
//                print("croppedImageRep.size.height: \(croppedImageRep.size.height)")
//                print("origBackground!.size.height: \(origBackground!.size.height)")
                
                let qrDisplayW = qrImage.size.width*deployScaleAdj
                print("qrDisplayW orig: \(qrImage.size.width), qrDisplayW display: \(qrDisplayW)")

                let wallpaperCenterX = backgroundImage.size.width/2
                let wallpaperCenterY = backgroundImage.size.height/2
                let displayTextH     = CGFloat(deployedFont!.pointSize*1.5*CGFloat(lines+1)*fontScale)
//                let displayTextH     = (deviceType == "iPad") ? CGFloat(deployedFont!.pointSize*CGFloat(lines+1)*fontScale):CGFloat(deployedFont!.pointSize*1.1*CGFloat(lines+1)*fontScale)
                
//                qrImageRect = CGRect(x: wallpaperCenterX - qrFromCenterX*deployScaleAdj, y: wallpaperCenterY-qrFromCenterY*deployScaleAdj, width: qrDisplayW, height: qrDisplayW)
                textRect    = CGRect(x: wallpaperCenterX - textFromCenterX*deployScaleAdj, y: wallpaperCenterY-textFromCenterY*deployScaleAdj-displayTextH, width: textRect.width*deployScaleAdj, height: displayTextH)
                
//                print("\n[deployed \(deviceType)]      qrImageRect: \(qrImageRect)")
//                print("[deployed \(deviceType)]         textRect: \(textRect)")
//                print("[deployed \(deviceType)]  backgroundImage: \(backgroundImage.size)")
//                print("[deployed \(deviceType)] wallpaperCenterX: \(wallpaperCenterX)")
//                print("[deployed \(deviceType)] wallpaperCenterY: \(wallpaperCenterY)")
//                print("[deployed \(deviceType)]    qrFromCenterx: \(qrFromCenterX)")
//                print("[deployed \(deviceType)]    qrFromCenterY: \(qrFromCenterY)")
//                print("[deployed \(deviceType)]  textFromCenterX: \(textFromCenterX)")
//                print("[deployed \(deviceType)]  textFromCenterY: \(textFromCenterY)")
//                print("[deployed \(deviceType)]     displayTextH: \(displayTextH)")
                
                publishedImage.lockFocus()

                var publishedImageRect: CGRect = .zero

                publishedImageRect.size        = publishedImage.size
                backgroundImage.draw(in: publishedImageRect)
                
                /*
                // vertical hash marks for testing - start
                let theStride = Int(origBackground!.size.height)/40
                for i in stride(from: 1, to: Int(origBackground!.size.height), by: theStride) {
//                    let thePercent = 100.0*(1.0 - CGFloat(i)/origBackground!.size.height)
                    let deployedTextMarker  = NSMutableAttributedString(string: "--\(i)--(\(Int(100.0*CGFloat(i)/origBackground!.size.height)))--        .", attributes: textAttributes)
                    let textRectMarker      = CGRect(x: (publishedImage.size.width/2-croppedImageRep.size.width*0.4),
                                      y: CGFloat(i),
                                      width: croppedImageRep.size.width*0.8,
                                      height: CGFloat(currentFont!.pointSize*2))
                    deployedTextMarker.draw(in: textRectMarker)
                }
                // vertical hash marks for testing - end
                 
                 // horizontal hash marks for testing - start
                let markerMeployedFont   = NSFont(name: appInfo.defaultFontName!, size: deployedFont!.pointSize/3)
                let markerTextAttributes = [NSAttributedString.Key.foregroundColor: appInfo.defaultTextColor ?? NSColor.black, NSAttributedString.Key.font: markerMeployedFont!, NSAttributedString.Key.paragraphStyle: paragraphStyle]
                 let theStride = Int(origBackground!.size.width)/20
                 for i in stride(from: 1, to: Int(origBackground!.size.width), by: theStride) {
 //                    let thePercent = 100.0*(1.0 - CGFloat(i)/origBackground!.size.height)
                     let deployedTextMarker  = NSMutableAttributedString(string: "\(i)", attributes: markerTextAttributes)
                     let textRectMarker = CGRect(x: CGFloat(i),
                                       y: (publishedImage.size.width/2),
                                                 width: 80.0,
                                       height: CGFloat(deployedFont!.pointSize*2))
                     deployedTextMarker.draw(in: textRectMarker)
                 }
                 // horizontal hash marks for testing - end
                */
                
                if AppInfo.overlay! < 2 {
                    deployedText.draw(in: textRect)
                }
                if AppInfo.overlay == 0 || AppInfo.overlay == 2 {
                    let qrCodeDeployWidth = qrImageRect.size.width*deployScaleAdj
                    generateQRCode(from: identifierText, scale: deployScaleAdj, purpose: "deploy")
                    print("qrCodeDeployWidth: \(qrCodeDeployWidth), qrCodeImageDeployed width: \(qrCodeImageDeployed!.size.width)")
                    qrImageRect = CGRect(x: wallpaperCenterX - qrFromCenterX*deployScaleAdj, y: wallpaperCenterY-qrFromCenterY*deployScaleAdj, width: qrImageRect.size.width*deployScaleAdj, height: qrImageRect.size.width*deployScaleAdj)
                    print(" qrImageRect size: \(qrImageRect.size)")
                    qrCodeImageDeployed!.draw(in: qrImageRect)
//                    print("qrCodeImageDeployed: \(qrCodeImageDeployed!.size)")
//                    qrCodeOverlay.draw(in: qrImageRect)
                }
                
                publishedImage.unlockFocus()
                let tmp_ciImage           = ciImage(theImage: publishedImage)!
                let tmp_imageRep          = NSCIImageRep(ciImage: tmp_ciImage)
                let deployedPixelW        = Double(tmp_imageRep.pixelsWide)
                let deployScale           = min(deployedPixelW/origBkgndPixelW, origBkgndPixelW/deployedPixelW)
                print("deployScale: \(deployScale)")
                let tmp_deployedWallpaper = scaleFilter(input: tmp_ciImage, aspectRatio: 1.0, scale: deployScale)
                let rep                   = NSCIImageRep(ciImage: tmp_deployedWallpaper)
                let deployedWallpaper     = NSImage(size: rep.size)
                deployedWallpaper.addRepresentation(rep)
                
                
                
                wallpaperToPublish = deployedWallpaper  // resize back to original
//                wallpaperToPublish = publishedImage   // size not adjusted - image gets larger
//                wallpaperToPublish = backgroundImage  // post original background - image size stays the same
            }
            // for deployment - end
        }
    }

    @IBAction func setBackground_action(_ sender: Any) {
        startTime = Date()
        
        setBackground_button.isEnabled = false
        AppInfo.stopUpdates            = false
        stopMsgDisplayed               = false
        stop_button.isHidden           = false

        switch selectScope_button.title {
        case "Group":
            scopeArray = ["test"]
        case "One Device":
            scopeArray = scopeValue_textfield.stringValue.components(separatedBy: ",")
            for i in 0..<scopeArray.count {
                scopeArray[i] = scopeArray[i].replacingOccurrences(of: " ", with: "").uppercased()
            }
        default:
            scopeArray.removeAll()
        }
        
        if currentProgress_indicator.isHidden {
//            print("start progress indicator")
            currentProgress_indicator.isIndeterminate = true
            currentProgress_indicator.startAnimation(self)
            currentProgress_indicator.isHidden = false
        }
        
        TokenDelegate.shared.getToken(serverUrl: JamfProServer.destination, whichServer: "source", base64creds: JamfProServer.base64Creds) { [self]
            (result: (Int,String)) in
            let (_,passFail) = result
            usleep(10000)
            if passFail == "success" {
//                print("authenticated, continue")
                var deviceBySerial = [String:[String:Any]]()
                var mobiledevices = [[String:Any]]()
                var apiEndpoint = "mobiledevices"
                var groupTag    = "mobile_devices"
                var nameTag     = "device_name"
                
                successCount    = 0
                failCount       = 0
//                print("allDevices: \(allDevices)")
                for device in allDevices {
                    if let deviceSerial = device["serial_number"] as? String {
                        deviceBySerial[deviceSerial] = device
                    }
                }
                
                if selectScope_button.title == "Group" {
                    if let _ = endpointNameId["\(scopeValue_textfield.stringValue.lowercased())"] {
                        apiEndpoint = "mobiledevicegroups/id/\(String(describing: endpointNameId["\(scopeValue_textfield.stringValue.lowercased())"]!))"
                        groupTag = "mobile_device_group"
                        nameTag  = "name"
                    } else {
//                        print("group name not found")
                        switch scopeValue_textfield.stringValue.lowercased() {
                        case "":
                            _ = Alert.shared.display(header: "Attention", message: "Group name cannot be blank")
                        default:
                            _ = Alert.shared.display(header: "Attention", message: "Group '\(scopeValue_textfield.stringValue)' was not found")
                        }
                        return
                    }
                } else if selectScope_button.title == "One Device" && "\(scopeValue_textfield.stringValue.lowercased())" == "" {
                    _ = Alert.shared.display(header: "Attention", message: "Device serial number cannot be blank")
                    return
                }
                
                JamfPro.shared.jsonAction(theServer: JamfProServer.destination, theEndpoint: apiEndpoint, theMethod: "GET", retryCount: 0) { [self]
                    (result: ([String:AnyObject],Int)) in
                    let (jsonResults,_) = result
//                    print("mobiledevices: \(jsonResults)")
                    var additionalMessage = "devices"
                    switch selectScope_button.title {
                    case "Group":
                        if let _ = jsonResults[groupTag] as? [String:Any] {
                            let mobiledevicegroup = jsonResults[groupTag] as! [String : Any]
                            mobiledevices = mobiledevicegroup["mobile_devices"] as! [[String : Any]]
                            additionalMessage = "devices in group \(scopeValue_textfield.stringValue)"
                        }
                    case "One Device":
                        for oneDevice in allObjects {
                            if let deviceSerial = oneDevice["serial_number"] as? String {
                                if (scopeArray.firstIndex(of: deviceSerial.uppercased()) != nil) {
                                    mobiledevices.append(oneDevice)
                                }
                            }
                        }
                        additionalMessage = "selected device(s): \(scopeValue_textfield.stringValue)"
                    default:
                        if let _ = jsonResults[groupTag] as? [[String:Any]] {
                            mobiledevices = jsonResults[groupTag] as! [[String : Any]]
                            additionalMessage = "total devices"
                        }
                    }
                    progressScale = 100.0/Double(mobiledevices.count)
                    currentProgress_indicator.increment(by: -100.0)

//                    print("mobiledevices: \(mobiledevices)")
                    WriteToLog.shared.message(theMessage: "Found \(mobiledevices.count) \(additionalMessage)")
                    if mobiledevices.count == 0 {
                        _ = Alert.shared.display(header: "No devices found", message: "")
                        currentProgress_indicator.stopAnimation(self)
                        currentProgress_indicator.isHidden = true
                        setBackground_button.isEnabled     = true
                        stop_button.isHidden               = true
                        return
                    }
                    
                    var threadNumber = 0
                    commandsComplete = 0
                    let response = Alert.shared.display(header: "", message: "You are about to set the wallpaper on \n\(mobiledevices.count) device\(mobiledevices.count == 1 ? "":"s").", firstButton: "Continue", secondButton: "Cancel")
                    if response == "Continue" {
                        while threadNumber < JamfProServer.maxThreads && threadNumber < mobiledevices.count {
                            buildAndDeploy(mobiledevices: mobiledevices, deviceBySerial: deviceBySerial, nameTag: nameTag, count: threadNumber)
                            threadNumber += 1
                        }
                    } else {
                        currentProgress_indicator.stopAnimation(self)
                        currentProgress_indicator.isHidden = true
                        setBackground_button.isEnabled     = true
                        stop_button.isHidden               = true
                        _ = Alert.shared.display(header: "", message: "Process cancelled")
                        return
                    }
                }
            } else {
                
            }
        }
    }   // func setBackground_action - end
    
    func buildAndDeploy(mobiledevices: [[String:Any]], deviceBySerial: [String:[String:Any]], nameTag: String, count: Int) {
        if AppInfo.stopUpdates {
            if !stopMsgDisplayed {
                _ = Alert.shared.display(header: "Wallpaper process has stopped after \(count-1) updates", message: "")
                currentProgress_indicator.isHidden = true
                stop_button.isHidden               = true
                stop_button.isEnabled              = true
                setBackground_button.isEnabled     = true
            }
            stopMsgDisplayed = true
            return
        }
        
        let formatter        = DateFormatter()
        formatter.dateFormat = "yMMd_HHmm"
        // used for file export - currently disabled
//        let today            = NSDate()
//        let timeDate2        = formatter.string(from: today as Date)
        
        var rate       = 0.0
        var xml        = ""
        var deviceType = ""
        let theDevice  = mobiledevices[count]
//        print("the device: \(theDevice)")
        if let deviceId = theDevice["id"] as? Int, let deviceName = theDevice[nameTag] as? String, let deviceSerial = theDevice["serial_number"] as? String {
            
            let deviceModel  = deviceBySerial[deviceSerial]?["model"] as? String ?? "iPad"
            print("deviceSerial: \(deviceSerial) \t deviceId: \(deviceId) \t deviceName: \(deviceName) \t deviceModel: \(deviceModel)")

            if (deviceModel.localizedCaseInsensitiveContains("iPad")) {
                deviceType = "iPad"
            } else if (deviceModel.localizedCaseInsensitiveContains("iPhone")) {
                deviceType = "iPhone"
            } else if (deviceModel.localizedCaseInsensitiveContains("iPod")) {
                deviceType = "iPod"
            } else if (deviceModel.localizedCaseInsensitiveContains("Apple TV")) {
                deviceType = "Apple TV"
            }
            let supervised   = deviceBySerial[deviceSerial]?["supervised"] as? Int ?? 0
            let isSupervised = (supervised == 1) ? true:false
            if qrCodeType_button.titleOfSelectedItem == "Serial Number" {
                identifierText = deviceSerial
            } else {
                identifierText = identifierText.replacingOccurrences(of: "$SERIALNUMBER", with: deviceSerial)
                identifierText = identifierText.replacingOccurrences(of: "$JSSID", with: "\(deviceId)")
            }
            
            var deviceLookup  = 1
            
            if (scopeArray.firstIndex(of: deviceSerial.uppercased()) != nil || currentScope != "One Device") {
//                                    print("update device \(deviceName)")
                if !isSupervised && deviceType != "Apple TV" {
                    deviceLookup = -1
                }
                JamfPro.shared.jsonAction(theServer: JamfProServer.destination, theEndpoint: "mobiledevices/id/\(deviceId)", theMethod: "GET", retryCount: deviceLookup) { [self]
                    (result: ([String:AnyObject],Int)) in
                    let (mobileDeviceRecord,_) = result
                    
                    if isSupervised && deviceType != "Apple TV" {
                        let json = mobileDeviceRecord["mobile_device"] as? [String:Any] ?? [:]
//                        print("json for \(deviceSerial): \(json)")
                        if json.count > 0 {
                            let general  = json["general"] as? [String:Any] ?? [:]
                            let siteInfo = general["site"] as? [String:Any] ?? ["id": 0, "name": ""]
                            let location = json["location"] as? [String:Any] ?? [:]

                            self.deviceInfo["devicename"]     = general["name"] as? String ?? ""
                            self.deviceInfo["serialnumber"]   = general["serial_number"] as? String ?? ""
                            self.deviceInfo["sitename"]       = siteInfo["name"] as? String ?? ""
                            self.deviceInfo["asset_tag"]      = general["asset_tag"] as? String ?? ""
                            self.deviceInfo["room"]           = location["room"] as? String ?? ""
                            self.deviceInfo["buildingname"]   = location["building"] as? String ?? ""
                            self.deviceInfo["departmentname"] = location["department"] as? String ?? ""
                        }
//                        print("serial for \(deviceSerial): \(self.deviceInfo["serial_number"]!)")
                        
                        setPreviewButton(deviceType: deviceType)
//                        print("deviceType: \(deviceType), deployScaleAdj: \(deployScaleAdj)")
//                        let qrCodeDeployAdj = (deployScaleAdj == 1.0) ? 1.0:qrCodeImage!.size.width*deployScaleAdj/abs(qrCodeImage!.size.width*deployScaleAdj-qrCodeImage!.size.width)
                        print("deviceType: \(deviceType), deployScaleAdj: \(deployScaleAdj)")

                        preview_action(deviceType: deviceType, deviceInfo: deviceInfo, action: "deploy")

                        let encodedImage = wallpaperToPublish?.base64String
                        // 1 (Lock screen), 2 (Home screen), or 3 (Lock and home screens)
//                        print("appInfo.targetScreen: \(appInfo.targetScreen!)")
                        
                        xml = """
    <?xml version="1.0" encoding="UTF-8" standalone=\"no\"?><mobile_device_command><general><command>Wallpaper</command><wallpaper_setting>\(AppInfo.targetScreen!)</wallpaper_setting><wallpaper_content>\(encodedImage!)</wallpaper_content></general><mobile_devices><mobile_device><id>\(deviceId)</id></mobile_device></mobile_devices></mobile_device_command>
    """
                        WriteToLog.shared.message(theMessage: "Generating wallpaper for \(deviceType) \(deviceName) (SN: \(deviceSerial))")
    //                    print("xml for \(deviceType): \(xml)")
                    } else {
                        xml = ""
//                        jpapiMethod = "SKIP"
                    }
                    
                    /*
                    // save wallpaper - start
                    if !FileManager().fileExists(atPath: "/Users/Shared/wallpapers/") {
                        do {
                            try FileManager().createDirectory(at: URL(string: "/Users/Shared/wallpapers/")!, withIntermediateDirectories: true)
                        } catch {
                            WriteToLog.shared.message(theMessage: "failed to create /Users/Shared/wallpaper/")
                        }
                    }
                    let imageRep = NSBitmapImageRep(data: wallpaperToPublish!.tiffRepresentation!)
                    let pngData = imageRep?.representation(using: .png, properties: [:])
                    var wallpaperFile = "/Users/Shared/wallpapers/Wallpaper-\(deviceType)_\(timeDate2).png"
                    var i = 1
                    do {
                        while FileManager().fileExists(atPath: wallpaperFile) {
                            wallpaperFile = "/Users/Shared/wallpapers/Wallpaper-\(deviceType)_\(timeDate2)_\(i).png"
                            i += 1
                        }
                        try pngData!.write(to: URL(fileURLWithPath: wallpaperFile))

                    } catch {
                        WriteToLog.shared.message(theMessage: "failed to save wallpaper")
                        print(error)
                    }
                    // save wallpaper - end
                    */
                    
                    JamfPro.shared.xmlAction(theServer: JamfProServer.destination, theEndpoint: "mobiledevicecommands/command/Wallpaper", theMethod: "POST", theData: xml, skip: !isSupervised) { [self]
                        (result: [Int:String]) in
                        commandsComplete += 1
                        usleep(10000)
                        currentProgress_indicator.isIndeterminate = false
//                            for (returnedCode,returnedMessage) in result {
                        for (returnedCode,returnedMessage) in result {
                            if returnedMessage == "success" {
                                if isSupervised {
                                    successCount += 1
                                    WriteToLog.shared.message(theMessage: "\(deviceType) \(deviceName) (SN: \(deviceSerial)) was successfully sent the wallpaper")
                                    // update Wallpaper Applied extension attribute
                                    let ea_xml = """
    <?xml version="1.0" encoding="UTF-8" standalone=\"no\"?><mobile_device>
    <extension_attributes><extension_attribute>
    <name>Wallpaper Applied</name>
    <type>Date</type>
    <multi_value>false</multi_value>
    <value>\(deployDateTime)</value>
    </extension_attribute></extension_attributes></mobile_device>
    """
                                    JamfPro.shared.xmlAction(theServer: JamfProServer.destination, theEndpoint: "mobiledevices/id/\(deviceId)", theMethod: "PUT", theData: ea_xml, skip: !isSupervised) {
                                        (result: [Int:String]) in
                                        for (_,returnedMessage) in result {
                                            if returnedMessage == "success" {
                                                WriteToLog.shared.message(theMessage: "\(deviceType) \(deviceName) (SN: \(deviceSerial)) Wallpaper Applied extentsion attribute was updated")
                                            } else {
                                                WriteToLog.shared.message(theMessage: "\(deviceType) \(deviceName) (SN: \(deviceSerial)) Wallpaper Applied extentsion attribute was not updated")
                                            }
                                        }
                                    }
                                } else {
                                    failCount += 1
                                    WriteToLog.shared.message(theMessage: "\(deviceType) \(deviceName) (SN: \(deviceSerial)) is not supervised and was was not sent the wallpaper")
                                }
                            } else {
                                failCount += 1
                                WriteToLog.shared.message(theMessage: "\(deviceType) \(deviceName) (SN: \(deviceSerial)) was was not sent the wallpaper")
                                WriteToLog.shared.message(theMessage: "http status code: \(returnedCode)")
                                if returnedCode == 413 {
                                    _ = Alert.shared.display(header: "File size is too large, reduce and retry.", message: "")
                                    commandsComplete = mobiledevices.count
                                } else {
                                    WriteToLog.shared.message(theMessage: "             xml: \(xml)")
                                }
                            }
                        }
                        currentProgress_indicator.increment(by: progressScale)
                        if commandsComplete == mobiledevices.count {
                            endTime = Date()
                            let components = Calendar.current.dateComponents([.second], from: startTime!, to: endTime!)
                            let timeDifference = Int(components.second!)
                            let (h,r) = timeDifference.quotientAndRemainder(dividingBy: 3600)
                            let (m,s) = r.quotientAndRemainder(dividingBy: 60)
                            
                            WriteToLog.shared.message(theMessage: "Run time: \(dd(value: h)):\(dd(value: m)):\(dd(value: s)) (h:m:s)")
                            if h > 0 {
                                rate = Double(commandsComplete)/(Double(h)+Double(m)/60.0+Double(s)/3600.0)
                                WriteToLog.shared.message(theMessage: "Averaged sending \(String(format: "%.1f", rate)) commands per hour")
                            } else if m > 0 {
                                rate = Double(commandsComplete)/(Double(m)+Double(s)/60.0)
                                WriteToLog.shared.message(theMessage: "Averaged sending \(String(format: "%.1f", rate)) commands per minute")
                            } else if s > 0 {
                                rate = Double(commandsComplete)/Double(s)
                                WriteToLog.shared.message(theMessage: "Averaged sending \(String(format: "%.1f", rate)) commands per second")
                            }
                            
                            var resultMessage = ""
                            if successCount > 0 {
                                let plural = (successCount > 1) ? "devices were":"device was"
                                resultMessage = "\(successCount) \(plural) successfully sent the new wallpaper.\n"
                            }
                            if failCount > 0 {
                                let plural = (failCount > 1) ? "devices were":"device was"
                                resultMessage = "\(resultMessage)\(failCount) \(plural) not sent the new wallpaper.\n"
                            }
                            
                            preview_action(deviceType: AppInfo.currentPreviewType, deviceInfo: [:], action: "preview")
                            
                            _ = Alert.shared.display(header: "Results", message: "\(resultMessage)")
                            currentProgress_indicator.isHidden = true
                            stop_button.isHidden               = true
                            setBackground_button.isEnabled     = true
                        } else {
                            if count+JamfProServer.maxThreads < mobiledevices.count {
                                buildAndDeploy(mobiledevices: mobiledevices, deviceBySerial: deviceBySerial, nameTag: nameTag, count: count+JamfProServer.maxThreads)
                            }
                        }
                    }
                }
            }
        }
    }
     
    func ciImage(theImage: NSImage) -> CIImage? {
        guard let data = theImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: data) else {
            return nil
        }
        let ci = CIImage(bitmapImageRep: bitmap)
        return ci
    }
    
    // Delegate Method
    func sendLoginComplete() {
//        let jamfUtf8Creds = "\(JamfProServer.username):\(JamfProServer.password)".data(using: String.Encoding.utf8)
//        JamfProServer.base64Creds = (jamfUtf8Creds?.base64EncodedString())!
        
        currentProgress_indicator.isIndeterminate = true
        currentProgress_indicator.isHidden = true
        
        connectedTo_label.stringValue = "Connected to: \(JamfProServer.displayName)"
        connectedTo_label.toolTip = "\(JamfProServer.destination)"
        selectScope_button.isEnabled = true
    }
    
    func sendTextFormat(textFormat: (String, Float, NSColor, Bool, Bool, Bool)) {
        (AppInfo.defaultFontName, AppInfo.defaultFontSize, AppInfo.defaultTextColor, textIsBold, textIsItalic, textIsUnderlined) = textFormat
        preview_action(deviceType: AppInfo.currentPreviewType, deviceInfo: [:], action: "preview")
    }
    
    func sendQrCodeString(textString: String, update: Bool) {
        if update {
            print("[sendString] qr code text: \(textString)")
            qrCodeType_button.toolTip = textString
            identifierText = textString
            defaults.set(textString, forKey: "qrCodeText")
        } else {
            print("[sendString] no change to qr code text")
        }
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if segue.identifier == "loginView" {
            let loginVC: LoginVC = segue.destinationController as! LoginVC
            loginVC.delegate = self
        } else if segue.identifier == "textFormat" {
            let textFormatVC: TextFormatVC = segue.destinationController as! TextFormatVC
            textFormatVC.delegate = self
        } else if segue.identifier == "qrCodeType" {
            let qrCodeTypeVC: QRCodeTypeVC = segue.destinationController as! QRCodeTypeVC
            qrCodeTypeVC.delegate = self
        }
    }
    
    
    override func mouseDown(with event: NSEvent) {
        guard let _ = finishedBackground?.size else {
            return
        }
        let mouseLocation = event.locationInWindow
//        print("\nstart location: \(mouseLocation)")
        startX    = mouseLocation.x
        startY    = mouseLocation.y
        let deviceOffsetX = (AppInfo.currentPreviewType == "iPad") ? 66.0:154.0
        let deviceOffsetY = (AppInfo.currentPreviewType == "iPad") ? 76.0:108.0
        
        startQRCodeX = qrImageRect.minX
        startQRCodeY = qrImageRect.minY
        startTextX   = textRect.minX
        startTextY   = textRect.minY

        bivX      = backgroundImage_imageview.frame.minX    //+deviceOffset
        bivY      = backgroundImage_imageview.frame.minY+31.0
        
        var shadowW = 0.0
        var shadowH = 0.0
        let minX = (previewFrame_imageview.frame.width - finishedBackground!.size.width)/2 + 30.0
//        print(" qrX: \(startQRCodeX)")
//        print("minX: \(minX)")
        
        if (startX-deviceOffsetX > startQRCodeX && startX-deviceOffsetX < qrImageRect.maxX) && (startY-deviceOffsetY > startQRCodeY && startY-deviceOffsetY < qrImageRect.maxY) {
            objectToMove = "qrCode"
            positionOffsetX = startX - (startQRCodeX+minX)
            positionOffsetY = startY - (startQRCodeY+bivY)
            
            shadowW = qrImageRect.width+5
            shadowH = shadowW
            dragShadow_button.image = qrCodeImage
        } else if (startX-deviceOffsetX > startTextX && startX-deviceOffsetX < textRect.maxX) && (startY-deviceOffsetY > startTextY && startY-deviceOffsetY < textRect.maxY) {
            objectToMove = "text"
            positionOffsetX = startX - (startTextX+minX)
            positionOffsetY = startY - (startTextY+bivY)
            
            shadowW = textRect.width
            shadowH = textRect.height
            dragShadow_button.image = textImage
        }
        var constraints = [NSLayoutConstraint]()
        if objectToMove != "" {
            let currentConstraints = dragShadow_button.constraints
            dragShadow_button.removeConstraints(currentConstraints)
//            print("move \(objectToMove)")
            
            constraints = [
                dragShadow_button.widthAnchor.constraint(equalToConstant: shadowW),
                dragShadow_button.heightAnchor.constraint(equalToConstant: shadowH)
                ]
            NSLayoutConstraint.activate(constraints)
            if objectToMove == "qrCode" {
                dragShadow_button.frame = CGRect(x: startQRCodeX+deviceOffsetX-3.0, y: startQRCodeY+deviceOffsetY-0.5, width: shadowW, height: shadowH)
            } else {
                dragShadow_button.frame = CGRect(x: startTextX+deviceOffsetX-3.0, y: startTextY+deviceOffsetY-0.5, width: shadowW, height: shadowH)
            }
//            dragShadow_button.frame = CGRect(x: (shadowX+minX), y: (shadowY+bivY), width: shadowW, height: shadowH)
            
            dragShadow_button.layer?.backgroundColor = NSColor.systemGray.cgColor
            dragShadow_button.alphaValue = 0.5
            dragShadow_button.updateLayer()
            dragShadow_button.isHidden = false
        }
    }
    
    override func mouseDragged(with event: NSEvent) {
        guard let _ = newImage?.size.height else {
            return
        }
        
        let mouseLocation  = event.locationInWindow
        let deviceOffsetX = (AppInfo.currentPreviewType == "iPad") ? 66.0:154.0
        let deviceOffsetY = (AppInfo.currentPreviewType == "iPad") ? 76.0:108.0

        if !withShiftKey {
            if abs(257-mouseLocation.x) < newImage!.size.width/2.0 {
                dx = mouseLocation.x - startX
            }
        } else {
            if objectToMove == "qrCode" {
                dx = 257 - deviceOffsetX - startQRCodeX - qrImageRect.width/2.0
            } else {
                dx = 257 - deviceOffsetX - startTextX - textRect.width/2.0
            }
        }
        if abs(333.5-mouseLocation.y) < newImage!.size.height/2.0 {
            dy = mouseLocation.y - startY
        }
            switch objectToMove {
            case "qrCode":
                dragShadow_button.alphaValue = 0.75
                dragShadow_button.frame = CGRect(x: (startQRCodeX+deviceOffsetX-3.0)+dx, y: (startQRCodeY+deviceOffsetY-0.5)+dy, width: qrImageRect.width, height: qrImageRect.height)
                dragShadow_button.updateLayer()
            case "text":
                dragShadow_button.alphaValue = 0.75
                dragShadow_button.frame = CGRect(x: (startTextX+deviceOffsetX-3.0)+dx, y: (startTextY+deviceOffsetY-0.5)+dy, width: qrImageRect.width, height: qrImageRect.height)
                dragShadow_button.updateLayer()
            default:
                break
            }
    }
    override func mouseUp(with event: NSEvent) {
        
//        objectToMove = "qrCode"
//            dx = 150
        
        if objectToMove != "" {
            dragShadow_button.isHidden = true
//            let mouseLocation = event.locationInWindow
//            dx = mouseLocation.x - startX
//            dy = mouseLocation.y - startY
            if dx+dy != 0 {
//                print("change: (\(dx), \(dy))")
                switch AppInfo.currentPreviewType {
                case "iPad":
                    dx = (objectToMove == "qrCode") ? dx+1.0:dx-1.5
                    dy = (objectToMove == "qrCode") ? dy+0.25:dy-1.5
                default:
                    dx = (objectToMove == "qrCode") ? dx+1.0:dx-1.5
                    dy = (objectToMove == "qrCode") ? dy+0.25:dy-1.5
                }
                preview_action(deviceType: AppInfo.currentPreviewType, deviceInfo: [:], action: "dragged-\(objectToMove)")
            }
        }
        objectToMove = ""
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        didRun = true
        //create log file
        Log.file = getCurrentTime().replacingOccurrences(of: ":", with: "") + "_" + Log.file
        if !(FileManager.default.fileExists(atPath: Log.path! + Log.file)) {
            FileManager.default.createFile(atPath: Log.path! + Log.file, contents: nil, attributes: nil)
        }
        cleanup()
        WriteToLog.shared.message(theMessage: "[ViewController] Running \(AppInfo.displayName) v\(AppInfo.version)")

        if let bookmarkData = UserDefaults.standard.object(forKey: "bookmark") as? Data {
            do {
                var bookmarkIsStale = false
                let url = try URL.init(resolvingBookmarkData: bookmarkData as Data, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &bookmarkIsStale)
                let _ = url.startAccessingSecurityScopedResource()
                WriteToLog.shared.message(theMessage: "[viewDidLoad] Bookmark Access Succeeded")
            } catch let error as NSError {
                WriteToLog.shared.message(theMessage: "[viewDidLoad] Bookmark Access Fails: \(error.description)")
            }
        }
        
        if NSFontPanel.sharedFontPanelExists {
            NSFontPanel.shared.close()
        }
        if NSColorPanel.sharedColorPanelExists {
            NSColorPanel.shared.orderOut(self)
        }
        stop_button.bezelColor = .red

        // Do any additional setup after loading the view.
        
        for theWallpaper in iPadWallpapers {
            iPadWallpaper_menuItem.submenu?.addItem(NSMenuItem(title: theWallpaper.name()!, action: #selector(updateWallpaper(_:)), keyEquivalent: ""))
        }
        for theWallpaper in iPhoneWallpapers {
            iPhoneWallpaper_menuItem.submenu?.addItem(NSMenuItem(title: theWallpaper.name()!, action: #selector(updateWallpaper(_:)), keyEquivalent: ""))
        }
        
        currentProgress_indicator.isHidden = true
        let paragraphStyle         = NSMutableParagraphStyle()
        paragraphStyle.alignment   = .center
        addText_textview.font      = .systemFont(ofSize: 16.0)
        addText_textview.defaultParagraphStyle = paragraphStyle
        
        self.addText_textview.delegate     = self
        self.scopeValue_textfield.delegate = self
        scopeMatches_tableview.delegate    = self
        scopeMatches_tableview.dataSource  = self
        scopeMatches_tableview.target      = self
        scopeMatches_tableview.doubleAction = #selector(selectObject)
        newImage?.delegate                  = self
        
        scopeMatches_tableview.usesAlternatingRowBackgroundColors = true
//        scopeMatches_tableview.layer?.borderWidth = 1
        
        identifierText = getMacSerialNumber()
        AppInfo.defaultBackgroundIsColor = defaults.bool(forKey: "defaultBackgroundIsColor")
        print("AppInfo.defaultBackgroundIsColor: \(AppInfo.defaultBackgroundIsColor)")

        if AppInfo.defaultBackgroundIsColor {
            guard let previousColor = defaults.data(forKey: "defaultBackgroundColor") else {
                return
            }
            do {
                let previousBackgroundColor =  try NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: previousColor)
                if AppInfo.currentPreviewType == "iPhone" {
                    backgroundImage = NSImage(color: previousBackgroundColor!, size: NSSize(width: 390, height: 844))
                } else {
                    backgroundImage = NSImage(color: previousBackgroundColor!, size: NSSize(width: 768, height: 1024))
                }
                print("AppInfo.currentPreviewType: \(AppInfo.currentPreviewType)")
                print("background width: \(backgroundImage.size.width), height: \(backgroundImage.size.height)")
                backgroundImage_imageview.image = backgroundImage
                AppInfo.defaultBackgroundColor = previousBackgroundColor
            } catch {
                print("failed to retrieve color")
            }
        } else {
            AppInfo.defaultBackgroundImageURL = defaults.string(forKey: "defaultBackgroundImageURL") ?? ""
        
            if FileManager().isReadableFile(atPath: AppInfo.defaultBackgroundImageURL) {
                let previousImageURL = "file://"+AppInfo.defaultBackgroundImageURL.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!
                backgroundImage = NSImage(contentsOf: URL(string: previousImageURL)!)!

                backgroundImage_imageview.image = backgroundImage
            } else {
                // using template image
                if let _ = NSImage(named: AppInfo.defaultBackgroundImageURL) {
                    backgroundImage = NSImage(named: AppInfo.defaultBackgroundImageURL)!
                    backgroundImage_imageview.image = backgroundImage
                }
            }
        }
        
        origBackgroundW = (backgroundImage.size.width)
        origBackgroundH = (backgroundImage.size.height)
        
        AppInfo.currentPreviewType = defaults.string(forKey: "currentPreviewType") ?? "iPad"
        setPreviewButton(deviceType: AppInfo.currentPreviewType)
        AppInfo.defaultText = defaults.string(forKey: "defaultText") ?? ""
        AppInfo.defaultFontName = defaults.string(forKey: "defaultFontName") ?? "HelveticaNeue"
        if NSFontManager.shared.availableFonts.firstIndex(of: AppInfo.defaultFontName!) == nil {
            AppInfo.defaultFontName = "HelveticaNeue"
        }
        AppInfo.textPosition   = defaults.integer(forKey: "textPosition")
        
        let textVertPosDict    = defaults.object(forKey: "textVertPos") as? [String:Int] ?? ["iPad":30, "iPhone":30]
        let textHorizPosDict   = defaults.object(forKey: "textHorizPos") as? [String:Int] ?? ["iPad":50, "iPhone":50]
        
        AppInfo.qrCodeSize     = defaults.double(forKey: "qrCodeSize")
        if AppInfo.qrCodeSize < 1 {
            AppInfo.qrCodeSize = 3.0
        }
        qrCodeType = defaults.string(forKey: "qrCodeType") ?? "Serial Number"
        qrCodeType_button.selectItem(withTitle: qrCodeType)
        if qrCodeType == "Custom Text" {
            identifierText = defaults.string(forKey: "qrCodeText") ?? ""
            qrCodeStringEdit_button.isHidden = false
            qrCodeType_button.toolTip = identifierText
        } else {
            qrCodeStringEdit_button.isHidden = true
        }
        let qrCodeVertPosDict  = defaults.object(forKey: "qrCodeVertPos") as? [String:Int] ?? ["iPad":30, "iPhone":30]
        let qrCodeHorizPosDict = defaults.object(forKey: "qrCodeHorizPos") as? [String:Int] ?? ["iPad":50, "iPhone":50]
        for device in ["iPad", "iPhone"] {
            AppInfo.qrCodeVertPos[device]  = qrCodeVertPosDict[device]
            AppInfo.qrCodeHorizPos[device] = qrCodeHorizPosDict[device]
            AppInfo.textVertPos[device]    = textVertPosDict[device]
            AppInfo.textHorizPos[device]   = textHorizPosDict[device]
        }
        
        if let savedRect = defaults.object(forKey: "iPadQRCodeRect") as? Data {
            do {
                AppInfo.iPadQRCodeRect = try decoder.decode(ObjectRect.self, from: savedRect)
            } catch {
                AppInfo.iPadQRCodeRect = ObjectRect(minX: 0.0, minY: 0.0, objectW: 40.0, objectH: 40.0)
                WriteToLog.shared.message(theMessage: "QR Code position for iPad preview could not be decoded")
            }
        } else {
            AppInfo.iPadQRCodeRect = ObjectRect(minX: 0.0, minY: 0.0, objectW: 40.0, objectH: 40.0)
            WriteToLog.shared.message(theMessage: "No stored QR Code position found for iPad preview")
        }
        if let savedRect = defaults.object(forKey: "iPadTextRect") as? Data {
            do {
                AppInfo.iPadTextRect = try decoder.decode(ObjectRect.self, from: savedRect)
            } catch {
                AppInfo.iPadTextRect = ObjectRect(minX: 0.0, minY: 0.0, objectW: 0.0, objectH: 0.0)
                WriteToLog.shared.message(theMessage: "Text position for iPad preview could not be decoded")
            }
        } else {
            AppInfo.iPadTextRect = ObjectRect(minX: 0.0, minY: 0.0, objectW: 0.0, objectH: 0.0)
            WriteToLog.shared.message(theMessage: "No stored text position found for iPad preview")
        }
        if let savedRect = defaults.object(forKey: "iPhoneQRCodeRect") as? Data {
            do {
                AppInfo.iPhoneQRCodeRect = try decoder.decode(ObjectRect.self, from: savedRect)
            } catch {
                AppInfo.iPhoneQRCodeRect = ObjectRect(minX: 0.0, minY: 0.0, objectW: 0.0, objectH: 0.0)
                WriteToLog.shared.message(theMessage: "QR Code position for iPhone preview could not be decoded")
            }
        } else {
            AppInfo.iPhoneQRCodeRect = ObjectRect(minX: 0.0, minY: 0.0, objectW: 0.0, objectH: 0.0)
            WriteToLog.shared.message(theMessage: "No stored QR Code position found for iPhone preview")
        }
        if let savedRect = defaults.object(forKey: "iPhoneTextRect") as? Data {
            do {
                AppInfo.iPhoneTextRect = try decoder.decode(ObjectRect.self, from: savedRect)
            } catch {
                AppInfo.iPhoneTextRect = ObjectRect(minX: 0.0, minY: 0.0, objectW: 0.0, objectH: 0.0)
                WriteToLog.shared.message(theMessage: "Text position for iPhone preview could not be decoded")
            }
        } else {
            AppInfo.iPhoneTextRect = ObjectRect(minX: 0.0, minY: 0.0, objectW: 0.0, objectH: 0.0)
            WriteToLog.shared.message(theMessage: "No stored text position found for iPhone preview")
        }
        
        AppInfo.overlay = defaults.integer(forKey: "overlay")
        overlay_button.selectItem(at: AppInfo.overlay ?? 0)
        AppInfo.targetScreen = (defaults.integer(forKey: "targetScreen") == 0) ? 1:defaults.integer(forKey: "targetScreen")
        target_button.selectItem(at: (AppInfo.targetScreen ?? 1)-1)
        
        // set positions
        AppInfo.justification = defaults.string(forKey: "justification") ?? "center"
        
        
        if let fontTemp = defaults.object(forKey: "defaultFontSize") {
            AppInfo.defaultFontSize = fontTemp as? Float ?? 48
        } else {
            AppInfo.defaultFontSize = 48
        }
        AppInfo.defaultTextStyle    = defaults.integer(forKey: "defaultTextStyle")
        AppInfo.defaultMenuItemFont = defaults.string(forKey: "defaultMenuItemFont") ?? "Helvetica Neue"
        
        addText_textview.string = AppInfo.defaultText!
        if AppInfo.defaultText != "" {
            AppInfo.defaultTextColor = NSColor.white
            guard let previousColor = defaults.data(forKey: "defaultTextColor") else {
                return
            }
            do {
                let previousTextColor =  try NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: previousColor)
                AppInfo.defaultTextColor = previousTextColor!
            } catch {
                print("failed to retrieve color")
            }
//            preview_action(deviceType: AppInfo.currentPreviewType, deviceInfo: [:], action: "preview")
        } else {
            AppInfo.defaultTextColor = NSColor.white
        }
        preview_action(deviceType: AppInfo.currentPreviewType, deviceInfo: [:], action: "preview")
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()

        if LoginWindow.show {
            performSegue(withIdentifier: "loginView", sender: nil)
            LoginWindow.show = false
        }
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    override func flagsChanged(with event: NSEvent) {
//            print("flagsChanged: \(event.modifierFlags.rawValue)")
        // 131330 - pressed shift key
        // 256    - released shift key
        if event.modifierFlags.contains(.shift) {
//                print("pressed shift")
            withShiftKey = true
        } else {
            withShiftKey = false
        }
    }
    
    func controlTextDidChange(_ obj: Notification) {
//        print("staticSourceDataArray: \(staticSourceDataArray)")
        if let textField = obj.object as? NSTextField {
            if textField.identifier!.rawValue == "scope" {
                let filter = scopeValue_textfield.stringValue
//                print("filter: \(filter)")
                if filter != "" {
                    allItemsArray = rawScopeArray.filter { $0.range(of: filter, options: .caseInsensitive) != nil }
                    allItemsArray = allItemsArray?.sorted()
                    self.scopeMatches_tableview.deselectAll(self)
//                    self.scopeMatches_tableview.reloadData()
//                    if rawScopeArray.count > 0 {
                    if allItemsArray?.count ?? 0 > 0 {
                        DispatchQueue.main.async { [self] in
                            scopeMatches_tableview.selectRowIndexes(.init(integer: 0), byExtendingSelection: false)
                            scopeMatches_scrollview.isHidden = false
                        }
                    } else {
                        scopeMatches_scrollview.isHidden = true
                    }
                } else {
                    self.scopeMatches_tableview.deselectAll(self)
                    allItemsArray = rawScopeArray
                }
                self.scopeMatches_tableview.reloadData()
            }   // if textField.identifier!.rawValue == "scope" - end
        }
    }
    func controlTextDidBeginEditing(_ obj: Notification) {
        if let textField = obj.object as? NSTextField {
            if textField.identifier!.rawValue == "scope" {
                scopeMatches_scrollview.isHidden = false
            }
        }
    }
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        // Do something against ENTER or TAB key
//        if (commandSelector == #selector(NSResponder.insertNewline(_:))) || (commandSelector == #selector(NSResponder.insertTab(_:))) {
        if (commandSelector == #selector(NSResponder.insertNewline(_:))) {
            // Do something against ENTER key
            if control.tag == 0 {
                if allItemsArray?.count ?? 0 > 0 {
                    if scopeMatches_tableview.numberOfSelectedRows == 0 {
                        scopeMatches_tableview.selectRowIndexes(.init(integer: 0), byExtendingSelection: false)
                    }
                    if !scopeMatches_scrollview.isHidden {
                        scopeValue_textfield.stringValue = "\(allItemsArray![scopeMatches_tableview.selectedRow])"
                        scopeMatches_scrollview.isHidden = true
                    } else {
                        setBackground_action(self)
                    }
                }
            }
            return true
        } else if (commandSelector == #selector(NSResponder.moveDown(_:))) {
            if allItemsArray?.count ?? 0 > 0 {
                let currentRow = scopeMatches_tableview.selectedRow
                let nextRow = (currentRow+1) % allItemsArray!.count
                scopeMatches_tableview.selectRowIndexes(.init(integer: nextRow), byExtendingSelection: false)
                scopeMatches_tableview.scrollRowToVisible(nextRow)
            }
        } else if (commandSelector == #selector(NSResponder.moveUp(_:))) {
            if allItemsArray?.count ?? 0 > 0 {
                let currentRow = scopeMatches_tableview.selectedRow
                let nextRow = (currentRow == 0) ? (allItemsArray!.count-1):(currentRow-1) % allItemsArray!.count
                scopeMatches_tableview.selectRowIndexes(.init(integer: nextRow), byExtendingSelection: false)
                scopeMatches_tableview.scrollRowToVisible(nextRow)
            }
        }
        
        //else if (commandSelector == #selector(NSResponder.deleteForward(_:))) {
            // Do something against DELETE key
//            return true
//        } else if (commandSelector == #selector(NSResponder.deleteBackward(_:))) {
            // Do something against BACKSPACE key
//            return true
//        } else if (commandSelector == #selector(NSResponder.cancelOperation(_:))) {
            // Do something against ESCAPE key
//            return true
//        }

        // return true if the action was handled; otherwise false
        return false
    }
    
    func textDidChange(_ notification: Notification) {
        // use textView.identifier?.rawValue to identify the textView, in case others are added
        //guard let textView = notification.object as? NSTextView else { return }
        
        AppInfo.defaultText = addText_textview.textStorage!.string
        preview_action(deviceType : AppInfo.currentPreviewType, deviceInfo: [:], action: "preview")
    }
    @objc func selectObject() {
        scopeValue_textfield.stringValue = "\(allItemsArray![scopeMatches_tableview.selectedRow])"
        scopeMatches_scrollview.isHidden = true
    }
    
    @IBAction func changeFont_action(_ sender: NSButton) {
        backgroundOrText = "textColor"
        addText_textview.usesFontPanel = true
//        if NSColorPanel.sharedColorPanelExists {
//            NSColorPanel.shared.orderOut(self)
//        }
        NSFontPanel.shared.makeKeyAndOrderFront(self)
    }
    
    @IBAction func changeColor_action(_ sender: NSButton) {
        addText_textview.usesFontPanel = false
        backgroundOrText = sender.identifier!.rawValue
        if NSFontPanel.sharedFontPanelExists {
            NSFontPanel.shared.close()
        }
        colorPanel.activate(true)
        colorPanel.window?.title = "Background Colors"
        colorPanel.action = #selector(changeObjectColor)
        AppInfo.defaultBackgroundIsColor = true
    }
    
    @objc func changeObjectColor(_ sender: Any?) {
        if backgroundOrText == "backgroundColor" {
            backgroundImage = NSImage(color: colorPanel.color, size: NSSize(width: 768, height: 1024))
            origBackgroundW = (backgroundImage.size.width)
            origBackgroundH = (backgroundImage.size.height)
            
            backgroundImage_imageview.image = backgroundImage
            AppInfo.defaultBackgroundColor  = colorPanel.color
        }

        preview_action(deviceType: AppInfo.currentPreviewType, deviceInfo: [:], action: "preview")
    }

    func getMacSerialNumber() -> String {
        var serialNumber: String? {
            let platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice") )
            
            guard platformExpert > 0 else {
                return nil
            }
            
            guard let serialNumber = (IORegistryEntryCreateCFProperty(platformExpert, kIOPlatformSerialNumberKey as CFString, kCFAllocatorDefault, 0).takeUnretainedValue() as? String)?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) else {
                return nil
            }
            
            IOObjectRelease(platformExpert)

            return serialNumber
        }
        
        return serialNumber ?? "Unknown"
    }
    func dd(value: Int) -> String {
        let formattedValue = (value < 10) ? "0\(value)":"\(value)"
        return formattedValue
    }
    
    class TableViewController: NSViewController {
        override func keyDown(with event: NSEvent) {

            if event.characters?.count == 1 {
                let character = event.keyCode
                switch (character) {
                // 36 is return
                case UInt16(36):
                    print("return: \(event)")
                default:
                    print("any other key: \(event)")
                    print("    character: \(character)")
                }
            } else {
                super.keyDown(with: event)
            }
        }
    }
}   // class ViewController - end

extension NSImage {
    var base64String: String? {
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(size.width),
            pixelsHigh: Int(size.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .calibratedRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
            ) else {
                print("Couldn't create bitmap representation")
                return nil
        }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        draw(at: NSZeroPoint, from: NSZeroRect, operation: .sourceOver, fraction: 1.0)
        NSGraphicsContext.restoreGraphicsState()

        // adjustments here didn't change image size, compresion factor goes from 0.0 (max compressio) to 1.0 (no compression)
        guard let data = rep.representation(using: NSBitmapImageRep.FileType.png, properties: [NSBitmapImageRep.PropertyKey.compressionFactor: 0.0]) else {
            print("Couldn't create PNG")
            return nil
        }

        if data.count <= 1000000 {
            print("size: \(Double(data.count)/1000.0) KB")
            WriteToLog.shared.message(theMessage: "size of deployed wallpaper: \(Double(data.count)/1000.0) KB")
        } else {
            print("size: \(Double(data.count)/1000000.0) MB")
            WriteToLog.shared.message(theMessage: "size of deployed wallpaper: \(Double(data.count)/1000000.0) KB")
        }
        return data.base64EncodedString(options: [])
    }
    
    convenience init(color: NSColor, size: NSSize) {
        self.init(size: size)
        lockFocus()
        color.drawSwatch(in: NSRect(origin: .zero, size: size))
        unlockFocus()
    }
}

extension ViewController: NSTableViewDataSource {
    func numberOfRows(in scopeMatches_tableview: NSTableView) -> Int {
//        print("[numberOfRows] \(allItemsArray?.count ?? 0)")
        return allItemsArray?.count ?? 0
    }
}

extension ViewController: NSTableViewDelegate {
    
    fileprivate enum CellIdentifiers {
        static let NameCell = "NameCell-ID"
    }
    
    func tableView(_ object_TableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        var text: String = ""
        var cellIdentifier: String = ""
    
//        print("[func tableView] item: \(unusedItems_TableArray?[row] ?? nil)")
        guard let item = allItemsArray?[row] else {
            return nil
        }
        
        
        if tableColumn == scopeMatches_tableview.tableColumns[0] {
            text = "\(item)"
            cellIdentifier = CellIdentifiers.NameCell
        }
    
        if let cell = scopeMatches_tableview.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as? NSTableCellView {
            
//            let font = NSFont(name: "HelveticaNeue", size: CGFloat(12))
//            let color = NSColor.white
//            let paragraph = NSMutableParagraphStyle()
//            paragraph.alignment = .left
//            let attribText = NSAttributedString(string: text, attributes: [NSAttributedString.Key.paragraphStyle : paragraph, NSAttributedString.Key.font : font!, NSAttributedString.Key.foregroundColor : color])
//            cell.textField?.attributedStringValue = attribText
            
            cell.textField?.stringValue = text
            cell.toolTip = serialToName[text]
            return cell
        }
        return nil
    }
    
//    func tableViewSelectionDidChange(_ notification: Notification) {
//        print("selection did change (to): \(scopeMatches_tableview.selectedRow)")
//        print("available objedts: \(allItemsArray)")
//        if scopeMatches_tableview.selectedRow >= 0 {
//            scopeValue_textfield.stringValue = "\(allItemsArray![scopeMatches_tableview.selectedRow])"
//        }
//    }
}

extension String {
    var baseUrl: String {
        get {
            var fqdn = ""
            let nameArray = self.components(separatedBy: "/")
            if nameArray.count > 2 {
                fqdn = nameArray[2]
            } else {
                fqdn =  self
            }
            return "\(nameArray[0])//\(fqdn)"
        }
    }
    var failoverFix: String {
        get {
            var serverUrlString = ""
            let toArray = self.components(separatedBy: "/?failover")
            serverUrlString = toArray[0]
            return serverUrlString
        }
    }
    var fqdnFromUrl: String {
        get {
            var fqdn = ""
            let nameArray = self.components(separatedBy: "/")
            if nameArray.count > 2 {
                fqdn = nameArray[2]
            } else {
                fqdn =  self
            }
            if fqdn.contains(":") {
                let fqdnArray = fqdn.components(separatedBy: ":")
                fqdn = fqdnArray[0]
            }
            return fqdn
        }
    }
    func occurrencesOf(string: String) -> Int {
        return self.components(separatedBy:string).count
    }
    
}

