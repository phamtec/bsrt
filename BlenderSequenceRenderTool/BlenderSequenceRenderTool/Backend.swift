//
//  Backend.swift
//  BlenderSequenceRenderTool
//
//  Created by Paul Hamilton on 27/04/2016.
//  Copyright © 2016 Paul Hamilton. All rights reserved.
//

import Foundation

protocol Backend {
    
    func getUsername() -> String
    func getPassword() -> String
    func getServerUrl() -> String
    
    func getSocket() -> SocketIOClient
    
    func getRequest(rest: String, query: String) -> NSMutableURLRequest
    func getRawRequest(rest: String, query: String) -> NSMutableURLRequest
    func loginUser(name: String, password: String, errorHandler: (String) -> Void, callback: () -> Void)
    func postJSONData(rest: String, query: String, data: Dictionary<String, String>, errorHandler: (String) -> Void, callback: (NSDictionary) -> Void ) -> Void
    func patchJSONData(rest: String, query: String, data: Dictionary<String, String>, errorHandler: (String) -> Void, callback: (NSDictionary) -> Void ) -> Void
    func deleteJSONData(rest: String, query: String, errorHandler: (String) -> Void, callback: (NSDictionary) -> Void ) -> Void
    func getJSONData(rest: String, query: String, errorHandler: (String) -> Void, callback: ([NSDictionary]) -> Void ) -> Void
    func getJSONObject(rest: String, query: String, errorHandler: (String) -> Void, callback: (NSDictionary) -> Void ) -> Void
    
}
