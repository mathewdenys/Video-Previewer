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
    
    // The width of all on-screen elements except the frames that are being previewed
    // i.e. the side panel and its scrollbar + the preview pane's scrollbar + padding on each side of the preview
    private let widthOfNonPreviewElements: Double = sidePanelWidth + scrollBarWidth + 2.0*previewPadding
    
    var body: some View {
        
        GeometryReader { geometry in
            // Determine the width and height of the preview
            let widthOfWindow:    Double = Double(geometry.size.width)
            let widthOfPreview:   Double = widthOfWindow - widthOfNonPreviewElements
            let heightOfWindow:   Double = Double(geometry.size.height)
            let heightOfPreview:  Double = heightOfWindow - 2.0*previewPadding + previewVerticalSpacing
            
            // Determine the maximum number of frames that can fit in the preview
            let frameSize:        Double = globalVars.vp!.getOptionValue("frame_size")!.getDouble()!.doubleValue
            let frameAspectRatio: Double = globalVars.vp!.getVideoAspectRatio().doubleValue
            let frameWidth:       Double = maxFrameWidth*frameSize + minFrameWidth*(1.0-frameSize)
            let frameHeight:      Double = Double(frameWidth/frameAspectRatio + previewVerticalSpacing)
            
            let maxCols:          Int    = Int(widthOfPreview  / Double(frameWidth))
            let maxRows:          Int    = Int(heightOfPreview / Double(frameHeight)) // Don't need padding on the bottom row
            var maxFrames:        Int    = maxCols * maxRows
            
            // If the frames_to_show option is set to "auto", we must tell the backend how many frames can fit in
            // the preview, generate the frames, and load them into the front end.
            let _ = Binding<Int> (
                get: {
                    if (globalVars.vp!.getOptionValue("frames_to_show")!.getString() != nil &&
                        (maxRows != globalVars.vp!.getRows().intValue || maxCols != globalVars.vp!.getCols().intValue) )
                    {
                        globalVars.vp!.setCols(Int32(maxCols))         // Tell the backend how many columns of frames fit in the preview
                        globalVars.vp!.setRows(Int32(maxRows))         // Tell the backend how many rows of frames fit in the preview
                        globalVars.vp!.update()                        // Update the preview on the backend (i.e. generate the required frames)
                        globalVars.frames = globalVars.vp!.getFrames() // Load the frames into the frontend
                    }
                    return maxFrames
                },
                
                set: { return maxFrames = $0 }
            )
            
            // Determine the actual number of columns and rows given the actual number of frames
            let Nframes:          Int    = globalVars.frames!.count
            let cols:             Int    = min(maxCols, Nframes)
            let rows:             Int    = (Nframes / cols) + 1
            
            
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
