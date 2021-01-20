//
//  PreviewPane.swift
//  Video-Previewer-GUI
//
//  Created by Mathew Denys on 14/01/21.
//

import SwiftUI

/*----------------------------------------------------------------------------------------------------
    MARK: - SelectedFrame
   ----------------------------------------------------------------------------------------------------*/

class SelectedFrame: ObservableObject {
    @Published var frame: FrameWrapper? = nil
}


/*----------------------------------------------------------------------------------------------------
    MARK: - FramePreviewView
   ----------------------------------------------------------------------------------------------------*/

struct FramePreviewView: View {
    @EnvironmentObject var selectedFrame: SelectedFrame
    let frame: FrameWrapper
    
    var body: some View {
        ZStack(alignment: Alignment(horizontal: .trailing, vertical: .top)) {
            Image(nsImage: frame.getImage() ?? NSImage())
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: CGFloat(frameWidth))
                .border(frame.getFrameNumber() == selectedFrame.frame?.getFrameNumber() ? Color.red : Color.white.opacity(0.0), width: frameBorderWidth)
            Text("\(frame.getFrameNumber())")
                .foregroundColor(Color.white)
                .padding(.all, 2.0)
                .background(Color(red:0, green:0, blue:0, opacity:0.2))
                .padding(.all, frameBorderWidth)
        }
        .onTapGesture {
            if (selectedFrame.frame != nil && selectedFrame.frame?.getFrameNumber() == frame.getFrameNumber()) {
                selectedFrame.frame = nil      // If this frame is selected
                return
            }
            selectedFrame.frame = self.frame  // If either no frame or a different frame is selected
        }
    }
}


/*----------------------------------------------------------------------------------------------------
    MARK: - PreviewPaneView
   ----------------------------------------------------------------------------------------------------*/

struct PreviewPaneView: View {
    var frames: [FrameWrapper?]
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
                                            FramePreviewView(frame: frames[index]!)
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
