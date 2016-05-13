//
//  RemoteProject.swift
//  BlenderSequenceRenderTool
//
//  Created by Paul Hamilton on 9/05/2016.
//  Copyright © 2016 Paul Hamilton. All rights reserved.
//

import Foundation

class RemoteProject {
    
    var project: String
    var host: String
    var messages: Messages
    var errorHandler: (String) -> Void
   
    init(messages: Messages, project: String, host: String, errorHandler: (String) -> Void) {
        self.messages = messages
        self.project = project
        self.host = host
        self.errorHandler = errorHandler
    }
    
    func doFindScene(callback: (String) -> Void) {

        BE.get().getJSONData("projects/\(project)/media", query: "", errorHandler: errorHandler) { (media: [NSDictionary]) -> Void in
            for m in media {
                let name = m["name"] as! String
                if (name == "Scene") {
                    callback(m["_id"] as! String)
                }
            }
        }
    }
    
    func forAllFrames(callback: (String) -> Void) {
        
        BE.get().getJSONData("projects/\(project)/media", query: "", errorHandler: errorHandler) { (media: [NSDictionary]) -> Void in
            for m in media {
                let name = m["name"] as! String
                if (name.rangeOfString(".* Frames", options: .RegularExpressionSearch) != nil) {
                    callback(m["_id"] as! String)
                }
            }
        }
        
    }
    
    func downloadMedia(id: String, filename: String, callback: () -> Void) {
        
        BE.get().downloadMedia("media/\(id)/content", query: "", filename: filename, errorHandler: self.errorHandler) { Void in
            self.messages.add("downloaded.")
            callback()
        }
        
    }
    
    func uploadFrames(frames: Set<String>, callback: () -> Void) {
        
        var post: Dictionary<String, String> = Dictionary<String, String>()
        post["project"] = self.project
        post["host"] = self.host
        var s = ""
        for f in frames {
            if (!s.isEmpty) {
                s += ", "
            }
            s += f
        }
        post["frames"] = s
        
        BE.get().postJSONData("progress", query: "", data: post, errorHandler: self.errorHandler) { (d) -> Void in
            
            callback()
            
        }
        
    }
    
    func uploadSceneArchive(filename: String) {
        
        let data = NSData(contentsOfFile: filename)
        BE.get().uploadMedia("projects/\(project)/media", query: "", name: "Scene", mime: "application/x-tgz", data: data!, errorHandler: self.errorHandler) { Void in
            self.messages.add("uploaded.")
        }

    }

    func uploadFramesArchive(filename: String) {
        
        let data = NSData(contentsOfFile: filename)
        BE.get().uploadMedia("projects/\(project)/media", query: "", name: "\(self.host) Frames", mime: "application/x-tgz", data: data!, errorHandler: self.errorHandler) { Void in
            self.messages.add("uploaded.")
        }
        
    }
    
    func deleteServerFrames(callback: () -> Void) {
        
        BE.get().deleteJSONData("progress", query: "?project=\(project)&host=\(host)", errorHandler: self.errorHandler) { (d) -> Void in
            
            callback()
            
        }
        
    }
    
    func deleteAllServerFrames(callback: () -> Void) {
        
        BE.get().deleteJSONData("progress", query: "?project=\(project)", errorHandler: self.errorHandler) { (d) -> Void in
            
            callback()
            
        }
        
    }
    
}