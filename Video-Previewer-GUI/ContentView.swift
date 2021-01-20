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

let frameBorderWidth  = CGFloat(3.0)

let frameWidth        = 200.0 // The width of the individual frames in the video preview
let previewPadding    = 15.0  // The padding around the frames in the video preview
let scrollBarWidth    = 15.0  // The width of a scrollbar in a ScrollView
let sidePanelMinWidth = 300.0 // The miniumum width of the side panel


/*----------------------------------------------------------------------------------------------------
    MARK: - ContentView
   ----------------------------------------------------------------------------------------------------*/

struct ContentView: View {
    let vp = VideoPreviewWrapper("/Users/mathew/Library/Containers/mdenys.Video-Previewer-GUI/Data/sunrise.mov")
    var frames: [FrameWrapper?]
    
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
            let rows: Int = (frames.count / cols) + 1
            
            // Determine the actual width of the entire video preview pane
            // The width of the side panel will adjust to fill the remaining space, with a minimum width given by `sidePanelMinWidth`
            //  i.e. The width of the actual frames displayed + the scrollbar + padding on each side
            let previewWidth: Double = frameWidth*Double(cols) + scrollBarWidth + 2.0*previewPadding
            
            HStack(spacing:0) {
                PreviewPaneView(frames: self.frames, cols: cols, rows: rows)
                    .frame(width: CGFloat(previewWidth))
                SidePanelView(vp: self.vp!)
            }
        }
    }
    
    init() {
        vp!.loadConfig()
        vp!.loadVideo()
        vp!.updatePreview()
        
        frames = vp!.getFrames()
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
