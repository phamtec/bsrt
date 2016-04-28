//
//  LocalBackend.swift
//  BlenderSequenceRenderTool
//
//  Created by Paul Hamilton on 27/04/2016.
//  Copyright © 2016 Paul Hamilton. All rights reserved.
//

import Foundation

class LocalBackend: GenericBackend {
    
    override func getUsername() -> String {
        return "tracy"
    }
    
    override func getPassword() -> String {
        return "password"
    }
    
    override func getServerUrl() -> String {
//        return "http://localhost:8080"
        return "http://10.0.0.104:8080"
    }

}
