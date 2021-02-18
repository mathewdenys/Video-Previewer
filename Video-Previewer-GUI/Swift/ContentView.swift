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
            // Whether frames_to_show is set to "auto" or not
            let autoFrameNumber : Bool = (globalVars.vp!.getOptionValue("frames_to_show")!.getString() != nil)
            
            // Determine the width and height of the window
            let widthOfWindow:    Double = Double(geometry.size.width)
            let heightOfWindow:   Double = Double(geometry.size.height)
            
            // Determine the width and height of the actual preview
            //  Width:  ignore the side panel and its scrollbar + the preview pane's scrollbar + padding around the preview
            //  Height: ignore the padding around the preview
            let widthOfPreview:   Double = widthOfWindow - sidePanelWidth - (autoFrameNumber ? 0.0 :scrollBarWidth) - 2.0*previewPadding
            let heightOfPreview:  Double = heightOfWindow - 2.0*previewPadding
            
            // Determine the maximum number of frames that can fit in the preview
            let frameSize:        Double = globalVars.vp!.getOptionValue("frame_size")!.getDouble()!.doubleValue
            let frameAspectRatio: Double = globalVars.vp!.getVideoAspectRatio().doubleValue
            let frameWidth:       Double = maxFrameWidth*frameSize + minFrameWidth*(1.0-frameSize)
            let frameHeight:      Double = Double(frameWidth/frameAspectRatio + previewVerticalSpacing)
            
            let maxCols:          Int    = Int(widthOfPreview  / Double(frameWidth))
            let maxRows:          Int    = Int((heightOfPreview + previewVerticalSpacing) / Double(frameHeight)) // Don't have padding on the bottom row
            var maxFrames:        Int    = maxCols * maxRows
            
            
            // If the frames_to_show option is set to "auto", we must tell the backend how many frames can fit in
            // the preview, generate the frames, and load them into the front end.
            let _ = Binding<Int> (
                get: {
                    if (autoFrameNumber && (maxRows != globalVars.vp!.getRows().intValue || maxCols != globalVars.vp!.getCols().intValue) )
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
                PreviewPaneView(cols: cols, rows: rows, showScrollbar: !autoFrameNumber)
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
