//
//  AppDelegate.swift
//  Video-Previewer-GUI
//
//  Created by Mathew Denys on 13/01/21.
//

import Cocoa
import SwiftUI


@main
class AppDelegate: NSObject, NSApplicationDelegate {

    var globalVars = GlobalVars()
    
    var window:              NSWindow!
    var configurationWindow: NSWindow!
    
    /*------------------------------------------------------------
     MARK: - Menu bar
     ------------------------------------------------------------*/    
    
    @IBAction func openGithubReadme(_ sender: Any?) {
        if let url = URL(string: "https://github.com/mathewdenys/Video-Previewer/blob/master/README.md") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @IBAction func saveConfig(_ sender: Any?) {
        let dialog = NSSavePanel();

        dialog.title                   = "Save configuration options"
        dialog.message                 = "Preexisting configuration files associated with this video will be updated while\nmaintaining formatting. Any other file will be overwritten."
        dialog.nameFieldStringValue    = ".videopreviewconfig"
        dialog.canCreateDirectories    = true
        dialog.showsResizeIndicator    = true
        dialog.showsHiddenFiles        = true

        // User presses "save"
        if ( globalVars.vp == nil) {
            return
        }
        if (dialog.runModal() ==  NSApplication.ModalResponse.OK) {
            let result = dialog.url // Pathname of the file

            if (result != nil) {
                let path: String = result!.path
                globalVars.vp!.saveAllOptions(path)
            }
        }
    }
    
    @IBAction func openVideoFile(_ sender: Any?) {
        let dialog = NSOpenPanel();
        
        dialog.title                   = "Open a video to preview"
        dialog.showsResizeIndicator    = true
        dialog.showsHiddenFiles        = true

        // User presses "open"
        if (dialog.runModal() ==  NSApplication.ModalResponse.OK) {
            let result = dialog.url // Pathname of the file

            if (result != nil) {
                let path: String = result!.path
                
                globalVars.vp     = NSVideoPreview(path)
                globalVars.frames = globalVars.vp!.getFrames()
                
                // If no frames were loaded (probably because the file loaded was not a video)
                if (globalVars.frames!.count == 0)
                {
                    globalVars.vp = nil
                    
                    let alert = NSAlert.init()
                    alert.messageText = "Could not load frames from file"
                    alert.informativeText = "Please open a valid video file. Note that image files cannot be previewed."
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                    
                    return;
                }
                
                NSDocumentController.shared.noteNewRecentDocumentURL(URL(fileURLWithPath: path))
            }
        }
    }
    
    // Called when the user selects an item from the "Open Recent" menu
    // Return true  to keep the item in the menu, and false otherwise
    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        print(filename)
        globalVars.vp     = NSVideoPreview(filename)
        globalVars.frames = globalVars.vp!.getFrames()
        return true
    }
    
    // Adapted from https://stackoverflow.com/a/62780829
    @IBAction func openConfigurationWindow(_ sender: Any?) {
            if nil == configurationWindow {      // Only create once
                let configurationView = ConfigurationView().environmentObject(globalVars)
                // Create the preferences window and set content
                configurationWindow = NSWindow(
                    contentRect: NSRect(x: 20, y: 20, width: 480, height: 300),
                    styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                    backing: .buffered,
                    defer: false)
                configurationWindow.center()
                configurationWindow.setFrameAutosaveName("Preferences")
                configurationWindow.isReleasedWhenClosed = false
                configurationWindow.contentView = NSHostingView(rootView: configurationView)
                configurationWindow.title = "Configuration options"
            }
            configurationWindow.makeKeyAndOrderFront(nil)
        }
    

    /*------------------------------------------------------------
        MARK: - Launching and terminating application
     ------------------------------------------------------------*/
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        // Show an "open" panel on launch to choose the video to preview
        // Keep showing the panel until a valid video is loaded
        while (globalVars.vp == nil) {
            openVideoFile(nil)
        }
        
        // Create the SwiftUI view that provides the window contents
        let contentView = ContentView().environmentObject(globalVars)
            .frame(minWidth: 800, maxWidth: .infinity, minHeight: 500, maxHeight: .infinity)

        // Create the window and set the content view
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.center()
        window.setFrameAutosaveName("Main Window")
        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

