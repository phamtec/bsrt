//
//  GenericBackend.swift
//  BlenderSequenceRenderTool
//
//  Created by Paul Hamilton on 27/04/2016.
//  Copyright © 2016 Paul Hamilton. All rights reserved.
//

import Foundation

class GenericBackend: Backend {
    
    var socket: SocketIOClient?

    init() {
        self.socket = SocketIOClient(socketURL: self.getServerUrl())
    }
    
    func getUsername() -> String {
        return ""
    }
    
    func getPassword() -> String {
        return ""
    }
    
    func getServerUrl() -> String {
        return "??"
    }
    
    func getSocket() -> SocketIOClient {
        return self.socket!
    }

    func getRequest(rest: String, query: String) -> NSMutableURLRequest {
        
        let path = rest.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLPathAllowedCharacterSet())
        let q = query.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
        let url = NSURL(string: "\(getServerUrl())/rest/1.0/\(path!)\(q!)")
        return NSMutableURLRequest(URL: url!)
        
    }
    
    func getRawRequest(rest: String, query: String) -> NSMutableURLRequest {
        
        let path = rest.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLPathAllowedCharacterSet())
        let q = query.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
        let url = NSURL(string: "\(getServerUrl())/\(path!)\(q!)")
        return NSMutableURLRequest(URL: url!)
        
    }
    
    func loginUser(name: String, password: String, errorHandler: (String) -> Void, callback: () -> Void) {
        
        // create some JSON
        let user: AnyObject = [
            "name": name, "password": password
        ]
        
        // POST to the login screen.
        let request = getRawRequest("login", query: "")
        let session = NSURLSession.sharedSession()
        request.HTTPMethod = "POST"
        
        do {
            request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(user, options: [])
        } catch let error as NSError {
            print(error)
            request.HTTPBody = nil
        }
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        let task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            
            GenericBackend.handleResponse(response, error: error, errorHandler: errorHandler, callback: callback)
            
        })
        
        task.resume()
        
    }
    
    func postJSONData(rest: String, query: String, data: Dictionary<String, String>, errorHandler: (String) -> Void, callback: (NSDictionary) -> Void ) -> Void {
        
        let request = getRequest(rest, query: query)
        let session = NSURLSession.sharedSession()
        request.HTTPMethod = "POST"
        
        do {
            request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(data, options: [])
        } catch let error as NSError {
            print(error)
            request.HTTPBody = nil
        }
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue((self.socket?.sid!)!, forHTTPHeaderField: "socketid")
        
        let task = session.dataTaskWithRequest(request) {data, response, error -> Void in
            
            GenericBackend.handleSingleResponse(data, response: response, error: error, errorHandler: errorHandler, callback: callback)
            
        }
        task.resume()
        
    }
    
    func patchJSONData(rest: String, query: String, data: Dictionary<String, String>, errorHandler: (String) -> Void, callback: (NSDictionary) -> Void ) -> Void {
        
        let request = getRequest(rest, query: query)
        let session = NSURLSession.sharedSession()
        request.HTTPMethod = "PATCH"
        
        do {
            request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(data, options: [])
        } catch let error as NSError {
            print(error)
            request.HTTPBody = nil
        }
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue((self.socket?.sid!)!, forHTTPHeaderField: "socketid")
       
        let task = session.dataTaskWithRequest(request) {data, response, error -> Void in
            
            GenericBackend.handleSingleResponse(data, response: response, error: error, errorHandler: errorHandler, callback: callback)
            
        }
        task.resume()
        
    }
    
    func deleteJSONData(rest: String, query: String, errorHandler: (String) -> Void, callback: (NSDictionary) -> Void ) -> Void {
        
        let request = getRequest(rest, query: query)
        let session = NSURLSession.sharedSession()
        request.HTTPMethod = "DELETE"
        
        let task = session.dataTaskWithRequest(request) {data, response, error -> Void in
            
            GenericBackend.handleSingleResponse(data, response: response, error: error, errorHandler: errorHandler, callback: callback)
            
        }
        task.resume()
        
    }
    
    func getJSONData(rest: String, query: String, errorHandler: (String) -> Void, callback: ([NSDictionary]) -> Void ) -> Void {
        
        let request = getRequest(rest, query: query)
        let session = NSURLSession.sharedSession()
        
        let task = session.dataTaskWithRequest(request) {data, response, error -> Void in
            
            GenericBackend.handleMultipleResponse(data, response: response, error: error, errorHandler: errorHandler, callback: callback)
            
        }
        
        task.resume()
    }
    
    func getJSONObject(rest: String, query: String, errorHandler: (String) -> Void, callback: (NSDictionary) -> Void ) -> Void {
        
        let request = getRequest(rest, query: query)
        let session = NSURLSession.sharedSession()
        
        let task = session.dataTaskWithRequest(request) {data, response, error -> Void in
            
            GenericBackend.handleSingleResponse(data, response: response, error: error, errorHandler: errorHandler, callback: callback)
            
        }
        
        task.resume()
    }
    
    private class func handleResponse(response: NSURLResponse!, error: NSError!, errorHandler: (String) -> Void, callback: () -> Void ) {
        
        if (response == nil) {
            if (error != nil) {
                errorHandler(error!.localizedDescription)
            }
            else {
                errorHandler("no reponse from server, and no error.")
            }
            errorHandler("Could not log onto remote server.")
        }
        else {
            if let httpResponse = response as? NSHTTPURLResponse {
                if (httpResponse.statusCode == 200) {
                    
                    callback()
                    
                }
                else if (httpResponse.statusCode == 401) {
                    errorHandler("User or password incorrect.")
                }
                else {
                    errorHandler("unexpected HTTP response \(httpResponse.statusCode)")
                }
            } else {
                errorHandler("unexpected response")
            }
        }
        
    }
    
    private class func handleSingleResponse(data: NSData!, response: NSURLResponse!, error: NSError!, errorHandler: (String) -> Void, callback: (NSDictionary) -> Void ) {
        
        if (response == nil) {
            if (error != nil) {
                errorHandler(error!.localizedDescription)
            }
            else {
                errorHandler("no reponse from server, and no error.")
            }
            errorHandler("Could not log onto remote server.")
        }
        else {
            if let httpResponse = response as? NSHTTPURLResponse {
                if (httpResponse.statusCode == 200) {
                    
                    let err: NSError? = nil
                    let json = try! NSJSONSerialization.JSONObjectWithData(data, options: .MutableLeaves) as? NSDictionary
                    if (err != nil) {
                        print(err!.localizedDescription)
                        let jsonStr = NSString(data: data, encoding: NSUTF8StringEncoding)
                        errorHandler("Error could not parse JSON: '\(jsonStr)'")
                    }
                    else {
                        callback(json!)
                    }
                }
                else if (httpResponse.statusCode == 401) {
                    errorHandler("Security error.")
                }
                else {
                    errorHandler("unexpected HTTP response \(httpResponse.statusCode)")
                }
            } else {
                errorHandler("unexpected response")
            }
        }
        
    }
    
    private class func handleMultipleResponse(data: NSData!, response: NSURLResponse!, error: NSError!, errorHandler: (String) -> Void, callback: ([NSDictionary]) -> Void ) {
        
        if (response == nil) {
            if (error != nil) {
                errorHandler(error!.localizedDescription)
            }
            else {
                errorHandler("no reponse from server, and no error.")
            }
            errorHandler("Could not log onto remote server.")
        }
        else {
            if let httpResponse = response as? NSHTTPURLResponse {
                if (httpResponse.statusCode == 200) {
                    
                    //                   let s = NSString(data: data, encoding: NSUTF8StringEncoding)
                    //                   println(s)
                    
                    let err: NSError? = nil
                    let json = try? NSJSONSerialization.JSONObjectWithData(data, options: .MutableLeaves) as? [NSDictionary]
                    if (err != nil) {
                        print(err!.localizedDescription)
                        let jsonStr = NSString(data: data, encoding: NSUTF8StringEncoding)
                        errorHandler("Error could not parse JSON: '\(jsonStr)'")
                    }
                    else {
                        callback(json!!)
                    }
                    
                }
                else if (httpResponse.statusCode == 401) {
                    errorHandler("Security error.")
                }
                else {
                    errorHandler("unexpected HTTP response \(httpResponse.statusCode)")
                }
            } else {
                errorHandler("unexpected response")
            }
        }
        
    }
    
}
