//
//  PreviewPane.swift
//  Video-Previewer-GUI
//
//  Created by Mathew Denys on 14/01/21.
//

import SwiftUI

/*----------------------------------------------------------------------------------------------------
    MARK: - Constants
   ----------------------------------------------------------------------------------------------------*/

let frameWidth     = CGFloat(200.0) // The width of each preview frame
let previewPadding = CGFloat(15.0)  // The padding around the video preview
let scrollBarWidth = CGFloat(15.0)  // Width of a scroll bar in a ScrollView


/*----------------------------------------------------------------------------------------------------
    MARK: - FramePreviewView
   ----------------------------------------------------------------------------------------------------*/

struct FramePreviewView: View {
    let image: NSImage
    
    var body: some View {
        Image(nsImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: frameWidth)
    }
}


/*----------------------------------------------------------------------------------------------------
    MARK: - FrameTableView
   ----------------------------------------------------------------------------------------------------*/

struct FrameTableView: View {
    let cols: Int
    let rows: Int
    var frames:  [NSImage?]
    
    var body: some View {
        ScrollView() {
            VStack(alignment:.leading){
                ForEach(0..<rows, id: \.self) { i in
                    HStack(spacing: 0) {
                        ForEach(0..<cols, id: \.self) { j in
                            let index = i*cols + j
                            if (index < frames.count)
                            {
                                FramePreviewView(image: frames[i*cols+j] ?? NSImage())
                            }
                        }
                        Spacer()
                    }
                }
            }.padding([.top, .leading, .bottom], previewPadding)
        }
    }
}


/*----------------------------------------------------------------------------------------------------
    MARK: - PreviewPaneView
   ----------------------------------------------------------------------------------------------------*/

struct PreviewPaneView: View {
    let vp: VideoPreviewWrapper
    var frames: [NSImage?]
    
    var body: some View {
        ZStack {
            Color(red: 0.98, green: 0.98, blue: 0.98, opacity: 1.0).edgesIgnoringSafeArea(.all)
            VStack {
                GeometryReader { geometry in
                    let c = Int(floor((geometry.size.width - scrollBarWidth - previewPadding) / frameWidth))
                    let r = (frames.count / c) + 1
                    
                    FrameTableView(cols: c, rows: r, frames: self.frames)
                }
                Spacer()
            }
        }
    }
    
    init(vp: VideoPreviewWrapper) {
        self.vp = vp
        self.vp.loadConfig()
        self.vp.loadVideo()
        self.vp.updatePreview()
        
        frames = vp.getFrames()
    }
}

struct PreviewPane_Previews: PreviewProvider {
    static var previews: some View {
        PreviewPaneView(vp: VideoPreviewWrapper("/Users/mathew/Library/Containers/mdenys.Video-Previewer-GUI/Data/sunrise.mov"))
    }
}
