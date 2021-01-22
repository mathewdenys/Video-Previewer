//
//  SidePanel.swift
//  Video-Previewer-GUI
//
//  Created by Mathew Denys on 13/01/21.
//

import SwiftUI

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
    MARK: - NumbersOnly
        - See: https://programmingwithswift.com/numbers-only-textfield-with-swiftui/
   ----------------------------------------------------------------------------------------------------*/

class NumbersOnly: ObservableObject {
    @Published var value = "" {
        didSet {
            let filtered = value.filter { $0.isNumber }
            
            if value != filtered {
                value = filtered
            }
        }
    }
}


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
                .foregroundColor(.gray)
                .frame(width: infoDescriptionWidth, alignment: .trailing)
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
    MARK: - InfoBlockView
   ----------------------------------------------------------------------------------------------------*/

struct InfoBlockView: View {
    @EnvironmentObject var globalVars: GlobalVars
    var title: String;
    var info:  [InfoPair];
    var displaysFrameInfo = false
    
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
                if (displaysFrameInfo && globalVars.selectedFrame == nil) {
                    Text("No frame selected")
                        .foregroundColor(.gray)
                } else {
                ForEach(info) { i in InfoRowView(info: i) }
                    .padding(.horizontal, 30.0)
                    .padding(.vertical, 5.0)
                }
            }
        }
    }
}


/*----------------------------------------------------------------------------------------------------
    MARK: - ConfigRowView
   ----------------------------------------------------------------------------------------------------*/

struct ConfigRowView: View, Identifiable {
    @EnvironmentObject var globalVars: GlobalVars
    var id:           String
    var tooltip:      String
    let valueType:    String
    let validStrings: Array<String>
    
    @ObservedObject var input = NumbersOnly()
    @State var selection = "temp..."
    @State var temp = false
    
    var body: some View {
        HStack(alignment: .top) {
            Text(id)
                .foregroundColor(.gray)
                .frame(width: configDescriptionWidth, alignment: .trailing)
                .toolTip(tooltip)
            
            // To work on: input methods for each config option, but they don't actually interact with the C++ code yet
            switch valueType {
            case "boolean":
                Toggle("", isOn: $temp)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .labelsHidden()
                
            case "positiveInteger":
                TextField("Input", text: $input.value)
                    .foregroundColor(almostBlack)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
            case "string":
                Picker("",selection: $selection) {
                    ForEach(validStrings, id: \.self) { string in
                            Text(string)
                        }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .labelsHidden()
            
            default:
                Text("Unknown")
                    .foregroundColor(almostBlack)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    
    init(id: String, tooltip: String, valueType: String, validStrings: Array<String>) {
        self.id = id
        self.tooltip = tooltip
        self.valueType = valueType
        self.validStrings = validStrings
    }
}


/*----------------------------------------------------------------------------------------------------
    MARK: - ConfigBlockView
   ----------------------------------------------------------------------------------------------------*/

struct ConfigBlockView: View {
    @EnvironmentObject var globalVars: GlobalVars
    var title: String;
    
    @State private var isExpanded = true;
    
    func setOptionTest(ID: String, val: Bool)
    {
        globalVars.vp.setOptionValue(ID, with: true)
    }
    
    
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
                ForEach(globalVars.vp.getOptionInformation(), id: \.self) { option in
                    ConfigRowView(id: option.getID(),tooltip: option.getDescription(), valueType: option.getValidValues(), validStrings: option.getValidStrings() )
                    }
                    .padding(.horizontal, 30.0)
                    .padding(.vertical, 5.0)
                
                // Temporary: button that actually sends input to the C++ code
                Button(action: {
                        setOptionTest(ID: "show_frame_info", val: true)
                }) {
                    Text("Update show_frame_info")
                }
                
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
    
    var body: some View {
        HStack(spacing:0) {
            Divider()
            
            GeometryReader { geometry in
                ScrollView {
                    VStack(alignment: .leading) {
                        InfoBlockView(title: "Video Information", info:
                            [
                                InfoPair(id: "File path",   value: globalVars.vp.getVideoNameString()),
                                InfoPair(id: "Encoding",    value: globalVars.vp.getVideoCodecString()),
                                InfoPair(id: "Frame rate",  value: globalVars.vp.getVideoFPSString()),
                                InfoPair(id: "Length",      value: globalVars.vp.getVideoLengthString()),
                                InfoPair(id: "# of frames", value: globalVars.vp.getVideoNumOfFramesString()),
                                InfoPair(id: "Dimensions",  value: globalVars.vp.getVideoDimensionsString()),
                            ]
                        )
                        Divider()
                        InfoBlockView(title: "Frame Information",     info:
                            [
                                InfoPair(id: "Frame #",    value: globalVars.selectedFrame == nil ? "-" : String(globalVars.selectedFrame!.getFrameNumber()) ),
                                InfoPair(id: "Time stamp", value: globalVars.selectedFrame == nil ? "-" : globalVars.selectedFrame!.getTimeStampString()     ),
                            ],
                                      displaysFrameInfo: true
                        )
                        Spacer()
                        Divider()
                        ConfigBlockView(title: "Configuration Options")
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
        SidePanelView()
            .frame(minWidth: 200, maxWidth: 250) // copy from ContentView.swift
    }
}
