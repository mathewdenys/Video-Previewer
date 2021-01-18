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
    let image: NSImage
    
    var body: some View {
        Image(nsImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 200.0)
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
            }
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
                    let c = Int(floor(geometry.size.width / 200))
                    let r = (frames.count / c) + 1
                    
                    FrameTableView(cols: c, rows: r, frames: self.frames)
                }
                Spacer()
            }.padding(.all)
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
