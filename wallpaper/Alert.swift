//
//  Copyright 2024 Jamf. All rights reserved.
//

import Cocoa

class Alert: NSObject {
    
    static let shared = Alert()
    private override init() { }
    
    func display(header: String, message: String, firstButton: String = "OK", secondButton: String = "") -> String {
        NSApplication.shared.activate(ignoringOtherApps: true)
        var selected = ""
        let dialog: NSAlert = NSAlert()
        dialog.messageText = header
        dialog.informativeText = message
        dialog.alertStyle = NSAlert.Style.warning
        if secondButton != "" {
            let otherButton = dialog.addButton(withTitle: secondButton)
            otherButton.keyEquivalent = "\r"
        }
        let okButton = dialog.addButton(withTitle: firstButton)
        okButton.keyEquivalent = "\(firstButton.lowercased().first ?? "o")"
        
        let theButton = dialog.runModal()
        switch theButton {
        case .alertFirstButtonReturn:
            selected = secondButton
        default:
            selected = firstButton
        }
        return selected
    }   // func alert_dialog - end
}
