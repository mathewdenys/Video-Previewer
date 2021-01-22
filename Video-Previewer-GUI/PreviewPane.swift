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
    @EnvironmentObject var globalVars: GlobalVars
    let frame: FrameWrapper
    
    var body: some View {
        ZStack(alignment: Alignment(horizontal: .trailing, vertical: .top)) {
            Image(nsImage: frame.getImage() ?? NSImage())
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: CGFloat(frameWidth))
                .border(frame.getFrameNumber() == globalVars.selectedFrame?.getFrameNumber() ? Color.red : Color.white.opacity(0.0), width: frameBorderWidth)
            
            if let b = globalVars.vp.getOptionValue("show_frame_info")?.getBool() {
                if (b.boolValue) {
                    Text("\(frame.getFrameNumber())")
                        .foregroundColor(Color.white)
                        .padding(.all, 2.0)
                        .background(Color(red:0, green:0, blue:0, opacity:0.2))
                        .padding(.all, frameBorderWidth)
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
    @EnvironmentObject var globalVars: GlobalVars
    let cols: Int
    let rows: Int
    
    var body: some View {
        ZStack {
            Color(red: 0.98, green: 0.98, blue: 0.98, opacity: 1.0).edgesIgnoringSafeArea(.all)
            ScrollView() {
                VStack(alignment:.leading){
                    ForEach(0..<rows, id: \.self) { i in
                        HStack(spacing: 0) {
                            ForEach(0..<cols, id: \.self) { j in
                                let index = i*cols + j
                                if (index < globalVars.frames!.count)
                                {
                                    FramePreviewView(frame: globalVars.frames![index]!)
                                }
                            }
                            Spacer()
                        }
                    }
                }.padding([.vertical,.leading], CGFloat(previewPadding)) // No need to pad the RHS because the size of the view takes that into account
            }
        }
    }
}

//struct PreviewPane_Previews: PreviewProvider {
//    static var previews: some View {
//        PreviewPaneView()
//    }
//}
