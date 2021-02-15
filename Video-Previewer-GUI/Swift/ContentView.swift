//
//  ContentView.swift
//  Video-Previewer-GUI
//
//  Created by Mathew Denys on 13/01/21.
//

import SwiftUI


struct ContentView: View {
    
    @EnvironmentObject
    private var globalVars: GlobalVars
    
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
            let Nframes:    Int = globalVars.frames!.count
            let frameWidth: Int = globalVars.vp!.getOptionValue("frame_width")!.getInt()!.intValue
            let cols:       Int = min(Int(widthOfPreview / Double(frameWidth)), Nframes)
            
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
