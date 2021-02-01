//
//  ContentView.swift
//  Video-Previewer-GUI
//
//  Created by Mathew Denys on 13/01/21.
//

import SwiftUI

/*----------------------------------------------------------------------------------------------------
    MARK: - Constants
   ----------------------------------------------------------------------------------------------------*/

let almostBlack            = Color(red: 0.2, green: 0.2, blue: 0.2, opacity: 1.0); // For text and shapes

let frameBorderWidth       = CGFloat(3.0)
let infoDescriptionWidth   = CGFloat(80)   // The width of the first column in the information blocks
let configDescriptionWidth = CGFloat(140)  // The width of the first column in the congiuation blocks

let frameWidth             = 200.0         // The width of the individual frames in the video preview
let previewPadding         = 15.0          // The padding around the frames in the video preview
let scrollBarWidth         = 15.0          // The width of a scrollbar in a ScrollView
let sidePanelWidth         = 400.0         // The miniumum width of the side panel

let pasteBoard             = NSPasteboard.general      // For copy-and-pasting

/*----------------------------------------------------------------------------------------------------
    MARK: - GlobalVars
   ----------------------------------------------------------------------------------------------------*/

class GlobalVars: ObservableObject {
    @Published var vp:            NSVideoPreview?    = nil
    @Published var frames:        [NSFramePreview?]? = nil
    @Published var selectedFrame: NSFramePreview?    = nil
    
    // configUpdateCounter is incremented any time configuration options are updated in the GUI
    // It's actual value is not meaningful; all that matters is that it is @Published, so any View with a GlobalVars object will be updated
    // Further, arbitrary code can be run in its didSet{}
    @Published var configUpdateCounter: Int = 0 { didSet{ frames = vp!.getFrames() } }
}

/*----------------------------------------------------------------------------------------------------
    MARK: - ContentView
   ----------------------------------------------------------------------------------------------------*/

struct ContentView: View {
    @EnvironmentObject var globalVars: GlobalVars
    
    var body: some View {
        
        if (globalVars.vp != nil) {
            GeometryReader { geometry in
                // Determine a lower bound for the width of all the on-screen elements *except* the actual frames that are being previewed
                //  i.e. the width of the side panel (includes its scrollbar) + the width of a scrollbar on the preview pane + padding on each side of the preview
                let widthOfNonPreviewElements: Double = sidePanelWidth + scrollBarWidth + 2.0*previewPadding
                
                // Determine an upper bound for the width of the frames being previewed
                let widthOfWindow:  Double = Double(geometry.size.width)
                let widthOfPreview: Double = widthOfWindow - widthOfNonPreviewElements
                
                // Determine the number of frames per row given the current window size
                //  i.e. the maximum number of images of width `frameWidth` that can fit into an area with the width of the screen minus the width of all the non-frame elements
                let Nframes: Int = globalVars.frames!.count
                let cols:    Int = min(Int(widthOfPreview / frameWidth), Nframes)
                
                // Determine the number of rows required to display the frames
                let rows: Int = (Nframes / cols) + 1
                
                // Determine the actual width of the entire video preview pane
                // The width of the side panel will adjust to fill the remaining space, with a minimum width given by `sidePanelMinWidth`
                //  i.e. The width of the actual frames displayed + the scrollbar + padding on each side
//                let previewWidth: Double = frameWidth*Double(cols) + scrollBarWidth + 2.0*previewPadding
                
                HStack(spacing:0) {
                    PreviewPaneView(cols: cols, rows: rows)
                    SidePanelView()
                        .frame(width: CGFloat(sidePanelWidth))
                }
            }
        } else {
            Button("Open...", action: {
                let dialog = NSOpenPanel();

                dialog.title                   = "Open a video to preview"
                
                dialog.showsResizeIndicator    = true
                dialog.showsHiddenFiles        = true

                // User presses "open"
                if (dialog.runModal() ==  NSApplication.ModalResponse.OK) {
                    let result = dialog.url // Pathname of the file

                    if (result != nil) {
                        let path: String = result!.path
                        globalVars.vp = NSVideoPreview(path)
                        globalVars.frames = globalVars.vp!.getFrames()
                        globalVars.configUpdateCounter += 1
                    }
                }
            } )
        }
        
        
        
        
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
