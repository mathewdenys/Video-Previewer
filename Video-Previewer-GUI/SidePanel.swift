//
//  SidePanel.swift
//  Video-Previewer-GUI
//
//  Created by Mathew Denys on 13/01/21.
//

import SwiftUI

/*----------------------------------------------------------------------------------------------------
    MARK: - Tooltip
        - From: https://stackoverflow.com/questions/63217860/how-to-add-tooltip-on-macos-10-15-with-swiftui
   ----------------------------------------------------------------------------------------------------*/
struct Tooltip: NSViewRepresentable {
    let tooltip: String
    
    func makeNSView(context: NSViewRepresentableContext<Tooltip>) -> NSView {
        let view = NSView()
        view.toolTip = tooltip

        return view
    }
    
    func updateNSView(_ nsView: NSView, context: NSViewRepresentableContext<Tooltip>) { }
}

public extension View {
    func toolTip(_ toolTip: String) -> some View {
        self.overlay(Tooltip(tooltip: toolTip))
    }
}


/*----------------------------------------------------------------------------------------------------
    MARK: - InfoPair
   ----------------------------------------------------------------------------------------------------*/

struct InfoPair: Identifiable {
    var id:      String;
    var value:   String;
    var tooltip: String;
    
    // Default initializer
    init(id: String, value: String, tooltip: String) {
        self.id = id;
        self.value = value;
        self.tooltip = tooltip;
    }
    
    // Initializer for InfoPair without a tooltip
    init(id: String, value: String) {
        self.id = id;
        self.value = value;
        self.tooltip = "";
    }
}


/*----------------------------------------------------------------------------------------------------
    MARK: - InfoRowView
   ----------------------------------------------------------------------------------------------------*/

struct InfoRowView: View, Identifiable {
    var id:      String
    var value:   String
    var tooltip: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(id)
                .foregroundColor(Color.gray)
                .frame(width: 120, alignment: .trailing)
                .toolTip(tooltip)
            Text(value)
                .foregroundColor(almostBlack)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    init(info: InfoPair) {
        id      = info.id;
        value   = info.value;
        tooltip = info.tooltip;
    }
}


/*----------------------------------------------------------------------------------------------------
    MARK: - Triangle
   ----------------------------------------------------------------------------------------------------*/

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))

        return path
    }
}


/*----------------------------------------------------------------------------------------------------
    MARK: - InfoBlockView
   ----------------------------------------------------------------------------------------------------*/

struct InfoBlockView: View {
    var title: String;
    var info:  [InfoPair];
    
    @State private var isExpanded = true;
    
    var body: some View {
        VStack {
            HStack {
                Text(title)
                    .fontWeight(.bold)
                    .foregroundColor(almostBlack)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Triangle()
                    .rotation(Angle(degrees: isExpanded ? 0 : 180))
                    .fill(almostBlack)
                    .frame(width: 9, height: 6)
            }
            .padding(.horizontal)
            .background(Color(red: 1.0, green: 1.0, blue: 1.0, opacity: 0.01)) // Hackey way of making the whole HStack clickable
            .onTapGesture { isExpanded = !isExpanded; }
            
            if isExpanded {
                ForEach(info) { i in InfoRowView(info: i) }
                    .padding(.horizontal, 30.0)
                    .padding(.vertical, 5.0)
            }
        }
    }
}



/*----------------------------------------------------------------------------------------------------
    MARK: - ConfigBlockView
   ----------------------------------------------------------------------------------------------------*/

struct ConfigBlockView: View {
    var title: String;
    var vp:    VideoPreviewWrapper;
    
    @State private var isExpanded = true;
    
    var body: some View {
        VStack {
            HStack {
                Text(title)
                    .fontWeight(.bold)
                    .foregroundColor(almostBlack)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Triangle()
                    .rotation(Angle(degrees: isExpanded ? 180 : 0))
                    .fill(almostBlack)
                    .frame(width: 9, height: 6)
            }
            .padding(.horizontal)
            .background(Color(red: 1.0, green: 1.0, blue: 1.0, opacity: 0.01)) // Hackey way of making the whole HStack clickable (FIX)
            .onTapGesture { isExpanded = !isExpanded; }
            
            if isExpanded {
                ForEach(vp.getOptionInformation(), id: \.self){ option in
                    InfoRowView(info: InfoPair(id: option.getID(),
                            value: vp.getOptionValueString(option.getID()),
                            tooltip: option.getDescription()))
                    }
                    .padding(.horizontal, 30.0)
                    .padding(.vertical, 5.0)
                HStack(alignment: .center) {
                    Button("Save", action: doNothing)
                    Button("Export", action: doNothing)
                }
                .padding(.horizontal)
            }
        }
    }
}

func doNothing() { }


/*----------------------------------------------------------------------------------------------------
    MARK: - SidePanelView
   ----------------------------------------------------------------------------------------------------*/

struct SidePanelView: View {
    @EnvironmentObject var globalVars: GlobalVars
    var vp: VideoPreviewWrapper
    
    var body: some View {
        HStack(spacing:0) {
            Divider()
            
            GeometryReader { geometry in
                ScrollView {
                    VStack(alignment: .leading) {
                        InfoBlockView(title: "Video Information", info:
                            [
                                InfoPair(id: "File path",   value: vp.getVideoNameString()),
                                InfoPair(id: "Encoding",    value: vp.getVideoCodecString()),
                                InfoPair(id: "Frame rate",  value: vp.getVideoFPSString()),
                                InfoPair(id: "Length",      value: vp.getVideoLengthString()),
                                InfoPair(id: "# of frames", value: vp.getVideoNumOfFramesString()),
                                InfoPair(id: "Dimensions",  value: vp.getVideoDimensionsString()),
                            ]
                        )
                        Divider()
                        InfoBlockView(title: "Frame Information",     info:
                            [
                                InfoPair(id: "Frame #",    value: globalVars.selectedFrame == nil ? "-" : String(globalVars.selectedFrame!.getFrameNumber()) ),
                                InfoPair(id: "Time stamp", value: globalVars.selectedFrame == nil ? "-" : globalVars.selectedFrame!.getTimeStampString()     ),
                            ]
                        )
                        Spacer()
                        Divider()
                        ConfigBlockView(title: "Configuration Options", vp: self.vp)
                    }
                    .padding(.vertical, 10.0)
                    .frame(minHeight: geometry.size.height) // Inside the GeometryReader, this keeps the ConfigInfoBlock at the bottom (by default the Spacer() does nothing in a ScrollView)
                }
            }
        }
    }
}

struct SidePanel_Previews: PreviewProvider {
    static var previews: some View {
        SidePanelView(vp: VideoPreviewWrapper("/Users/mathew/Library/Containers/mdenys.Video-Previewer-GUI/Data/sunrise.mov"))
            .frame(minWidth: 200, maxWidth: 250) // copy from ContentView.swift
    }
}
