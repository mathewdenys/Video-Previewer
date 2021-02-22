//
//  PreviewPane.swift
//  Video-Previewer-GUI
//
//  Created by Mathew Denys on 14/01/21.
//

import SwiftUI


/*----------------------------------------------------------------------------------------------------
    MARK: - FramePreviewView
        Dislaying a single frame in the preview
   ----------------------------------------------------------------------------------------------------*/

struct FramePreviewView: View {
    
    @EnvironmentObject private var preview:  PreviewData
    @EnvironmentObject private var settings: UserSettings
    
    let frame: NSFramePreview
    
    var body: some View {
        
        let frameSize:  Double = preview.backend!.getOptionValue("frame_size")!.getDouble()!.doubleValue
        let frameWidth: Double = maxFrameWidth*frameSize + minFrameWidth*(1.0-frameSize)
        
        ZStack(alignment: Alignment(horizontal: .trailing, vertical: .top)) {
            Image(nsImage: frame.getImage() ?? NSImage())
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: CGFloat(frameWidth))
                .border(frame.getFrameNumber() == preview.selectedFrame?.getFrameNumber() ? Color(settings.frameBorderColor) : Color.clear, width: CGFloat(settings.frameBorderThickness))
            
            VStack(alignment: .trailing) {
                let showTimestamp = preview.backend!.getOptionValue("overlay_timestamp")!.getBool()
                let showNumber    = preview.backend!.getOptionValue("overlay_number")!.getBool()
                
                if (showTimestamp != nil && showTimestamp!.boolValue) {
                    Text("\(frame.getTimeStampString())")
                        .regularFont()
                        .foregroundColor(colorOverlayForeground)
                        .padding(.all, 2.0)
                        .background(colorOverlayBackground)
                        .padding([.top, .trailing], CGFloat(settings.frameBorderThickness))
                }
                
                if (showNumber != nil && showNumber!.boolValue) {
                    Text("\(frame.getFrameNumber())")
                        .regularFont()
                        .foregroundColor(colorOverlayForeground)
                        .padding(.all, 2.0)
                        .background(colorOverlayBackground)
                        .padding(.trailing, CGFloat(settings.frameBorderThickness))
                        .padding(.top, (showTimestamp != nil && showTimestamp!.boolValue) ? 3 : CGFloat(settings.frameBorderThickness))
                }
            }
        }
        .onTapGesture {
            if (preview.selectedFrame != nil && preview.selectedFrame?.getFrameNumber() == frame.getFrameNumber()) {
                preview.selectedFrame = nil      // If this frame is selected
                return
            }
            preview.selectedFrame = self.frame  // If either no frame or a different frame is selected
        }
    }
}


/*----------------------------------------------------------------------------------------------------
    MARK: - PreviewPaneView
   ----------------------------------------------------------------------------------------------------*/

struct PreviewPaneView: View {
    
    @EnvironmentObject private var preview:  PreviewData
    @EnvironmentObject private var settings: UserSettings
    
    let cols:          Int
    let rows:          Int
    let showScrollbar: Bool
    
    var body: some View {
        ZStack {
            colorBackground.edgesIgnoringSafeArea(.all)
            
            ScrollView(showsIndicators: showScrollbar) {
                
                let frameSize:  Double = preview.backend!.getOptionValue("frame_size")!.getDouble()!.doubleValue
                let frameWidth: Double = maxFrameWidth*frameSize + minFrameWidth*(1.0-frameSize)
                
                HStack(alignment: .center) {
                    Spacer()
                    VStack(alignment:.center, spacing: CGFloat(settings.previewSpaceBetweenRows)){
                        ForEach(0..<rows, id: \.self) { i in
                            HStack(spacing: 0) {
                                ForEach(0..<cols, id: \.self) { j in
                                    let index = i*cols + j
                                    if (index < preview.frames!.count) {
                                        FramePreviewView(frame: preview.frames![index]!)
                                            .padding(.trailing, (j == (cols-1) ? 0 : CGFloat(settings.previewSpaceBetweenCols))) // Spacing between each column (don't put after the last column)
                                    } else {
                                        Spacer().frame(width: CGFloat(frameWidth))
                                            .padding(.trailing, (j == (cols-1) ? 0 : CGFloat(settings.previewSpaceBetweenCols))) // Spacing between each column (don't put after the last column)
                                    }
                                }
                            }
                        }
                    }.padding([.vertical], CGFloat(previewPadding)) // No need to pad horizontally because the width of the view takes that into account
                    Spacer()
                }
            }
        }
    }
}
