//
//  ProdBackend.swift
//  BlenderSequenceRenderTool
//
//  Created by Paul Hamilton on 27/04/2016.
//  Copyright © 2016 Paul Hamilton. All rights reserved.
//

import Foundation

class ProdBackend: GenericBackend {
/*
    override func getUsername() -> String {
        return "paulh"
    }
     
    override func getPassword() -> String {
        return "????"
    }
*/
    override func getServerUrl() -> String {
        return "https://staging2.visualops.com"
    }

}
