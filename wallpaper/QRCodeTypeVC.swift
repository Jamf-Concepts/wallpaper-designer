//
//  Copyright 2024 Jamf. All rights reserved.
//

import Cocoa

protocol SendingStringDelegate {
    func sendQrCodeString(textString: String, update: Bool)
}

class QRCodeTypeVC: NSViewController, NSTextFieldDelegate {
     
    var delegate: SendingStringDelegate? = nil
    
    @IBOutlet weak var qrCodeText_textField: NSTextField!
    
    @IBOutlet weak var ok_button: NSButton!
    @IBOutlet weak var cancel_button: NSButton!
    
    @IBAction func cancel_action(_ sender: Any) {
        delegate?.sendQrCodeString(textString: qrCodeText_textField.stringValue, update: false)
        dismiss(self)
    }
    @IBAction func ok_action(_ sender: Any) {
        delegate?.sendQrCodeString(textString: qrCodeText_textField.stringValue, update: true)
        dismiss(self)
    }
    
//    func sendTextString() {
//        delegate?.sendString(textString: qrCodeText_textField.stringValue)
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        qrCodeText_textField.delegate = self
        qrCodeText_textField.stringValue = defaults.string(forKey: "qrCodeText") ?? ""
        
    }
}
