//
//  PreviewPane.swift
//  Video-Previewer-GUI
//
//  Created by Mathew Denys on 14/01/21.
//

import SwiftUI


/*----------------------------------------------------------------------------------------------------
    MARK: - FramePreviewView
   ----------------------------------------------------------------------------------------------------*/

struct FramePreviewView: View {
    
    @EnvironmentObject private var globalVars: GlobalVars
    @EnvironmentObject private var settings:   UserSettings
    
    private let frame: NSFramePreview
    
    init(frame: NSFramePreview) { self.frame = frame }
    
    var body: some View {
        
        let frameSize:  Double = globalVars.vp!.getOptionValue("frame_size")!.getDouble()!.doubleValue
        let frameWidth: Double = maxFrameWidth*frameSize + minFrameWidth*(1.0-frameSize)
        
        ZStack(alignment: Alignment(horizontal: .trailing, vertical: .top)) {
            Image(nsImage: frame.getImage() ?? NSImage())
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: CGFloat(frameWidth))
                .border(frame.getFrameNumber() == globalVars.selectedFrame?.getFrameNumber() ? Color(settings.frameBorderColor) : Color.white.opacity(0.0), width: CGFloat(settings.frameBorderThickness))
            
            VStack(alignment: .trailing) {
                if let showNumber = globalVars.vp!.getOptionValue("overlay_timestamp")?.getBool() {
                    if (showNumber.boolValue) {
                        Text("\(frame.getTimeStampString())")
                            .font(fontRegular)
                            .foregroundColor(colorOverlayForeground)
                            .padding(.all, 2.0)
                            .background(colorOverlayBackground)
                            .padding(.all, CGFloat(settings.frameBorderThickness))
                    }
                }
                
                if let showNumber = globalVars.vp!.getOptionValue("overlay_number")?.getBool() {
                    if (showNumber.boolValue) {
                        Text("\(frame.getFrameNumber())")
                            .font(fontRegular)
                            .foregroundColor(colorOverlayForeground)
                            .padding(.all, 2.0)
                            .background(colorOverlayBackground)
                            .padding(.all, CGFloat(settings.frameBorderThickness))
                    }
                }
            }
        }
        .onTapGesture {
            if (globalVars.selectedFrame != nil && globalVars.selectedFrame?.getFrameNumber() == frame.getFrameNumber()) {
                globalVars.selectedFrame = nil      // If this frame is selected
                return
            }
            globalVars.selectedFrame = self.frame  // If either no frame or a different frame is selected
        }
    }
}


/*----------------------------------------------------------------------------------------------------
    MARK: - PreviewPaneView
   ----------------------------------------------------------------------------------------------------*/

struct PreviewPaneView: View {
    
    @EnvironmentObject private var globalVars: GlobalVars
    @EnvironmentObject private var settings:   UserSettings
    
    let cols:          Int
    let rows:          Int
    let showScrollbar: Bool
    
    var body: some View {
        ZStack {
            Color(colorBackground).edgesIgnoringSafeArea(.all)
            
            ScrollView(showsIndicators: showScrollbar) {
                
                let frameSize:  Double = globalVars.vp!.getOptionValue("frame_size")!.getDouble()!.doubleValue
                let frameWidth: Double = maxFrameWidth*frameSize + minFrameWidth*(1.0-frameSize)
                
                HStack(alignment: .center) {
                    Spacer()
                    VStack(alignment:.center, spacing: CGFloat(settings.previewSpaceBetweenRows)){
                        ForEach(0..<rows, id: \.self) { i in
                            HStack(spacing: 0) {
                                ForEach(0..<cols, id: \.self) { j in
                                    let index = i*cols + j
                                    if (index < globalVars.frames!.count) {
                                        FramePreviewView(frame: globalVars.frames![index]!)
                                    } else {
                                        Spacer().frame(width: CGFloat(frameWidth))
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
