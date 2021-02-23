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

    private let preview  = PreviewData()
    private let settings = UserSettings()
    
    private var previewWindow:     NSWindow!
    private var preferencesWindow: NSWindow!
    
    
    // Open an open dialogue for selecting a video file to preview
    @IBAction func showOpenDialogue(_ sender: Any?) {
        let dialog = NSOpenPanel();
        
        dialog.title                   = "Open a video to preview"
        dialog.showsResizeIndicator    = true
        dialog.showsHiddenFiles        = true
        dialog.allowedFileTypes        = ["public.movie"] // Only allow user to open files conforming to public.movie UTI
        
        // The following loop runs indefinitely until the "break" condition inside is reached (or
        // the user presses the "Cancel" button. In practice the loop only runs once unless the
        // user opens an invalid file, whch is (very) unlikely because dialog.allowedFileTypes
        // has been set. Note that dialog.runModal() displays an open dialogue, and returns
        // NSApplication.ModalResponse.OK when the user selects a file
        while (dialog.runModal() ==  NSApplication.ModalResponse.OK)
        {
            if let result = dialog.url // Pathname of the file
            {
                let path   = result.path
                let vp     = NSVideoPreview(path)
                let frames = vp!.getFrames()
                
                // The following code runs if an array of frames was successfully imported
                if (frames!.count != 0)
                {
                    preview.backend = vp
                    preview.frames = frames
                    
                    NSDocumentController.shared.noteNewRecentDocumentURL(URL(fileURLWithPath: path))
                    showPreviewWindow(fileName: result.lastPathComponent)
                    break
                }
                
                // The following code only runs if no frames were loaded (probably because the file loaded was not a video)
                let alert = NSAlert.init()
                alert.messageText = "Could not load frames from file"
                alert.informativeText = "Please open a valid video file. Note that image files cannot be previewed."
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
        }
    }
    
    // Called when the user selects an item from the "Open Recent" menu
    func application(_ sender: NSApplication, openFile filePath: String) -> Bool {
        print(filePath)
        preview.backend  = NSVideoPreview(filePath)
        preview.frames   = preview.backend!.getFrames()
        showPreviewWindow(fileName: URL(fileURLWithPath: filePath).lastPathComponent)
        return true // Return true to keep the item in the menu
    }
    
    // Setup and then display a window containing a ContentView
    func showPreviewWindow(fileName: String) {
        // Only create the window once
        if previewWindow == nil
        {
            // Create an instance of the ContentView
            let contentView = ContentView()
                .environmentObject(preview)
                .environmentObject(settings)
                .frame(minWidth: 800, maxWidth: .infinity, minHeight: 500, maxHeight: .infinity)

            // Create the window and set the content
            previewWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
                styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                backing: .buffered, defer: false)
            previewWindow.isReleasedWhenClosed = false
            previewWindow.center()
            previewWindow.setFrameAutosaveName("Main Window")
            previewWindow.tabbingMode = .disallowed
            previewWindow.contentView = NSHostingView(rootView: contentView)
        }
        
        // Name the window
        previewWindow.title = fileName
        
        // Clear the selected frame (in the case that a frame is selected when the user opens a new file)
        preview.selectedFrame = nil
        
        // Show the window
        previewWindow.makeKeyAndOrderFront(nil)
    }
    
    // Setup and then display a window containing a PreferencesView
    @IBAction func showPreferencesWindow(_ sender: Any?) {
        // Only create the window once
        if preferencesWindow == nil
        {
            // Create an instance of the PreferencesView
            let preferencesView = PreferencesView()
                .environmentObject(preview)
                .environmentObject(settings)
            
            // Create the window and set the content
            preferencesWindow = NSWindow(
                contentRect: NSRect(x: 20, y: 20, width: 480, height: 300),
                styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                backing: .buffered,
                defer: false)
            preferencesWindow.center()
            preferencesWindow.setFrameAutosaveName("Preferences")
            preferencesWindow.title = "Preferences"
            preferencesWindow.isReleasedWhenClosed = false
            preferencesWindow.contentView = NSHostingView(rootView: preferencesView)
        }
        
        // Show the window
        preferencesWindow.makeKeyAndOrderFront(nil)
    }
    
    // Open a save dialogue for exporting configuration options
    @IBAction func saveConfig(_ sender: Any?) {
        let dialog = NSSavePanel();

        dialog.title                   = "Save configuration options"
        dialog.message                 = "Preexisting configuration files associated with this video will be updated while\nmaintaining formatting. Any other file will be overwritten."
        dialog.nameFieldStringValue    = ".videopreviewconfig"
        dialog.canCreateDirectories    = true
        dialog.showsResizeIndicator    = true
        dialog.showsHiddenFiles        = true

        // If no video is loaded for previewing
        if ( preview.backend == nil) {
            return
        }
        
        // User presses "save"
        if (dialog.runModal() ==  NSApplication.ModalResponse.OK) {
            let result = dialog.url // Pathname of the file

            if let path: String = result?.path {
                preview.backend!.saveAllOptions(path)
            }
        }
    }
    
    // Open the README on GitHub
    @IBAction func openReadme(_ sender: Any?) {
        if let url = URL(string: "https://github.com/mathewdenys/Video-Previewer/blob/master/README.md") {
            NSWorkspace.shared.open(url)
        }
    }

    // Called when the application finishes launching
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        showOpenDialogue(nil)
    }

}

