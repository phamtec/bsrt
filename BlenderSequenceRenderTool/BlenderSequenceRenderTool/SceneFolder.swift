//
//  SceneFolder.swift
//  BlenderSequenceRenderTool
//
//  Created by Paul Hamilton on 9/05/2016.
//  Copyright © 2016 Paul Hamilton. All rights reserved.
//

import Foundation

class SceneFolder {
    
    var project: String
    var parent: String
    var host: String
    var ext: String
    var messages: Messages
    var errorHandler: (String) -> Void
    
    init(messages: Messages, project: String, parent: String, host: String, ext: String, errorHandler: (String) -> Void) {
        self.messages = messages
        self.parent = parent
        self.host = host
        self.ext = ext
        self.project = project
        self.errorHandler = errorHandler
    }
    
    func doDownloadScene() {
        deleteAllFrameFiles()
        self.messages.add("all frame files deleted")
        BE.get().getJSONData("projects/\(project)/media", query: "", errorHandler: errorHandler) { (media: [NSDictionary]) -> Void in
            for m in media {
                let name = m["name"] as! String
                if (name == "Scene") {
                    let id = m["_id"] as! String
                    let dir:NSString = self.parent
                    let parent = dir.stringByDeletingLastPathComponent
                    self.downloadAndUnzip(id, folder: parent, file: "scene.tgz")
                }
            }
        }
    }

    func doUploadScene() {
        
        self.deleteAllFrameFiles()
        self.deleteBlenderBackupsAndZips()
        self.messages.add("all frame files, blender backups and zips deleted")
        
        let dir:NSString = self.parent
        let parent = dir.stringByDeletingLastPathComponent
        let sceneDir = "scene.tgz"
        let result = self.shell("/usr/bin/tar", arguments: ["czf", sceneDir, dir.lastPathComponent], cwd: parent)
        if (result.characters.count > 0) {
            self.messages.add(result)
        }
        else {
            self.messages.add("zipped.")
            let data = NSData(contentsOfFile: "\(parent)/\(sceneDir)")
            BE.get().uploadMedia("projects/\(project)/media", query: "", name: "Scene", mime: "application/x-tgz", data: data!, errorHandler: errorHandler) { Void in
                self.messages.add("uploaded.")
            }
        }

    }

    func deleteAllFrameFiles() {
        let fileManager = NSFileManager.defaultManager()
        let enumerator = fileManager.enumeratorAtPath(self.getFramesPath())!
        while let element = enumerator.nextObject() as? String {
            let path:NSString = element
            if (path.pathExtension == self.ext) {
                self.deleteFrameFile(path.stringByDeletingPathExtension)
            }
        }
    }
    
    func doUploadFrames() {
        deleteEmptyFrameFiles()
        
        let framedir = "\(self.host)-frames.tgz"
        let result = shell("/usr/bin/tar", arguments: ["czf", framedir, "frames"], cwd: parent)
        if (result.characters.count > 0) {
            self.messages.add(result)
        }
        else {
            self.messages.add("zipped.")
            let data = NSData(contentsOfFile: "\(parent)/\(framedir)")
            BE.get().uploadMedia("projects/\(project)/media", query: "", name: "\(self.host) Frames", mime: "application/x-tgz", data: data!, errorHandler: self.errorHandler) { Void in
                self.messages.add("uploaded.")
            }
        }
    }
    
    func downloadAndUnzip(id: String, folder: String, file: String) {
        
        BE.get().downloadMedia("media/\(id)/content", query: "", filename: "\(folder)/\(file)", errorHandler: self.errorHandler) { Void in
            self.messages.add("downloaded.")
            let result = self.shell("/usr/bin/tar", arguments: ["xzf", file], cwd: folder)
            if (result.characters.count > 0) {
                self.messages.add(result)
            }
            else {
                self.messages.add("unzipped.")
            }
        }
        
    }
    
    func collectAllFrameFiles() -> Set<String> {
        
        var files = Set<String>()
        let fileManager = NSFileManager.defaultManager()
        let enumerator = fileManager.enumeratorAtPath(getFramesPath())!
        while let element = enumerator.nextObject() as? String {
            let path:NSString = element
            if (path.pathExtension == self.ext) {
                var frame = path.stringByDeletingPathExtension
                if (isFrameFileEmpty(frame)) {
                    frame += "-"
                }
                if (!files.contains(frame)) {
                    files.insert(frame)
                }
            }
        }
        return files
        
    }

    func deleteEmptyFrameFiles() {
        
        let fileManager = NSFileManager.defaultManager()
        let enumerator = fileManager.enumeratorAtPath(getFramesPath())!
        while let element = enumerator.nextObject() as? String {
            let path:NSString = element
            if (path.pathExtension == self.ext) {
                let frame = path.stringByDeletingPathExtension
                if (isFrameFileEmpty(frame)) {
                    deleteFrameFile(frame)
                }
            }
        }
    }

    func getFramesPath() -> String {
        return "\(self.parent)/frames"
    }
    
    func frameFileExists(frame: String) -> Bool {
        let filename = getFrameFilename(frame)
        do {
            try NSFileManager.defaultManager().attributesOfItemAtPath(filename)
            return true
        } catch {
        }
        return false
    }
    
    func createEmptyFrameFile(frame: String) -> Void {
        let filename = getFrameFilename(frame)
        do {
            let empty = ""
            let url = NSURL(fileURLWithPath: filename)
            try empty.writeToURL(url, atomically: true, encoding: NSUTF8StringEncoding)
        } catch {
            print("Error: \(error)")
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
    
    private func deleteBlenderBackupsAndZips() {
        
        let fileManager = NSFileManager.defaultManager()
        let enumerator = fileManager.enumeratorAtPath(self.parent)!
        while let element = enumerator.nextObject() as? String {
            let path:NSString = element
            if (path.pathExtension == "blend1" || path.pathExtension == "tgz") {
                do {
                    try NSFileManager.defaultManager().removeItemAtPath("\(self.parent)/\(element)")
                } catch {
                    print("Error: \(error)")
                }
            }
        }
        
    }
    
    
    private func shell(launchPath: String, arguments: [String], cwd: String) -> String
    {
        let task = NSTask()
        task.launchPath = launchPath
        task.arguments = arguments
        task.currentDirectoryPath = cwd
        let pipe = NSPipe()
        task.standardOutput = pipe
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output: String = NSString(data: data, encoding: NSUTF8StringEncoding)! as String
        
        return output
    }
    
    
    private func getFrameFile(frame: String) -> String {
        if (isFrameEmpty(frame)) {
            return frame.substringToIndex(frame.endIndex.predecessor())
        }
        else {
            return frame
        }
    }
    
    private func isFrameEmpty(frame: String) -> Bool {
        return frame[frame.endIndex.predecessor()] == "-"
    }
    
    private func getFrameFilename(frame: String) -> String {
        let fr = getFrameFile(frame)
        let path = getFramesPath()
        return "\(path)/\(fr).\(self.ext)"
    }
    
    private func isFrameFileEmpty(frame: String) -> Bool {
        let filename = getFrameFilename(frame)
        do {
            let attr : NSDictionary? = try NSFileManager.defaultManager().attributesOfItemAtPath(filename)
            
            if let _attr = attr {
                return _attr.fileSize() == 0
            }
        } catch {
            print("Error: \(error)")
        }
        return false
    }
    
    private func deleteFrameFile(frame: String) -> Void {
        let filename = getFrameFilename(frame)
        do {
            try NSFileManager.defaultManager().removeItemAtPath(filename)
        } catch {
            print("Error: \(error)")
        }
    }
    
}