//
//  Copyright 2024 Jamf. All rights reserved.
//


import Foundation
import Security

struct KeychainItem {
    var service: String
    var account: String
    var secret: String
    
    init(service: String, account: String, secret: String) {
        self.service = service
        self.account = account
        self.secret = secret
    }
}

var keychainItems = [KeychainItem]()

let kSecAttrAccountString          = NSString(format: kSecAttrAccount)
let kSecValueDataString            = NSString(format: kSecValueData)
let kSecClassGenericPasswordString = NSString(format: kSecClassGenericPassword)
let keychainQ                      = DispatchQueue(label: "org.jamf.wallpaper", qos: DispatchQoS.background)
let sharedPrefix                   = "JSK"
let accessGroup                    = "483DWKW443.jamfie.SharedJSK"
var useApiClient                   = 1
var useUsername                    = 0

class Credentials {
    
    static let shared = Credentials()
    private init() { }
    
    var userPassDict     = [String:String]()
    var keychainItemName = ""
    var returnMessage    = "keychain save process completed successfully"
    
//    func save(service: String, account: String, credential: String) -> String {
    func save(arrayOfKeychainItems: [KeychainItem]) -> String {
        keychainQ.async { [self] in
            for theKeychainItem in arrayOfKeychainItems {
                let service = theKeychainItem.service.lowercased()
                let account = theKeychainItem.account.lowercased()
                let credential = theKeychainItem.secret
                if !service.isEmpty {
                    
                    var theService = service
                
        //            print("[Credentials.save] useApiClient: \(useApiClient)")
                    if useApiClient == 1 {
                        theService = "apiClient-" + theService
                    }
                    
                    let keychainItemName = sharedPrefix + "-" + theService
                    
                    WriteToLog.shared.message(theMessage: "[credentials.save] keychain item \(keychainItemName) for account \(account)")
                    if let password = credential.data(using: String.Encoding.utf8) {
                        //                    keychainQ.async { [self] in
                        var keychainQuery: [String: Any] = [kSecClass as String: kSecClassGenericPasswordString,
                                                            kSecAttrService as String: keychainItemName,
                                                            kSecAttrAccessGroup as String: accessGroup,
                                                            kSecUseDataProtectionKeychain as String: true,
                                                            kSecAttrAccount as String: account,
                                                            kSecValueData as String: password]
                        
                        // see if credentials already exist for server
                        //                    print("[save] for for keychain item: \(service) for account: \(account)")
                        //                    let accountCheck = checkExisting(service: keychainItemName, account: account)
                        let accountCheck = retrieve(service: service, account: account)
//                        print("[save] service: \(service)")
//                        print("[save] matches found: \(accountCheck.count)")
//                        print("[save] matches: \(accountCheck)")
                        if accountCheck[account] == nil {
                            // try to add new credentials
                            WriteToLog.shared.message(theMessage: "[credentials.save] adding new keychain item \(keychainItemName) for account \(account)")
                            let addStatus = SecItemAdd(keychainQuery as CFDictionary, nil)
                            if (addStatus != errSecSuccess) {
                                if let addErr = SecCopyErrorMessageString(addStatus, nil) {
                                    //                                print("[addStatus] Write failed for service \(service), account \(account): \(addErr)")
                                    WriteToLog.shared.message(theMessage: "[credentials.save] Write failed for service \(keychainItemName), account \(account): \(addErr)")
                                }
                                returnMessage = "keychain save process was unsuccessful"
                            } else {
                                WriteToLog.shared.message(theMessage: "[credentials.save] keychain item added")
                            }
                        } else {
                            // credentials already exist, try to update
                            WriteToLog.shared.message(theMessage: "[credentials.update] see if keychain item \(keychainItemName) for account \(account) needs updating")
                            keychainQuery = [kSecClass as String: kSecClassGenericPasswordString,
                                             kSecAttrService as String: keychainItemName,
                                             kSecAttrAccessGroup as String: accessGroup,
                                             kSecAttrAccount as String: account,
                                             kSecUseDataProtectionKeychain as String: true,
                                             kSecMatchLimit as String: kSecMatchLimitOne,
                                             kSecReturnAttributes as String: true]
                            if credential != accountCheck[account] {
                                let updateStatus = SecItemUpdate(keychainQuery as CFDictionary, [kSecValueDataString:password] as [NSString : Any] as CFDictionary)
                                if (updateStatus != errSecSuccess) {
//                                    if let updateErr = SecCopyErrorMessageString(updateStatus, nil) {
                                        //                                    print("[addStatus] keychain item for service \(service), account \(account), failed to update.")
                                        WriteToLog.shared.message(theMessage: "[credentials.update] keychain item for service \(service), account \(account), failed to update.")
                                        returnMessage = "keychain save process was unsuccessful"
//                                    } else {
//                                        WriteToLog.shared.message(theMessage: "[credentials.update] keychain item for service \(service), account \(account), has been updated.")
//                                    }
                                } else {
                                    //                                    print("[addStatus] keychain item for service \(service), account \(account), has been updated.")
                                    WriteToLog.shared.message(theMessage: "[credentials.update] keychain item for service \(service), account \(account), has been updated.")
                                }
                            } else {
                                returnMessage = "keychain item is current"
                            }
                        }
                        //                    }
                    } else {
                        WriteToLog.shared.message(theMessage: "[credentials.save] failed to set password for \(keychainItemName), account \(account)")
                        returnMessage = "keychain save process was unsuccessful"
                    }
                }
                //            sleep(1)
            }
            print("[Credentials.save] loop returnMessage:\(returnMessage)")
        }   // for theKeychainItem in arrayOfKeychainItems - end
        print("[Credentials.save] final returnMessage:\(returnMessage)")
        return returnMessage
    }   // func save - end
    
    func retrieve(service: String, account: String = "") -> [String:String] {
        WriteToLog.shared.message(theMessage: "[retrieve] fetch credentials for service: \(service)")
        WriteToLog.shared.message(theMessage: "[retrieve] fetch password/secret for: \(account)")
//        print("[credentials.retrieve] service passed: \(service)")
        var keychainResult   = [String:String]()
        var theService = service.lowercased()

        print("[credentials] JamfProServer useApiClient: \(useApiClient)")
        
        if useApiClient == 1 {
            theService = "apiClient-" + theService
        }
        
        let keychainItemName = sharedPrefix + "-" + theService
        
//        print("[retrieve] keychainItemName: \(keychainItemName)")
        WriteToLog.shared.message(theMessage: "[credentials.retrieve] keychainName: \(keychainItemName), account: \(account)")
        // look for common keychain item
        keychainResult = itemLookup(service: keychainItemName)
//        print("[retrieve] keychainItemName: \(keychainItemName)")
//        print("[retrieve]   keychainResult: \(keychainResult)")
        
//        if keychainResult.count > 0 {
//            let deleteResult = delete(service: keychainItemName, account: account)
//            print("[retrieve] deleteResult: \(deleteResult)")
//        }
        
        if keychainResult.count > 1 && !account.isEmpty {
            
            for (username, password) in keychainResult {
                if username.lowercased() == account {
                    WriteToLog.shared.message(theMessage: "[credentials.retrieve] found password for: \(account)")
                    return [username:password]
                }
            }
        }
        
        return keychainResult
    }
    
    func itemLookup(service: String) -> [String:String] {
        userPassDict.removeAll()
//        print("[credentials.itemLookup] keychainName: \(service)")
        let keychainQuery: [String: Any] = [kSecClass as String: kSecClassGenericPasswordString,
                                            kSecAttrService as String: service,
                                            kSecAttrAccessGroup as String: accessGroup,
                                            kSecUseDataProtectionKeychain as String: true,
                                            kSecMatchLimit as String: kSecMatchLimitAll,
                                            kSecReturnAttributes as String: true,
                                            kSecReturnData as String: true] // new

        var items_ref: CFTypeRef?
        
        let status = SecItemCopyMatching(keychainQuery as CFDictionary, &items_ref)
        guard status != errSecItemNotFound else {
            WriteToLog.shared.message(theMessage: "[credentials.itemLookup] keychain item, \(service), was not found")
            return [:]
            
        }
        guard status == errSecSuccess else { return [:] }
        
        guard let items = items_ref as? [[String: Any]] else {
            WriteToLog.shared.message(theMessage: "[credentials.itemLookup] unable to read keychain item: \(service)")
            return [:]
        }
        for item in items {
            if let account = item[kSecAttrAccount as String] as? String, let passwordData = item[kSecValueData as String] as? Data {
                let password = String(data: passwordData, encoding: String.Encoding.utf8)
                userPassDict[account] = password ?? ""
            }
        }

        WriteToLog.shared.message(theMessage: "[credentials.itemLookup] keychain item count: \(userPassDict.count) for \(service)")
        return userPassDict
    }
    
    func delete(service: String, account: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccessGroup as String: accessGroup,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        return status == errSecSuccess
    }
}

