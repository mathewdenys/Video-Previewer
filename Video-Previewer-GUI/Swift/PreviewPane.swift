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
    
    @EnvironmentObject
    private var globalVars: GlobalVars
    
    private let frame: NSFramePreview
    
    init(frame: NSFramePreview) { self.frame = frame }
    
    var body: some View {
        ZStack(alignment: Alignment(horizontal: .trailing, vertical: .top)) {
            Image(nsImage: frame.getImage() ?? NSImage())
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: CGFloat(frameWidth))
                .border(frame.getFrameNumber() == globalVars.selectedFrame?.getFrameNumber() ? Color.red : Color.white.opacity(0.0), width: frameBorderWidth)
            
            if let s = globalVars.vp!.getOptionValue("frame_info_overlay")?.getString() {
                VStack(alignment: .trailing) {
                    if (s == "both" || s == "timestamp") {
                        Text(frame.getTimeStampString())
                            .foregroundColor(colorOverlayForeground)
                            .padding(.all, 2.0)
                            .background(colorOverlayBackground)
                            .padding(.all, frameBorderWidth)
                    }
                    
                    if (s == "both" || s == "number") {
                        Text("\(frame.getFrameNumber())")
                            .foregroundColor(colorOverlayForeground)
                            .padding(.all, 2.0)
                            .background(colorOverlayBackground)
                            .padding(.all, frameBorderWidth)
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
    
    @EnvironmentObject
    private var globalVars: GlobalVars
    
    private let cols: Int
    private let rows: Int
    
    init(cols: Int, rows: Int) {
        self.cols = cols
        self.rows = rows
    }
    
    var body: some View {
        ZStack {
            Color(colorBackground).edgesIgnoringSafeArea(.all)
            
            ScrollView {
                HStack(alignment: .center) {
                    Spacer()
                    VStack(alignment:.center){
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
