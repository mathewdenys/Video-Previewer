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
            .frame(width: CGFloat(frameWidth))
    }
}


/*----------------------------------------------------------------------------------------------------
    MARK: - PreviewPaneView
   ----------------------------------------------------------------------------------------------------*/

struct PreviewPaneView: View {
    var frames: [NSImage?]
    let cols: Int
    let rows: Int
    
    var body: some View {
        ZStack {
            Color(red: 0.98, green: 0.98, blue: 0.98, opacity: 1.0).edgesIgnoringSafeArea(.all)
            VStack {
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
                    }.padding(.all, CGFloat(previewPadding))
                }
            }
        }
    }
}

//struct PreviewPane_Previews: PreviewProvider {
//    static var previews: some View {
//        PreviewPaneView()
//    }
//}
