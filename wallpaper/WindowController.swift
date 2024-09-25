//
//  Copyright 2024 Jamf. All rights reserved.
//

import Cocoa
import Foundation

class WindowController: NSWindowController {
    override func windowDidLoad() {
        super.windowDidLoad()
        self.windowFrameAutosaveName = "MainAppWindow"
    }
}
