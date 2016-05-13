//
//  SceneFolder.swift
//  BlenderSequenceRenderTool
//
//  Created by Paul Hamilton on 9/05/2016.
//  Copyright © 2016 Paul Hamilton. All rights reserved.
//

import Foundation

class SceneFolder {
    
    var parent: String
    var ext: String
    var messages: Messages
    var errorHandler: (String) -> Void
    
    init(messages: Messages, parent: String, ext: String, errorHandler: (String) -> Void) {
        self.messages = messages
        self.parent = parent
        self.ext = ext
        self.errorHandler = errorHandler
    }

    func doZipScene(callback: (String) -> Void) {
        
        let dir:NSString = self.parent
        let parent = dir.stringByDeletingLastPathComponent
        let sceneDir = "scene.tgz"
        let result = self.shell("/usr/bin/tar", arguments: ["czf", sceneDir, dir.lastPathComponent], cwd: parent)
        if (result.characters.count > 0) {
            self.messages.add(result)
        }
        else {
            self.messages.add("zipped.")
            callback("\(parent)/\(sceneDir)")
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
        self.messages.add("all frame files deleted")
    }
    
    func doZipFrames(callback: (String) -> Void) {
        
        let framefile = "frames.tgz"
        let result = shell("/usr/bin/tar", arguments: ["czf", framefile, "frames"], cwd: parent)
        if (result.characters.count > 0) {
            self.messages.add(result)
        }
        else {
            self.messages.add("zipped.")
            callback("\(parent)/\(framefile)")
        }
    }
    
    func getParentPath() -> String {
        let dir:NSString = self.parent
        return dir.stringByDeletingLastPathComponent
    }
    
    func getParentFile(file: String) -> String {
        let parent = getParentPath()
        return "\(parent)/\(file)"
    }
    
    func getPath(file: String) -> String {
        return "\(self.parent)/\(file)"
    }
    
    func unzip(parent: String, file: String) {
        
        let result = self.shell("/usr/bin/tar", arguments: ["xzf", file], cwd: parent)
        if (result.characters.count > 0) {
            self.messages.add(result)
        }
        else {
            self.messages.add("unzipped.")
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
    
    func deleteBlenderBackupsAndZips() {
        
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
    
    
    func shell(launchPath: String, arguments: [String], cwd: String) -> String
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