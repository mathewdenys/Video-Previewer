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
    var frames: [NSImage?]
    var rows, cols: Int
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView() {
                VStack(alignment:.leading){
                    ForEach(0..<rows) { i in
                        HStack(spacing: 0) {
                            ForEach(0..<cols) { j in
                                let index = i*cols + j
                                if (index < frames.count)
                                {
                                    Image(nsImage: frames[i*cols+j] ?? NSImage())
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 200.0)
                                }
                            }
                            Spacer()
                        }
                    }
                }
            }.hideIndicators()
        }
    }
    
    init(vp: VideoPreviewWrapper) {
        self.vp = vp
        self.vp.loadConfig()
        self.vp.loadVideo()
        self.vp.updatePreview()
        
        frames = vp.getFrames()
        cols = 5 // TODO: hard coded for now, but eventually this will be adaptive to the window size
        rows = (frames.count / cols) + 1
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
