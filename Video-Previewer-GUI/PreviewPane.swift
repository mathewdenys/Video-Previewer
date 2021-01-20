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
    let frame: FrameWrapper
    @State var isSelected = false
    
    var body: some View {
        ZStack(alignment: Alignment(horizontal: .trailing, vertical: .top)) {
            Image(nsImage: frame.getImage() ?? NSImage())
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: CGFloat(frameWidth))
                .border(isSelected ? Color.red : Color.white.opacity(0.0), width: frameBorderWidth)
            Text("\(frame.getFrameNumber())")
                .foregroundColor(Color.white)
                .padding(.all, 2.0)
                .background(Color(red:0, green:0, blue:0, opacity:0.2))
                .padding(.all, frameBorderWidth)
        }
        .onTapGesture {
            isSelected = !isSelected;
            print("frame \(frame.getFrameNumber()) is \(isSelected ? "" : "not") selected")
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
