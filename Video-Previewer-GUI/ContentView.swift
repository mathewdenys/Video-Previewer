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

let almostBlack = Color(red: 0.2, green: 0.2, blue: 0.2, opacity: 1.0); // For text and shapes

let frameBorderWidth       = CGFloat(3.0)
let infoDescriptionWidth   = CGFloat(80)   // Width of the first column in the information blocks
let configDescriptionWidth = CGFloat(140)  // Width of the first column in the congiuation blocks

let frameWidth        = 200.0 // The width of the individual frames in the video preview
let previewPadding    = 15.0  // The padding around the frames in the video preview
let scrollBarWidth    = 15.0  // The width of a scrollbar in a ScrollView
let sidePanelMinWidth = 300.0 // The miniumum width of the side panel


/*----------------------------------------------------------------------------------------------------
    MARK: - GlobalVars
   ----------------------------------------------------------------------------------------------------*/

class GlobalVars: ObservableObject {    
    @Published var vp:            VideoPreviewWrapper = VideoPreviewWrapper("/Users/mathew/Library/Containers/mdenys.Video-Previewer-GUI/Data/sunrise.mov")
    @Published var frames:        [FrameWrapper?]?    = nil
    @Published var selectedFrame: FrameWrapper?       = nil
    
    // configUpdateCounter is incremented any time configuration options are updated in the GUI
    // It's actual value is not meaningful; all that matters is that it is @Published, so any View with a GlobalVars object will be updated
    // Further, arbitrary code can be run in its didSet{}
    @Published var configUpdateCounter: Int = 0 { didSet{ frames = vp.getFrames() } }
    
    init() {
        frames = vp.getFrames()
    }
}

/*----------------------------------------------------------------------------------------------------
    MARK: - ContentView
   ----------------------------------------------------------------------------------------------------*/

struct ContentView: View {
    @EnvironmentObject var globalVars: GlobalVars
    
    var body: some View {
        
        GeometryReader { geometry in
            // Determine a lower bound for the width of all the on-screen elements *except* the actual frames that are being previewed
            //  i.e. the width of the side panel + the width of a scrollbar on the side panel and on the preview pane + padding on each side of the preview
            let minWidthOfNonFrameElements: Double = sidePanelMinWidth + 2.0*scrollBarWidth + 2.0*previewPadding
            
            // Determine an upper bound for the width of the frames being previewed
            let widthOfWindow:     Double = Double(geometry.size.width)
            let maxWidthOfPreview: Double = widthOfWindow - minWidthOfNonFrameElements
            
            // Determine the number of frames per row given the current window size
            //  i.e. the maximum number of images of width `frameWidth` that can fit into an area with the width of the screen minus the width of all the non-frame elements
            let cols: Int = Int(maxWidthOfPreview / frameWidth)
            
            // Determine the number of rows required to display the frames
            let rows: Int = (globalVars.frames!.count / cols) + 1
            
            // Determine the actual width of the entire video preview pane
            // The width of the side panel will adjust to fill the remaining space, with a minimum width given by `sidePanelMinWidth`
            //  i.e. The width of the actual frames displayed + the scrollbar + padding on each side
            let previewWidth: Double = frameWidth*Double(cols) + scrollBarWidth + 2.0*previewPadding
            
            HStack(spacing:0) {
                PreviewPaneView(cols: cols, rows: rows)
                    .frame(width: CGFloat(previewWidth))
                SidePanelView()
            }
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
