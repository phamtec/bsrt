//
//  AlertUtils.swift
//  BlenderSequenceRenderTool
//
//  Created by Paul Hamilton on 27/04/2016.
//  Copyright © 2016 Paul Hamilton. All rights reserved.
//


import Foundation
import AppKit

class AlertUtils {
    
    class func defaultErrorHandler(controller: NSViewController) -> (String) -> Void {
        return { message -> Void in
            dispatch_async(dispatch_get_main_queue()) {
                () -> Void in
                let v = controller as! ViewController
                v.addMsg(message)
            }
        }
    }
    
}
