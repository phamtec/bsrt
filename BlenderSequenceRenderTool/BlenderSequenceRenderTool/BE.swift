//
//  BE.swift
//  BlenderSequenceRenderTool
//
//  Created by Paul Hamilton on 27/04/2016.
//  Copyright © 2016 Paul Hamilton. All rights reserved.
//

import Foundation

//let _sharedBackend: Backend = { LocalBackend() }()
let _sharedBackend: Backend = { ProdBackend() }()
//let _sharedBackend: Backend = { TestingBackend() }()

class BE {
    class func get() -> Backend {
        return _sharedBackend
    }
}

