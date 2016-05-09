//
//  ViewController.swift
//  BlenderSequenceRenderTool
//
//  Created by Paul Hamilton on 27/04/2016.
//  Copyright © 2016 Paul Hamilton. All rights reserved.
//

import Cocoa
import AppKit

class ViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, Messages {

    @IBOutlet var usernameField: NSTextField!
    @IBOutlet var passwordField: NSSecureTextField!
    @IBOutlet var projectField: NSPopUpButton!
    @IBOutlet var hostField: NSTextField!
    @IBOutlet var folderField: NSTextField!
    @IBOutlet var extensionField: NSTextField!
    @IBOutlet var working: NSProgressIndicator!
    @IBOutlet var startButton: NSButton!
    @IBOutlet var stopButton: NSButton!
    @IBOutlet var serverBox: NSBox!
    @IBOutlet var settingsBox: NSBox!
    @IBOutlet var runningBox: NSBox!
    @IBOutlet var toolsBox: NSBox!
    @IBOutlet var masterBox: NSBox!
    @IBOutlet var slaveBox: NSBox!
    @IBOutlet var roleBox: NSBox!
    @IBOutlet var standaloneButton: NSButton!
    @IBOutlet var masterButton: NSButton!
    @IBOutlet var slaveButton: NSButton!
    @IBOutlet var tableView: NSTableView!
    
    var source:dispatch_source_t?
    var files = Set<String>()
    var projects: [NSDictionary]?
    var messages: Array<String> = Array<String>()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.working.hidden = true
        
        enableBox(self.runningBox, flag: false)
        enableBox(self.masterBox, flag: false)
        enableBox(self.slaveBox, flag: false)
        enableBox(self.settingsBox, flag: false)
        enableBox(self.roleBox, flag: false)
        
        self.usernameField.stringValue = BE.get().getUsername()
        self.passwordField.stringValue = BE.get().getPassword()

        withProject() { project in
            
            self.withFolder() { folder in
                
                self.projectField.removeAllItems()
                if let p = project {
                    self.projectField.addItemWithTitle(p.name!)
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

    // Messages protocol
    func add(msg: String) {
        self.addMsg(msg)
    }
    
    func addMsg(msg: String) {
        let timestamp = NSDateFormatter.localizedStringFromDate(NSDate(), dateStyle: .MediumStyle, timeStyle: .ShortStyle)
        dispatch_async(dispatch_get_main_queue()) {
            () -> Void in
            self.messages.append("\(timestamp): \(msg)")
            self.tableView.reloadData()
        }
    }
    
    @IBAction func master(sender: AnyObject) {
        self.standaloneButton.enabled = true
        self.masterButton.enabled = false
        self.slaveButton.enabled = true
        self.enableBox(self.slaveBox, flag: true)
        self.enableBox(self.toolsBox, flag: false)
        self.enableBox(self.runningBox, flag: true)
        self.enableBox(self.masterBox, flag: true)
        startListening()
    }
    
    @IBAction func slave(sender: AnyObject) {
        self.standaloneButton.enabled = true
        self.masterButton.enabled = true
        self.slaveButton.enabled = false
        self.enableBox(self.slaveBox, flag: false)
        self.enableBox(self.toolsBox, flag: false)
        self.enableBox(self.runningBox, flag: false)
        self.enableBox(self.masterBox, flag: false)
        startListening()
    }
    
    @IBAction func standalone(sender: AnyObject) {
        self.standaloneButton.enabled = false
        self.masterButton.enabled = true
        self.slaveButton.enabled = true
        self.enableBox(self.slaveBox, flag: true)
        self.enableBox(self.toolsBox, flag: true)
        self.enableBox(self.runningBox, flag: true)
        self.enableBox(self.masterBox, flag: true)
    }
    
    @IBAction func login(sender: AnyObject) {
        
        self.working.startAnimation(self)
        self.working.hidden = false
        
        BE.get().loginUser(usernameField.stringValue, password: passwordField.stringValue, errorHandler: AlertUtils.defaultErrorHandler(self)) {
            
            BE.get().getJSONObject("users/me", query: "", errorHandler: AlertUtils.defaultErrorHandler(self)) { (user: NSDictionary) -> Void in
                
                BE.get().getJSONData("projects", query: "", errorHandler: AlertUtils.defaultErrorHandler(self)) { (projects: [NSDictionary]) -> Void in
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        () -> Void in
                        
                        self.working.stopAnimation(self)
                        self.working.hidden = true
                        self.enableBox(self.serverBox, flag: false)
                        self.enableBox(self.runningBox, flag: true)
                        self.enableBox(self.masterBox, flag: true)
                        self.enableBox(self.slaveBox, flag: true)
                        self.enableBox(self.settingsBox, flag: true)
                        self.enableBox(self.roleBox, flag: true)
                        self.stopButton.enabled = false
                        self.standaloneButton.enabled = false
                        self.projects = projects
                        
                        let sel = self.projectField.titleOfSelectedItem
                        self.projectField.removeAllItems()
                        for p in projects {
                            self.projectField.addItemWithTitle(p["name"] as! String)
                        }
                        if (sel != nil) {
                            self.projectField.selectItemWithTitle(sel!)
                        }
                   }
                    
                }
                
            }
            
        }
        
    }
    
    private func startListening() {
        
        if (self.source != nil) {
            return
        }
        
        let scene:SceneFolder = SceneFolder(messages: self, project: self.getProjectId(self.projectField.titleOfSelectedItem!)!, parent: self.folderField.stringValue, host: self.hostField.stringValue, ext: self.extensionField.stringValue, errorHandler: AlertUtils.defaultErrorHandler(self))
        
        BE.get().getSocket().on("progress") { data, ack in
            
            let d = data[0] as? NSDictionary
            let frames = d!["frames"] as! String
            let fa = frames.componentsSeparatedByString(",")
            let ws = NSCharacterSet.whitespaceAndNewlineCharacterSet()
            for f in fa {
                let fr = f.stringByTrimmingCharactersInSet(ws)
                if (!scene.frameFileExists(fr)) {
                    scene.createEmptyFrameFile(fr)
                }
            }
            
        }
        
        BE.get().getSocket().on("command") { data, ack in
            
            let d = data[0] as? NSDictionary
            let name = d!["name"] as! String
            self.addMsg("received command \(name)")
            if (name == "start") {
                self.startTracking()
            }
            else if (name == "stop") {
                self.stopTracking()
            }
            else if (name == "uploadFrames") {
                scene.doUploadFrames()
            }
            else if (name == "downloadScene") {
                scene.doDownloadScene()
            }
        }
        
        BE.get().getSocket().on("id") {data, ack in
            let data: AnyObject = [
                "id": self.getProjectId(self.projectField.titleOfSelectedItem!)!, "initials": "", "userid": ""
            ]
            BE.get().getSocket().emit("openDocument", data)
        }
        
        BE.get().getSocket().connect()

    }
    
    private func stopListening() {
        if (self.source != nil) {
            dispatch_source_cancel(self.source!)
            self.source = nil
        }
    }
    
    private func startTracking() {
        
        let scene:SceneFolder = SceneFolder(messages: self, project: self.getProjectId(self.projectField.titleOfSelectedItem!)!, parent: self.folderField.stringValue, host: self.hostField.stringValue, ext: self.extensionField.stringValue, errorHandler: AlertUtils.defaultErrorHandler(self))
        
        commitFields()
        deleteServerFrames() {
            
            self.files = scene.collectAllFrameFiles()
            if (self.files.count > 0) {
                scene.uploadFrames(self.files) {
                    self.watchFolder()
                }
            }
            else {
                self.watchFolder()
            }
        }
        
    }
    
    @IBAction func start(sender: AnyObject) {
        
        if (self.masterButton.enabled == false) {
            sendCommand("start")
        }
        
        self.stopButton.enabled = true
        self.startButton.enabled = false
        self.enableBox(self.settingsBox, flag: false)
        self.enableBox(self.masterBox, flag: false)
        self.enableBox(self.slaveBox, flag: false)
        self.enableBox(self.toolsBox, flag: false)
        
        startTracking()
        
        if (self.standaloneButton.enabled == false) {
            startListening()
        }
        
    }
    
    private func stopTracking() {
        // we don't actually do anything.
    }
    
    @IBAction func stop(sender: AnyObject) {
        
        if (self.masterButton.enabled == false) {
            sendCommand("stop")
        }
        
        self.stopButton.enabled = false
        self.startButton.enabled = true
        self.enableBox(self.settingsBox, flag: true)
        self.enableBox(self.masterBox, flag: true)
        self.enableBox(self.slaveBox, flag: true)
        self.enableBox(self.toolsBox, flag: true)
        
        stopTracking()
        
        if (self.standaloneButton.enabled == false) {
            stopListening()
        }
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
    
    @IBAction func deleteEmptyFrames(sender: AnyObject) {
        let scene:SceneFolder = SceneFolder(messages: self, project: self.getProjectId(self.projectField.titleOfSelectedItem!)!, parent: self.folderField.stringValue, host: self.hostField.stringValue, ext: self.extensionField.stringValue, errorHandler: AlertUtils.defaultErrorHandler(self))
        
        scene.deleteEmptyFrameFiles()
    }
    
    @IBAction func deleteAllFrames(sender: AnyObject) {

        let scene:SceneFolder = SceneFolder(messages: self, project: self.getProjectId(self.projectField.titleOfSelectedItem!)!, parent: self.folderField.stringValue, host: self.hostField.stringValue, ext: self.extensionField.stringValue, errorHandler: AlertUtils.defaultErrorHandler(self))
        
        confirm("Are you sure?", description: "All the frames will be permanently deleted.") {
            scene.deleteAllFrameFiles()
        }
        
    }
    
    @IBAction func uploadScene(sender: AnyObject) {

        let scene:SceneFolder = SceneFolder(messages: self, project: self.getProjectId(self.projectField.titleOfSelectedItem!)!, parent: self.folderField.stringValue, host: self.hostField.stringValue, ext: self.extensionField.stringValue, errorHandler: AlertUtils.defaultErrorHandler(self))
        
        confirm("Are you sure?", description: "All local frames and blender backups will be deleted before the scene file is zipped and uploaded.") {
            
            scene.doUploadScene()
            
        }

    }
    
    @IBAction func downloadScene(sender: AnyObject) {

        let scene:SceneFolder = SceneFolder(messages: self, project: self.getProjectId(self.projectField.titleOfSelectedItem!)!, parent: self.folderField.stringValue, host: self.hostField.stringValue, ext: self.extensionField.stringValue, errorHandler: AlertUtils.defaultErrorHandler(self))
        
        if (self.masterButton.enabled == false) {
            sendCommand("downloadScene")
        }
        else {
            confirm("Are you sure?", description: "All the local frames will be permanently deleted.") {
                scene.doDownloadScene()
            }
        }
    }
    
    @IBAction func uploadFrames(sender: AnyObject) {

        let scene:SceneFolder = SceneFolder(messages: self, project: self.getProjectId(self.projectField.titleOfSelectedItem!)!, parent: self.folderField.stringValue, host: self.hostField.stringValue, ext: self.extensionField.stringValue, errorHandler: AlertUtils.defaultErrorHandler(self))
        
        if (self.masterButton.enabled == false) {
            sendCommand("uploadFrames")
        }
        else {
            scene.doUploadFrames()
        }
    }
    
    @IBAction func downloadAllFrames(sender: AnyObject) {
        
        let scene:SceneFolder = SceneFolder(messages: self, project: self.getProjectId(self.projectField.titleOfSelectedItem!)!, parent: self.folderField.stringValue, host: self.hostField.stringValue, ext: self.extensionField.stringValue, errorHandler: AlertUtils.defaultErrorHandler(self))
        
        scene.deleteEmptyFrameFiles()
        
        let project = self.getProjectId(self.projectField.titleOfSelectedItem!)!
        BE.get().getJSONData("projects/\(project)/media", query: "", errorHandler: AlertUtils.defaultErrorHandler(self)) { (media: [NSDictionary]) -> Void in
            for m in media {
                let name = m["name"] as! String
                if (name.rangeOfString(".* Frames", options: .RegularExpressionSearch) != nil) {
                    let id = m["_id"] as! String
                    scene.downloadAndUnzip(id, folder: self.folderField.stringValue, file: "frames.tgz")
                }
            }
        }
    }
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return self.messages.count ?? 0
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        if let cell = tableView.makeViewWithIdentifier("TextCellID", owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = self.messages[row]
            return cell
        }
        
        return nil
    }
    
    private func sendCommand(cmd: String) {
        
        var post: Dictionary<String, String> = Dictionary<String, String>()
        post["name"] = cmd
        post["project"] = self.getProjectId(self.projectField.titleOfSelectedItem!)!
       
        BE.get().postJSONData("command", query: "", data: post, errorHandler: AlertUtils.defaultErrorHandler(self)) { (d) -> Void in
            self.addMsg("sent \(cmd).")
        }
    }
    
    private func enableBox(box: NSBox, flag: Bool) {
        
        for sub in box.subviews {
            for v in sub.subviews {
                let sel = Selector("setEnabled:")
                if (v.respondsToSelector(sel)) {
                    let method: Method
                    method = class_getInstanceMethod(v.dynamicType, sel)
                    let implementation = method_getImplementation(method)
                    typealias Function = @convention(c) (AnyObject, Selector, Bool) -> Void
                    let function = unsafeBitCast(implementation, Function.self)
                    function(v, sel, flag)
                }
            }
        }
    }
    
    private func getProject(name: String) -> NSDictionary? {
        if let projects = self.projects {
            for p in projects {
                let name = p["name"] as! String
                if (name == projectField.titleOfSelectedItem) {
                    return p
                }
            }
        }
        return nil
    }
    
    private func getProjectId(name: String) -> String? {
        return getProject(name)!["_id"] as? String
    }
    
    private func commitFields() {
        deleteProject()
        if let project = getProject(projectField.titleOfSelectedItem!) {
            saveProject(project["_id"] as! String, name: projectField.titleOfSelectedItem!)
        }
        deleteFolder()
        saveFolder(self.folderField.stringValue, ext: self.extensionField.stringValue)
    }
    
    private func confirm(msg: String, description: String, callback: () -> Void) {
        
        let dlg: NSAlert = NSAlert()
        dlg.messageText = msg
        dlg.informativeText = description
        dlg.alertStyle = NSAlertStyle.WarningAlertStyle
        dlg.addButtonWithTitle("OK")
        dlg.addButtonWithTitle("Cancel")
        let res = dlg.runModal()
        if res == NSAlertFirstButtonReturn {
            callback()
        }
        
    }
        
    private func deleteServerFrames(callback: () -> Void) {
        
        let project = self.getProjectId(self.projectField.titleOfSelectedItem!)
        BE.get().deleteJSONData("progress", query: "?project=\(project!)&host=\(self.hostField.stringValue)", errorHandler: AlertUtils.defaultErrorHandler(self)) { (d) -> Void in
            
            callback()
            
        }
        
    }
    
    private func watchFolder() {
        
        let scene:SceneFolder = SceneFolder(messages: self, project: self.getProjectId(self.projectField.titleOfSelectedItem!)!, parent: self.folderField.stringValue, host: self.hostField.stringValue, ext: self.extensionField.stringValue, errorHandler: AlertUtils.defaultErrorHandler(self))
        
        let folder = open(scene.getFramesPath(), O_RDONLY)
        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        self.source = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, UInt(folder), DISPATCH_VNODE_WRITE, queue)
        
        dispatch_source_set_event_handler(self.source!, {
            let newfiles = scene.collectAllFrameFiles()
            let diff = newfiles.subtract(self.files)
            if (diff.count > 0) {
                
                scene.uploadFrames(diff) {
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        () -> Void in
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
    
    private func saveProject(id: String, name: String) {
        let app = NSApplication.sharedApplication().delegate as! AppDelegate
        let project = NSEntityDescription.insertNewObjectForEntityForName("Project", inManagedObjectContext: app.managedObjectContext) as! Project
        project.id = id
        project.name = name
        save()
    }
    
    private func deleteProject() {
        deleteEntities("Project")
    }
    
    private func withProject(callback: (Project?) -> Void) {
        
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
    
    private func saveFolder(path: String, ext: String) {
        let app = NSApplication.sharedApplication().delegate as! AppDelegate
        let folder = NSEntityDescription.insertNewObjectForEntityForName("Folder", inManagedObjectContext: app.managedObjectContext) as! Folder
        folder.path = path
        folder.ext = ext
        save()
    }
    
    private func deleteFolder() {
        deleteEntities("Folder")
    }
    
    private func withFolder(callback: (Folder?) -> Void) {
        
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

