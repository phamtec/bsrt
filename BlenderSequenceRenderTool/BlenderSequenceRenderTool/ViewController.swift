//
//  ViewController.swift
//  BlenderSequenceRenderTool
//
//  Created by Paul Hamilton on 27/04/2016.
//  Copyright © 2016 Paul Hamilton. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet var usernameField: NSTextField!
    @IBOutlet var passwordField: NSSecureTextField!
    @IBOutlet var projectField: NSTextField!
    @IBOutlet var hostField: NSTextField!
    @IBOutlet var folderField: NSTextField!
    @IBOutlet var extensionField: NSTextField!
    @IBOutlet var working: NSProgressIndicator!
    @IBOutlet var start: NSButton!
    @IBOutlet var stop: NSButton!
    @IBOutlet var login: NSButton!
    @IBOutlet var message: NSTextField!
    
    var source:dispatch_source_t?
    var files = Set<String>()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.working.hidden = true
        self.stop.enabled = false
        self.start.enabled = false
        self.usernameField.stringValue = BE.get().getUsername()
        self.passwordField.stringValue = BE.get().getPassword()
        
        withProject() { project in
            
            self.withFolder() { folder in
                
                if let p = project {
                    self.projectField.stringValue = p.name!
                }
                if let f = folder {
                    self.folderField.stringValue = f.path!
                    self.extensionField.stringValue = f.ext!
                }
                self.hostField.stringValue = NSHost.currentHost().localizedName!
            }
            
        }
        
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }


    @IBAction func login(sender: AnyObject) {
        
        self.working.startAnimation(self)
        self.working.hidden = false
        
        BE.get().loginUser(usernameField.stringValue, password: passwordField.stringValue, errorHandler: AlertUtils.defaultErrorHandler(self)) {
            
            BE.get().getJSONObject("users/me", query: "", errorHandler: AlertUtils.defaultErrorHandler(self)) { (user: NSDictionary) -> Void in
                
                dispatch_async(dispatch_get_main_queue()) {
                    () -> Void in
                    
                    self.working.stopAnimation(self)
                    self.working.hidden = true
                    self.login.enabled = false
                    self.usernameField.enabled = false
                    self.passwordField.enabled = false
                    self.start.enabled = true
                    
                }
                               
            }
            
        }
        
    }
    
    @IBAction func start(sender: AnyObject) {
        
        deleteProject()
        saveProject(projectField.stringValue)
        deleteFolder()
        saveFolder(self.folderField.stringValue, ext: self.extensionField.stringValue)
        
        self.stop.enabled = true
        self.start.enabled = false
        self.projectField.enabled = false
        self.folderField.enabled = false
        self.extensionField.enabled = false
        startWatchingFolder()
        
        BE.get().getSocket().on("progress") { data, ack in
            
            let d = data[0] as? NSDictionary
            let frames = d!["frames"] as! String
            self.createPlaceHolders(frames)
            
        }
        
        BE.get().getSocket().on("id") {data, ack in
            let data: AnyObject = [
                "id": self.projectField.stringValue, "initials": "", "userid": ""
            ]
            BE.get().getSocket().emit("openDocument", data)
        }
        
        BE.get().getSocket().connect()
        
    }
    
    private func createPlaceHolders(frames: String) {
        let fa = frames.componentsSeparatedByString(",")
        let ws = NSCharacterSet.whitespaceAndNewlineCharacterSet()
        for f in fa {
            let fr = f.stringByTrimmingCharactersInSet(ws)
            if (!frameFileExists(fr)) {
                createEmptyFrameFile(fr)
            }
        }
    }
    
    @IBAction func stop(sender: AnyObject) {
        stopWatchingFolder()
        self.stop.enabled = false
        self.start.enabled = true
        self.projectField.enabled = true
        self.folderField.enabled = true
        self.extensionField.enabled = true
   }
    
    @IBAction func setFolder(sender: AnyObject) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.beginWithCompletionHandler() { result in
            if (result == 1) {
                self.folderField.stringValue = (panel.URL?.absoluteURL.filePathURL?.path)!
                self.deleteFolder()
                self.saveFolder(self.folderField.stringValue, ext: self.extensionField.stringValue)
            }
        }
        
    }
    
    private func stopWatchingFolder() {
        if (self.source != nil) {
            dispatch_source_cancel(self.source!)
        }
    }
    
    private func collectAllFiles() -> Set<String> {
    
        var files = Set<String>()
        let fileManager = NSFileManager.defaultManager()
        let enumerator = fileManager.enumeratorAtPath(self.folderField.stringValue)!
        while let element = enumerator.nextObject() as? String {
            let path:NSString = element
            if (path.pathExtension == self.extensionField.stringValue) {
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
    
    private func deleteFrames(callback: () -> Void) {
        
        BE.get().deleteJSONData("progress", query: "?project=\(self.projectField.stringValue)&host=\(self.hostField.stringValue)", errorHandler: AlertUtils.defaultErrorHandler(self)) { (d) -> Void in
            
            callback()
            
        }
        
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
        return "\(self.folderField.stringValue)/\(fr).\(self.extensionField.stringValue)"
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
    
    private func frameFileExists(frame: String) -> Bool {
        let filename = getFrameFilename(frame)
        do {
            try NSFileManager.defaultManager().attributesOfItemAtPath(filename)
            return true
        } catch {
        }
        return false
    }
    
    private func createEmptyFrameFile(frame: String) -> Void {
        let filename = getFrameFilename(frame)
        do {
            let empty = ""
            let url = NSURL(fileURLWithPath: filename)
            try empty.writeToURL(url, atomically: true, encoding: NSUTF8StringEncoding)
        } catch {
            print("Error: \(error)")
        }
    }
    
    private func uploadFrames(frames: Set<String>, callback: () -> Void) {
        
        var post: Dictionary<String, String> = Dictionary<String, String>()
        post["project"] = self.projectField.stringValue
        post["host"] = self.hostField.stringValue
        var s = ""
        for f in frames {
            if (!s.isEmpty) {
                s += ", "
            }
            s += f
        }
        post["frames"] = s
        
        BE.get().postJSONData("progress", query: "", data: post, errorHandler: AlertUtils.defaultErrorHandler(self)) { (d) -> Void in
            
            callback()
            
        }
        
    }
    
    private func watchFolder() {
        
        let folder = open(self.folderField.stringValue, O_RDONLY)
        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        self.source = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, UInt(folder), DISPATCH_VNODE_WRITE, queue)
        
        dispatch_source_set_event_handler(self.source!, {
            let newfiles = self.collectAllFiles()
            let diff = newfiles.subtract(self.files)
            if (diff.count > 0) {
                
                self.uploadFrames(diff) {
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        () -> Void in
                        
                        self.message.stringValue = "frames uploaded"
                        self.files = newfiles
                        
                    }
                    
                }
                
            }
            
        })
        
        dispatch_source_set_cancel_handler(self.source!, {
            close(folder)
        })
        
        dispatch_resume(self.source!)
        
    }
    
    private func startWatchingFolder() {
        
        deleteFrames() {
            
            self.files = self.collectAllFiles()
            if (self.files.count > 0) {
                self.uploadFrames(self.files) {
                    self.watchFolder()
                }
            }
            else {
                self.watchFolder()
            }
        }
    }
    
    private func deleteEntities(name: String) {
        let app = NSApplication.sharedApplication().delegate as! AppDelegate
        let fetchRequest = NSFetchRequest(entityName: name)
        if let fetchResults = (try? app.managedObjectContext.executeFetchRequest(fetchRequest)) as? [NSManagedObject] {
            for u in fetchResults {
                app.managedObjectContext.deleteObject(u)
            }
        }
        var e: NSError?
        do {
            try app.managedObjectContext.save()
        } catch let error as NSError {
            e = error
            print("delete error: \(e!.localizedDescription)")
            abort()
        }
    }
    
    private func save() {
        
        let app = NSApplication.sharedApplication().delegate as! AppDelegate
        do {
            try app.managedObjectContext.save()
        } catch {
            fatalError("Failure to save context: \(error)")
        }
        
    }
    
    func saveProject(name: String) {
        let app = NSApplication.sharedApplication().delegate as! AppDelegate
        let project = NSEntityDescription.insertNewObjectForEntityForName("Project", inManagedObjectContext: app.managedObjectContext) as! Project
        project.name = name
        save()
    }
    
    func deleteProject() {
        deleteEntities("Project")
    }
    
    func withProject(callback: (Project?) -> Void) {
        
        let app = NSApplication.sharedApplication().delegate as! AppDelegate
        let fetchRequest = NSFetchRequest(entityName: "Project")
        if let fetchResults = (try? app.managedObjectContext.executeFetchRequest(fetchRequest)) as? [Project] {
            if (fetchResults.count > 0) {
                callback(fetchResults[0])
            }
            else {
                callback(nil)
           }
        }
        
    }
    
    func saveFolder(path: String, ext: String) {
        let app = NSApplication.sharedApplication().delegate as! AppDelegate
        let folder = NSEntityDescription.insertNewObjectForEntityForName("Folder", inManagedObjectContext: app.managedObjectContext) as! Folder
        folder.path = path
        folder.ext = ext
        save()
    }
    
    func deleteFolder() {
        deleteEntities("Folder")
    }
    
    func withFolder(callback: (Folder?) -> Void) {
        
        let app = NSApplication.sharedApplication().delegate as! AppDelegate
        let fetchRequest = NSFetchRequest(entityName: "Folder")
        if let fetchResults = (try? app.managedObjectContext.executeFetchRequest(fetchRequest)) as? [Folder] {
            if (fetchResults.count > 0) {
                callback(fetchResults[0])
            }
            else {
                callback(nil)
            }
        }
        
    }
    
}

