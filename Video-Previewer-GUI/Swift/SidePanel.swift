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
    MARK: - String extension
   ----------------------------------------------------------------------------------------------------*/

extension String {
    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
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
    MARK: - InfoRowView
   ----------------------------------------------------------------------------------------------------*/

struct InfoRowView: View {
    
    private var id:      String
    private var value:   String
    private var tooltip: String
    
    // Default initializer
    init(id: String, value: String, tooltip: String) {
        self.id = id;
        self.value = value;
        self.tooltip = tooltip;
    }
    
    // Initializer without a tooltip
    init(id: String, value: String) {
        self.id = id;
        self.value = value;
        self.tooltip = "";
    }
    
    var body: some View {
        HStack(alignment: .top) {
            Text(id)
                .foregroundColor(colorFaded)
                .frame(width: infoDescriptionWidth, alignment: .trailing)
                .toolTip(tooltip)
            Text(value)
                .foregroundColor(colorBold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contextMenu {
                    Button("Copy", action: {
                        pasteBoard.clearContents()
                        pasteBoard.writeObjects([value as NSString])
                    })
                }
        }.padding(.vertical, infoRowVPadding)
        
    }
}


/*----------------------------------------------------------------------------------------------------
    MARK: - ConfigEditorBoolean
   ----------------------------------------------------------------------------------------------------*/

struct ConfigEditorBoolean: View {
    
    @EnvironmentObject
    private var globalVars: GlobalVars
    
    var option: NSOptionInformation
    
    var body: some View {
        
        let bindBool = Binding<Bool> (
            get: { globalVars.vp!.getOptionValue(option.getID())!.getBool()?.boolValue ?? false },
            set: { globalVars.vp!.setOptionValue(option.getID(), with: $0)
                           globalVars.configUpdateCounter += 1
                         }
                )
        
        Toggle("", isOn: bindBool)
            .frame(maxWidth: .infinity, alignment: .leading)
            .labelsHidden()
    }
}


/*----------------------------------------------------------------------------------------------------
    MARK: - ConfigEditorPositiveInteger
   ----------------------------------------------------------------------------------------------------*/

struct ConfigEditorPositiveInteger: View {
    
    @EnvironmentObject
    private var globalVars: GlobalVars
    
    var option: NSOptionInformation
    
    var body: some View {
        
        let bindInt = Binding<Int>(
            get: { globalVars.vp!.getOptionValue(option.getID())!.getInt()?.intValue ?? 0 },
            set: { var newValue = $0
                   if ($0 < 1) { newValue = 1 }   // An ePositiveInteger can't have a value less than 1
                globalVars.vp!.setOptionValue(option.getID(), with: Int32(newValue))
                   globalVars.configUpdateCounter += 1
                 }
        )
        
        TextField("", value: bindInt, formatter: NumberFormatter())
            .frame(maxWidth: .infinity, alignment: .leading)

        Stepper("", value: bindInt)
            .labelsHidden()
    }
}


/*----------------------------------------------------------------------------------------------------
    MARK: - ConfigEditorPositiveIntegerOrAuto
   ----------------------------------------------------------------------------------------------------*/

struct ConfigEditorPositiveIntegerOrAuto: View {
    
    @EnvironmentObject
    private var globalVars: GlobalVars
    
    var option: NSOptionInformation
    
    @State private var intValue: Int = 1
    
    var body: some View {
        
        let bindInt = Binding<Int>(
            get: { globalVars.vp!.getOptionValue(option.getID())!.getInt()?.intValue ?? intValue },
            set: { var newValue = Int32($0)
                   if (newValue < 1) { newValue = 1 } // An ePositiveInteger can't have a value less than 1
                   globalVars.vp!.setOptionValue(option.getID(), with: newValue)
                   globalVars.configUpdateCounter += 1
            }
        )
        
        let bindBool = Binding<Bool> (
            get: { return (globalVars.vp!.getOptionValue(option.getID())!.getString()) == nil ? false : true },
            set: {
                if ( $0 == true)  {                                                      // If "auto" is turned on
                    intValue = bindInt.wrappedValue                                      // Save the Int value (so that value is not lost when "auto" is turned off)
                    globalVars.vp!.setOptionValue(option.getID(), with: "auto")          // Set the option value to be "auto" in vp
                    
                }
                
                if ( $0 == false) {                                                      // If "auto" is turned off
                    globalVars.vp!.setOptionValue(option.getID(), with: Int32(intValue)) // Recover the Int value
                    
                }
                globalVars.configUpdateCounter += 1
            }
        )
        
        VStack {
            
            if !bindBool.wrappedValue
            {
                HStack {
                    TextField("", value: bindInt, formatter: NumberFormatter())
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Stepper("", value: bindInt)
                        .labelsHidden()
                }
            }
            
            Toggle("Automatic", isOn: bindBool)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}


/*----------------------------------------------------------------------------------------------------
    MARK: - ConfigEditorPositiveIntegerOrString
   ----------------------------------------------------------------------------------------------------*/

struct ConfigEditorPositiveIntegerOrString: View {
    
    @EnvironmentObject
    private var globalVars: GlobalVars
    
    var option: NSOptionInformation
    
    var body: some View {
        
        let bindInt = Binding<Int>(
            get: { globalVars.vp!.getOptionValue(option.getID())!.getInt()?.intValue ?? 0 },
            set: { var newValue = $0
                   if ($0 < 1) { newValue = 1 }   // An ePositiveInteger can't have a value less than 1
                   globalVars.vp!.setOptionValue(option.getID(), with: Int32(newValue))
                   globalVars.configUpdateCounter += 1
                 }
        )
        
        let bindString = Binding<String>(
            get: { globalVars.vp!.getOptionValue(option.getID())!.getString() ?? "" },
            set: { globalVars.vp!.setOptionValue(option.getID(), with: $0)
                   globalVars.configUpdateCounter += 1
                 }
        )
        
        TextField("", value: bindInt, formatter: NumberFormatter())
            .frame(maxWidth: .infinity, alignment: .leading)

        Stepper("", value: bindInt)
            .labelsHidden()

        Picker("",selection: bindString) {
            ForEach(option.getValidStrings(), id: \.self) { string in Text(string) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .labelsHidden()
    }
}


/*----------------------------------------------------------------------------------------------------
    MARK: - ConfigEditorPercentage
   ----------------------------------------------------------------------------------------------------*/

struct ConfigEditorPercentage: View {
    
    @EnvironmentObject
    private var globalVars: GlobalVars
    
    var option: NSOptionInformation
    
    var body: some View {
        
        let bindInt = Binding<Int>(
            get: { globalVars.vp!.getOptionValue(option.getID())!.getInt()?.intValue ?? 0 },
            set: { var newValue = $0
                   if ($0 < 1)   { newValue = 1 }   // An ePercentage can't have a value less than 1
                   if ($0 > 100) { newValue = 100 } // An ePercentage can't have a value greater than 100
                globalVars.vp!.setOptionValue(option.getID(), with: Int32(newValue))
                   globalVars.configUpdateCounter += 1
                 }
        )
        
        TextField("", value: bindInt, formatter: NumberFormatter())
            .frame(maxWidth: .infinity, alignment: .leading)

        Stepper("", value: bindInt)
            .labelsHidden()
    }
}


/*----------------------------------------------------------------------------------------------------
    MARK: - ConfigEditorDecimal
   ----------------------------------------------------------------------------------------------------*/

struct ConfigEditorDecimal: View {
    
    @EnvironmentObject
    private var globalVars: GlobalVars
    
    var option: NSOptionInformation
    
    var body: some View {
        
        let bindDouble = Binding<Double>(
            get: { globalVars.vp!.getOptionValue(option.getID())!.getDouble()?.doubleValue ?? 0.0 },
            set: { globalVars.vp!.setOptionValue(option.getID(), with: Double($0))
                   globalVars.configUpdateCounter += 1
                 }
        )
        
        Slider(value: bindDouble, in: 0...1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, -10)
    }
}


/*----------------------------------------------------------------------------------------------------
    MARK: - ConfigEditorDecimalOrAuto
   ----------------------------------------------------------------------------------------------------*/

struct ConfigEditorDecimalOrAuto: View {
    
    @EnvironmentObject
    private var globalVars: GlobalVars
    
    var option: NSOptionInformation
    
    @State private var doubleValue: Double = 0.0
    
    var body: some View {
        
        let bindDouble = Binding<Double>(
            get: { globalVars.vp!.getOptionValue(option.getID())!.getDouble()?.doubleValue ?? doubleValue },
            set: { globalVars.vp!.setOptionValue(option.getID(), with: Double($0))
                   globalVars.configUpdateCounter += 1
                 }
        )
        
        let bindBool = Binding<Bool> (
            get: { return (globalVars.vp!.getOptionValue(option.getID())!.getString()) == nil ? false : true },
            set: {
                if ($0 == true) {                                                    // If "auto" is turned on
                    doubleValue = bindDouble.wrappedValue                            // Save the Double value (so that value is not lost when "auto" is turned off)
                    globalVars.vp!.setOptionValue(option.getID(), with: "auto");     // Set the option value to be "auto" in vp
                }
                
                if ($0 == false) {                                                   // If "auto" is turned off
                    globalVars.vp!.setOptionValue(option.getID(), with: doubleValue) // Recover the Double value
                }
                
                globalVars.configUpdateCounter += 1
            }
        )
        
        VStack {
            if !bindBool.wrappedValue
            {
                Slider(value: bindDouble, in: 0...1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, -10)
            }
            
            Toggle("Automatic", isOn: bindBool)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}


/*----------------------------------------------------------------------------------------------------
    MARK: - ConfigEditorString
   ----------------------------------------------------------------------------------------------------*/

struct ConfigEditorString: View {
    
    @EnvironmentObject
    private var globalVars: GlobalVars
    
    var option: NSOptionInformation
    
    var body: some View {
        
        let bindString = Binding<String>(
            get: { globalVars.vp!.getOptionValue(option.getID())!.getString() ?? "" },
            set: { globalVars.vp!.setOptionValue(option.getID(), with: $0)
                   globalVars.configUpdateCounter += 1
                 }
        )
        
        Picker("", selection: bindString) {
            ForEach(option.getValidStrings(), id: \.self) { string in Text(string) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .labelsHidden()
    }
}


/*----------------------------------------------------------------------------------------------------
    MARK: - ConfigRowView
        A ConfigRowView is displayed for each recognised configuration option
        A different display is defined for each possible value of OptionInformation.getValidValues()
   ----------------------------------------------------------------------------------------------------*/

struct ConfigRowView: View {
    
    @EnvironmentObject
    private var globalVars: GlobalVars
    
    let option: NSOptionInformation
    
    var body: some View {
        
        HStack(alignment: .top) {
            // Left hand column: option name
            Text(option.getID().capitalizingFirstLetter().replacingOccurrences(of: "_", with: " "))
                .foregroundColor(colorFaded)
                .frame(width: configDescriptionWidth, alignment: .trailing)
                .toolTip(option.getDescription())
                .contextMenu {
                    Button("Copy id", action: {
                        pasteBoard.clearContents()
                        pasteBoard.writeObjects([option.getID() as NSString])
                    })
                    Button("Copy value", action: {
                        pasteBoard.clearContents()
                        pasteBoard.writeObjects([globalVars.vp!.getOptionValueString(option.getID()) as NSString])
                    })
                    Button("Copy configuration string", action: {
                        pasteBoard.clearContents()
                        pasteBoard.writeObjects([globalVars.vp!.getOptionConfigString(option.getID()) as NSString])
                    })
                }
            
            // Right hand column: editable option value
            switch option.getValidValues() {
            
                case NSValidOptionValue.eBoolean:
                    ConfigEditorBoolean(option: option)
                    
                case NSValidOptionValue.ePositiveInteger:
                    ConfigEditorPositiveInteger(option: option)
                    
                case NSValidOptionValue.ePositiveIntegerOrAuto:
                    ConfigEditorPositiveIntegerOrAuto(option: option)
                    
                case NSValidOptionValue.ePositiveIntegerOrString:
                    ConfigEditorPositiveIntegerOrString(option: option)
                    
                case NSValidOptionValue.ePercentage:
                    ConfigEditorPercentage(option: option)
                    
                case NSValidOptionValue.eDecimal:
                    ConfigEditorDecimal(option: option)
                    
                case NSValidOptionValue.eDecimalOrAuto:
                    ConfigEditorDecimalOrAuto(option: option)
                    
                case NSValidOptionValue.eString:
                    ConfigEditorString(option: option)

                default:
                    Spacer()
            }
        }
        .padding(.vertical, configRowVPadding)
        .foregroundColor(colorBold)
    }
}


/*----------------------------------------------------------------------------------------------------
    MARK: - CollapsibleBlockView
   ----------------------------------------------------------------------------------------------------*/

struct CollapsibleBlockView<Content: View>: View {
    
    @EnvironmentObject
    private var globalVars: GlobalVars
    
    @State
    private var isExpanded = true
    
    private var expandedByDefault = true
    
    private let title:              String
    private let collapsibleContent: Content

    // Initialise with a title and content
    init(title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.collapsibleContent = content()
    }
    
    // Initialise with a title, content, and an expandedByDefault bool. expandedByDefault determines the
    // value of isExapnded when the view appears. Unfortunately, because collpsibleContent is shown
    // conditionally on the valyeof isExpanded, the value of isExapnded cannot be set directly in the
    // initialiser, but mustbe set in an .onAppear() instead.
    init(title: String, expandedByDefault: Bool, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.expandedByDefault = expandedByDefault
        self.collapsibleContent = content()
    }
    
    var body: some View {
        VStack {
            HStack {
                Text(title)
                    .fontWeight(.bold)
                    .foregroundColor(colorBold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Triangle()
                    .rotation(Angle(degrees: isExpanded ? 180 : 90))
                    .fill(colorBold)
                    .frame(width: 9, height: 6)
            }
            .background(colorInvisible) // Hackey way of making the whole HStack clickable
            .onTapGesture { isExpanded = !isExpanded; }
            
            if isExpanded { collapsibleContent }
        }
        .padding(.horizontal)
        .onAppear(perform: {isExpanded = expandedByDefault})
    }
}


/*----------------------------------------------------------------------------------------------------
    MARK: - BasicConfigBlockView
        This view displays just the "basic" configuration options. It is displayed in the side panel
        and in the configuration options window.
   ----------------------------------------------------------------------------------------------------*/

struct BasicConfigBlockView: View {
    
    @EnvironmentObject
    private var globalVars: GlobalVars
    
    let title:              String
    let expandedByDefault:  Bool
    
    var body: some View {
    
        CollapsibleBlockView(title: self.title, expandedByDefault: self.expandedByDefault) {
            ConfigRowView(option: globalVars.vp!.getOptionInformation("frames_to_show")!)
            ConfigRowView(option: globalVars.vp!.getOptionInformation("frame_size")!)
            ConfigRowView(option: globalVars.vp!.getOptionInformation("action_on_hover")!)
            ConfigRowView(option: globalVars.vp!.getOptionInformation("overlay_timestamp")!)
            ConfigRowView(option: globalVars.vp!.getOptionInformation("overlay_number")!)
        }
    }
}


/*----------------------------------------------------------------------------------------------------
    MARK: - SidePanelView
   ----------------------------------------------------------------------------------------------------*/

struct SidePanelView: View {
    
    @EnvironmentObject
    private var globalVars: GlobalVars
    
    var body: some View {
        HStack(spacing:0) {
            
            Divider()
            
            GeometryReader { geometry in
                ScrollView {
                    VStack(alignment: .leading) {
                        CollapsibleBlockView(title: "Video Information") {
                            HStack{
                                InfoRowView(id: "File path",   value: globalVars.vp!.getVideoNameString())
                                Button(action: { NSWorkspace.shared.openFile(globalVars.vp!.getVideoNameString()) }) {
                                    Image(nsImage: NSImage(imageLiteralResourceName: NSImage.followLinkFreestandingTemplateName))
                                }.buttonStyle(BorderlessButtonStyle())
                            }
                            InfoRowView(id: "Encoding",    value: globalVars.vp!.getVideoCodecString())
                            InfoRowView(id: "Frame rate",  value: globalVars.vp!.getVideoFPSString())
                            InfoRowView(id: "Length",      value: globalVars.vp!.getVideoLengthString())
                            InfoRowView(id: "# of frames", value: globalVars.vp!.getVideoNumOfFramesString())
                            InfoRowView(id: "Dimensions",  value: globalVars.vp!.getVideoDimensionsString())
                        }
                        
                        Divider()
                        
                        CollapsibleBlockView(title: "Frame Information") {
                            if (globalVars.selectedFrame == nil) {
                                Text("No frame selected")
                                    .foregroundColor(colorFaded)
                            } else {
                                InfoRowView(id: "Time stamp", value: globalVars.selectedFrame == nil ? "-" : globalVars.selectedFrame!.getTimeStampString()     )
                                InfoRowView(id: "Frame #",    value: globalVars.selectedFrame == nil ? "-" : String(globalVars.selectedFrame!.getFrameNumber()) )
                            }
                        }
                        
                        Spacer()
                        
                        Divider()
                        
                        BasicConfigBlockView(title: "Configuration Options", expandedByDefault: true)
                        
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
