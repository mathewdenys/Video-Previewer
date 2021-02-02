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

// Colors are defined in Assets.xassets for light and dark themes
let colorBackground        = NSColor(named: NSColor.Name("colorBackground"))!
let colorOverlayForeground = Color(NSColor(named: NSColor.Name("colorOverlayForeground"))!)
let colorOverlayBackground = Color(NSColor(named: NSColor.Name("colorOverlayBackground"))!)
let colorBold              = Color(NSColor(named: NSColor.Name("colorBold"))!)
let colorFaded             = Color(NSColor(named: NSColor.Name("colorFaded"))!)
let colorInvisible         = Color(NSColor(named: NSColor.Name("colorInvisible"))!)

let frameBorderWidth       = CGFloat(3.0)
let infoDescriptionWidth   = CGFloat(100)  // The width of the first column in the information blocks
let configDescriptionWidth = CGFloat(140)  // The width of the first column in the congiuation blocks

let frameWidth             = 200.0         // The width of the individual frames in the video preview
let previewPadding         = 15.0          // The padding around the frames in the video preview
let scrollBarWidth         = 15.0          // The width of a scrollbar in a ScrollView
let sidePanelWidth         = 400.0         // The miniumum width of the side panel

let infoRowVPadding        = CGFloat(5.0)  // The vertical padding around the content of an InfoRowView
let configRowVPadding      = CGFloat(0.0)  // The vertical padding around the content of an ConfigRowView

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
            
            HStack(spacing:0) {
                PreviewPaneView(cols: cols, rows: rows)
                SidePanelView()
                    .frame(width: CGFloat(sidePanelWidth))
            }
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
