//
//  PreviewPane.swift
//  Video-Previewer-GUI
//
//  Created by Mathew Denys on 14/01/21.
//

import SwiftUI


struct FramePreview: View {
    
    var image: NSImage
    
    var body: some View {
        Image(nsImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 200.0)
    }
}

struct VideoPreview: View {
    
    var vp: VideoPreviewWrapper
    
    var body: some View {
        VStack{
            HStack(spacing:0) {
                FramePreview(image: vp.getFirstFrame() ?? NSImage())
                FramePreview(image: vp.getFirstFrame() ?? NSImage())
                FramePreview(image: vp.getFirstFrame() ?? NSImage())
                FramePreview(image: vp.getFirstFrame() ?? NSImage())
            }
            HStack(spacing:0) {
                FramePreview(image: vp.getFirstFrame() ?? NSImage())
                FramePreview(image: vp.getFirstFrame() ?? NSImage())
                FramePreview(image: vp.getFirstFrame() ?? NSImage())
                FramePreview(image: vp.getFirstFrame() ?? NSImage())
            }
            HStack(spacing:0) {
                FramePreview(image: vp.getFirstFrame() ?? NSImage())
                FramePreview(image: vp.getFirstFrame() ?? NSImage())
                FramePreview(image: vp.getFirstFrame() ?? NSImage())
                FramePreview(image: vp.getFirstFrame() ?? NSImage())
            }
        }
    }
    
    init(vp: VideoPreviewWrapper) {
        self.vp = vp
        self.vp.loadConfig()
        self.vp.loadVideo()
        self.vp.updatePreview()
    }
}



struct PreviewPane: View {
    
    var vp: VideoPreviewWrapper
    
    var body: some View {
        ZStack {
            Color(red: 0.98, green: 0.98, blue: 0.98, opacity: 1.0).edgesIgnoringSafeArea(.all)
            VStack {
                VideoPreview(vp: self.vp)
                Spacer()
            }
            .padding(.all)
        }
    }
}

struct PreviewPane_Previews: PreviewProvider {
    static var previews: some View {
        PreviewPane(vp: VideoPreviewWrapper("/Users/mathew/Library/Containers/mdenys.Video-Previewer-GUI/Data/sunrise.mov"))
    }
}
