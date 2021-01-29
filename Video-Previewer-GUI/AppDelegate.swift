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
    var window: NSWindow!
    
    /*------------------------------------------------------------
     MARK: - Menu bar
     ------------------------------------------------------------*/    
    
    @IBAction func openGithubReadme(_ sender: NSMenuItem) {
        if let url = URL(string: "https://github.com/mathewdenys/Video-Previewer/blob/master/README.md") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @IBAction func saveConfig(_ sender: NSMenuItem) {
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
    
    @IBAction func openVideoFile(_ openMenuItem: NSMenuItem) {
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
            }
        }
    }
    

    /*------------------------------------------------------------
        MARK: - Launching and terminating application
     ------------------------------------------------------------*/
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Create the SwiftUI view that provides the window contents.
        let contentView = ContentView().environmentObject(globalVars)
            .frame(minWidth: 800, maxWidth: .infinity, minHeight: 500, maxHeight: .infinity)

        // Create the window and set the content view.
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

