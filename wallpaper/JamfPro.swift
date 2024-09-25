//
//  Copyright 2024 Jamf. All rights reserved.
//

import Foundation
class JamfPro: NSObject, URLSessionDelegate {
    
    static let shared = JamfPro()
    private override init() { }
    
    var renewQ     = DispatchQueue(label: "com.jamfie.token_refreshQ", qos: DispatchQoS.utility)   // running background process for refreshing token
    let apiActionQ = OperationQueue() // DispatchQueue(label: "com.jamfie.apiActionQ", qos: DispatchQoS.background)
    
    func jsonAction(theServer: String, theEndpoint: String, theMethod: String, retryCount: Int, completion: @escaping (_ result: ([String:AnyObject],Int)) -> Void) {

        if retryCount == -1 {
            // skip action
//            print("skip lookup of \(theEndpoint)")
            completion(([:],0))
            return
        }
    
        URLCache.shared.removeAllCachedResponses()
        var existingDestUrl = ""
        

        existingDestUrl = "\(theServer)/JSSResource/\(theEndpoint)"
        existingDestUrl = existingDestUrl.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")
        print("[JamfPro.jsonAction] looking up \(existingDestUrl)")
        print("[JamfPro.jsonAction]    authType: \(JamfProServer.authType)")
        print("[JamfPro.jsonAction] accessToken: \(JamfProServer.accessToken)")
        
        //WriteToLog.shared.message(theMessage: "[JamfPro.jsonAction] \(theMethod) - existing endpoint URL: \(existingDestUrl)")
        let destEncodedURL = URL(string: existingDestUrl)
        let jsonRequest    = NSMutableURLRequest(url: destEncodedURL! as URL)
        
        let semaphore = DispatchSemaphore(value: 0)
        apiActionQ.maxConcurrentOperationCount = JamfProServer.maxThreads
        apiActionQ.qualityOfService = .background
        apiActionQ.addOperation {
            
            jsonRequest.httpMethod = theMethod
            let destConf = URLSessionConfiguration.default
            destConf.timeoutIntervalForRequest = 10.0
            destConf.httpAdditionalHeaders = ["Authorization" : "\(JamfProServer.authType) \(JamfProServer.accessToken)", "Content-Type" : "application/json", "Accept" : "application/json", "User-Agent" : AppInfo.userAgentHeader]
            
            let destSession = Foundation.URLSession(configuration: destConf, delegate: self, delegateQueue: OperationQueue.main)
            let task = destSession.dataTask(with: jsonRequest as URLRequest, completionHandler: {
                (data, response, error) -> Void in
                destSession.finishTasksAndInvalidate()
                if let err = error {
    //                    print("Error localizedDescription: \(err.localizedDescription)")
                    WriteToLog.shared.message(theMessage: "[JamfPro.jsonAction] an HTTP error occured: \(err.localizedDescription)")
                    _ = Alert.shared.display(header: "\(err.localizedDescription)", message: "")
                    completion(([:],0))
                    return
                }
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode >= 200 && httpResponse.statusCode <= 299 {
                        do {
                            let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                            if let endpointJSON = json as? [String:AnyObject] {
//                                if LogLevel.debug { //WriteToLog.shared.message(theMessage: "[JamfPro.jsonAction] \(endpointJSON)\n") }
                                completion((endpointJSON,httpResponse.statusCode))
                            } else {
//                                //WriteToLog.shared.message(theMessage: "[JamfPro.jsonAction] error parsing JSON for \(existingDestUrl)\n")
                                completion(([:],httpResponse.statusCode))
                            }
                        }
                    } else {
                        //WriteToLog.shared.message(theMessage: "[JamfPro.jsonAction] error during GET, HTTP Status Code: \(httpResponse.statusCode)\n")
                        if "\(httpResponse.statusCode)" == "401" && retryCount < 1 {
                            if JamfProServer.authType == "Bearer" {
                                //WriteToLog.shared.message(theMessage: "[JamfPro.jsonAction] authentication failed.  Trying to gneerate a new token")
                                TokenDelegate.shared.getToken(serverUrl: JamfProServer.URL, whichServer: "source", base64creds: JamfProServer.base64Creds) {
                                    (result: (Int,String)) in
                                    let (_,passFail) = result
                                    if passFail != "failed" {
                                        self.jsonAction(theServer: theServer, theEndpoint: theEndpoint, theMethod: theMethod, retryCount: retryCount+1) {
                                        (result: ([String:AnyObject],Int)) in
                                            completion(result)
                                        }
                                    } else {
                                        //WriteToLog.shared.message(theMessage: "[JamfPro.jsonAction] authentication failed.")
                                        completion((["Message":"Failed to authenticate" as AnyObject],httpResponse.statusCode))
                                    }
                                }
                            } else {
                                completion((["Message":"Failed to authenticate" as AnyObject],httpResponse.statusCode))
                            }
                        } else if httpResponse.statusCode > 499 && retryCount < 1 {
                            sleep(5)
                            //WriteToLog.shared.message(theMessage: "[JamfPro.jsonAction] Retry \(existingDestUrl)")
                            self.jsonAction(theServer: theServer, theEndpoint: theEndpoint, theMethod: theMethod, retryCount: retryCount+1) {
                                (result: ([String:AnyObject],Int)) in
                                completion(result)
                            }
                        } else {
                            completion(([:],0))
                        }
                    }
                } else {
                    //WriteToLog.shared.message(theMessage: "[JamfPro.jsonAction] error parsing JSON for \(existingDestUrl)")
                    //WriteToLog.shared.message(theMessage: "[JamfPro.jsonAction] error: \(String(describing: error))")
                    completion(([:],0))
                }   // if let httpResponse - end
                semaphore.signal()
                if error != nil {
                }
            })  // let task = destSession - end
            //print("GET")
            task.resume()
            semaphore.wait()
        }   // apiActionQ - end
    }
    
    func xmlAction(theServer: String, theEndpoint: String, theMethod: String, theData: String, skip: Bool, completion: @escaping (_ result: [Int:String]) -> Void) {

        if AppInfo.stopUpdates {
            apiActionQ.cancelAllOperations()
            completion([0:"success"])
            return
        }
        
        if skip {
            completion([0:"success"])
            return
        }
        
        URLCache.shared.removeAllCachedResponses()
        var existingDestUrl = ""
        
        existingDestUrl = "\(theServer)/JSSResource/\(theEndpoint)"
        existingDestUrl = existingDestUrl.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")
        
//        if LogLevel.debug { //WriteToLog.shared.message(theMessage: "[JamfPro.xmlAction] Looking up: \(existingDestUrl)\n") }
        //WriteToLog.shared.message(theMessage: "[JamfPro.xmlAction] \(theMethod) - existing endpoint URL: \(existingDestUrl)")
        let destEncodedURL = URL(string: existingDestUrl)
        let xmlRequest    = NSMutableURLRequest(url: destEncodedURL! as URL)
        
        let semaphore = DispatchSemaphore(value: 0)
        apiActionQ.maxConcurrentOperationCount = JamfProServer.maxThreads
        apiActionQ.qualityOfService = .default
        apiActionQ.addOperation {
            
            xmlRequest.httpMethod = theMethod
            let destConf = URLSessionConfiguration.default
            destConf.httpAdditionalHeaders = ["Authorization" : "\(JamfProServer.authType) \(JamfProServer.accessToken)", "Content-Type" : "application/xml", "Accept" : "application/xml", "User-Agent" : AppInfo.userAgentHeader]
            if theMethod == "POST" || theMethod == "PUT" {
                let encodedXML = theData.data(using: String.Encoding.utf8)
                xmlRequest.httpBody = encodedXML!
            }
            
            let destSession = Foundation.URLSession(configuration: destConf, delegate: self, delegateQueue: OperationQueue.main)
            let task = destSession.dataTask(with: xmlRequest as URLRequest, completionHandler: {
                (data, response, error) -> Void in
                destSession.finishTasksAndInvalidate()
                if let err = error {
    //                    print("Error localizedDescription: \(err.localizedDescription)")
                    WriteToLog.shared.message(theMessage: "[JamfPro.xmlAction] an HTTP error occured: \(err.localizedDescription)")
                    _ = Alert.shared.display(header: "\(err.localizedDescription)", message: "")
                    completion([0:"failed"])
                    return
                }
                if let httpResponse = response as? HTTPURLResponse {
//                    print("[JamfPro.xmlAction] httpResponse: \(String(describing: httpResponse))")
                    if httpResponse.statusCode >= 200 && httpResponse.statusCode <= 299 {
                        
//                                //WriteToLog.shared.message(theMessage: "[JamfPro.xmlAction] error parsing JSON for \(existingDestUrl)\n")
                        completion([httpResponse.statusCode:"success"])
                        
                    } else {
                        //WriteToLog.shared.message(theMessage: "[JamfPro.xmlAction] error during \(theMethod), HTTP Status Code: \(httpResponse.statusCode)\n")
                        if "\(httpResponse.statusCode)" == "401" {
                            //_ = Alert.shared.display(header: "Alert", message: "Verify username and password.")
                        }
                        if httpResponse.statusCode > 500 {
                            //WriteToLog.shared.message(theMessage: "[JamfPro.xmlAction] momentary pause\n")
                            sleep(2)
                            //WriteToLog.shared.message(theMessage: "[JamfPro.xmlAction] back to work\n")
                        }
//                        //WriteToLog.shared.message(theMessage: "[JamfPro.xmlAction] error HTTP Status Code: \(httpResponse.statusCode)\n")
                        completion([httpResponse.statusCode:"failed"])
                    }
                } else {
//                    //WriteToLog.shared.message(theMessage: "[JamfPro.xmlAction] error parsing JSON for \(existingDestUrl)\n")
                    completion([0:""])
                }   // if let httpResponse - end
                semaphore.signal()
                if error != nil {
                }
            })  // let task = destSession - end
            //print("GET")
            task.resume()
            semaphore.wait()
        }   // apiActionQ - end
    }
        
    func jpapiAction(serverUrl: String, endpoint: String, apiData: [String:Any], id: String, token: String, method: String, completion: @escaping (_ returnedJSON: [String: Any]) -> Void) {
        
        if method.lowercased() == "skip" {
            completion(["JPAPI_result":"failed", "JPAPI_response":000])
            return
        }
        
        URLCache.shared.removeAllCachedResponses()
        var path = ""

        switch endpoint {
        case  "buildings", "csa/token", "icon", "jamf-pro-version":
            path = "v1/\(endpoint)"
        default:
            path = "v2/\(endpoint)"
        }

        var urlString = "\(serverUrl)/api/\(path)"
        urlString     = urlString.replacingOccurrences(of: "//api", with: "/api")
        if id != "" && id != "0" {
            urlString = urlString + "/\(id)"
        }
//        print("[Jpapi] urlString: \(urlString)")
        
        let url            = URL(string: "\(urlString)")
        let configuration  = URLSessionConfiguration.ephemeral
        var request        = URLRequest(url: url!)
        switch method.lowercased() {
        case "get":
            request.httpMethod = "GET"
        case "create", "post":
            request.httpMethod = "POST"
        default:
            request.httpMethod = "PUT"
        }
        
        if apiData.count > 0 {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: apiData, options: .prettyPrinted)
            } catch let error {
                print(error.localizedDescription)
            }
        }
        
//        print("[Jpapi.action] Attempting \(method) on \(urlString).")
        
        configuration.httpAdditionalHeaders = ["Authorization" : "Bearer \(token)", "Content-Type" : "application/json", "Accept" : "application/json"]
        let session = Foundation.URLSession(configuration: configuration, delegate: self as URLSessionDelegate, delegateQueue: OperationQueue.main)
        let task = session.dataTask(with: request as URLRequest, completionHandler: {
            (data, response, error) -> Void in
            session.finishTasksAndInvalidate()
            if let err = error {
//                    print("Error localizedDescription: \(err.localizedDescription)")
                WriteToLog.shared.message(theMessage: "[JamfPro.jpapiAction] an HTTP error occured: \(err.localizedDescription)")
                _ = Alert.shared.display(header: "\(err.localizedDescription)", message: "")
                completion(["JPAPI_result":"failed", "JPAPI_response":0])
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode >= 200 && httpResponse.statusCode <= 299 {
                    let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                    if let endpointJSON = json! as? [String:Any] {
                        completion(endpointJSON)
                        return
                    } else {    // if let endpointJSON error
                        completion(["JPAPI_result":"failed", "JPAPI_response":httpResponse.statusCode])
                        return
                    }
                } else {    // if httpResponse.statusCode <200 or >299
                    completion(["JPAPI_result":"failed", "JPAPI_method":request.httpMethod ?? method, "JPAPI_response":httpResponse.statusCode, "JPAPI_server":urlString, "JPAPI_token":token])
                    return
                }
            } else {
                completion([:])
                return
            }
        })
        task.resume()
        
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping(  URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
}
