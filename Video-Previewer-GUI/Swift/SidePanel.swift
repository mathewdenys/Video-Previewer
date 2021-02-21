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
        HStack(alignment: .top, spacing: horiontalRowSpacing) {
            Text(id)
                .font(fontRegular)
                .foregroundColor(colorFaded)
                .frame(width: infoDescriptionWidth, alignment: .trailing)
                .toolTip(tooltip)
            Text(value)
                .font(fontRegular)
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
    MARK: - ConfigIDText
   ----------------------------------------------------------------------------------------------------*/

struct ConfigIDText: View {
    
    @EnvironmentObject
    private var globalVars: GlobalVars
    
    var option: NSOptionInformation
    
    var body: some View {
        Text(option.getID().capitalizingFirstLetter().replacingOccurrences(of: "_", with: " "))
            .font(fontRegular)
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
        
        HStack(spacing: horiontalRowSpacing) {
            ConfigIDText(option: option)
            Toggle("", isOn: bindBool)
                .frame(maxWidth: .infinity, alignment: .leading)
                .labelsHidden()
        }
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
        
        HStack(spacing: horiontalRowSpacing) {
            ConfigIDText(option: option)
            TextField("", value: bindInt, formatter: NumberFormatter())
                .font(fontRegular)
                .frame(maxWidth: .infinity, alignment: .leading)

            Stepper("", value: bindInt)
                .labelsHidden()
        }
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
            HStack(spacing: horiontalRowSpacing) {
                ConfigIDText(option: option)
                Toggle("Automatic", isOn: bindBool)
                    .font(fontRegular)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            if !bindBool.wrappedValue
            {
                HStack(spacing: horiontalRowSpacing) {
                    Spacer().frame(width: configDescriptionWidth)
                    TextField("", value: bindInt, formatter: NumberFormatter())
                        .font(fontRegular)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Stepper("", value: bindInt)
                        .labelsHidden()
                }
            }
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
        
        HStack(spacing: horiontalRowSpacing) {
            ConfigIDText(option: option)
            
            TextField("", value: bindInt, formatter: NumberFormatter())
                .font(fontRegular)
                .frame(maxWidth: .infinity, alignment: .leading)

            Stepper("", value: bindInt)
                .labelsHidden()

            Picker("",selection: bindString) {
                ForEach(option.getValidStrings(), id: \.self) { string in Text(string).font(fontRegular) }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .labelsHidden()
        }
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
        
        HStack(spacing: horiontalRowSpacing) {
            ConfigIDText(option: option)
            
            TextField("", value: bindInt, formatter: NumberFormatter())
                .font(fontRegular)
                .frame(maxWidth: .infinity, alignment: .leading)

            Stepper("", value: bindInt)
                .labelsHidden()
        }
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
        
        HStack(spacing: horiontalRowSpacing) {
            ConfigIDText(option: option)
            
            Slider(value: bindDouble, in: 0...1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, -6)
        }
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
            
            HStack(spacing: horiontalRowSpacing) {
                ConfigIDText(option: option)
                Toggle("Automatic", isOn: bindBool)
                    .font(fontRegular)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            HStack(spacing: horiontalRowSpacing) {
                Spacer().frame(width: configDescriptionWidth)
                if !bindBool.wrappedValue
                {
                    Slider(value: bindDouble, in: 0...1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, -6)
                }
            }
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
        
        HStack(spacing: horiontalRowSpacing) {
            ConfigIDText(option: option)
            
            Picker("", selection: bindString) {
                ForEach(option.getValidStrings(), id: \.self) { string in Text(string).font(fontRegular) }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .labelsHidden()
        }
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
}




/*----------------------------------------------------------------------------------------------------
    MARK: - BasicConfigSection
        This view displays just the "basic" configuration options. It is displayed in the side panel
        and in the configuration options window.
   ----------------------------------------------------------------------------------------------------*/

struct BasicConfigSection: View {
    
    @EnvironmentObject
    private var globalVars: GlobalVars
    
    let title:          String
    let isCollapsible:  Bool
    
    var body: some View {
        
        if (isCollapsible) {
            CollapsibleSection(title: title) {
                ConfigRowView(option: globalVars.vp!.getOptionInformation("frames_to_show")!)
                ConfigRowView(option: globalVars.vp!.getOptionInformation("frame_size")!)
                ConfigRowView(option: globalVars.vp!.getOptionInformation("action_on_hover")!)
                ConfigRowView(option: globalVars.vp!.getOptionInformation("overlay_timestamp")!)
                ConfigRowView(option: globalVars.vp!.getOptionInformation("overlay_number")!)
            }
        } else {
            Section(title: title) {
                ConfigRowView(option: globalVars.vp!.getOptionInformation("frames_to_show")!)
                ConfigRowView(option: globalVars.vp!.getOptionInformation("frame_size")!)
                ConfigRowView(option: globalVars.vp!.getOptionInformation("action_on_hover")!)
                ConfigRowView(option: globalVars.vp!.getOptionInformation("overlay_timestamp")!)
                ConfigRowView(option: globalVars.vp!.getOptionInformation("overlay_number")!)
            }
        }
    }
}


/*----------------------------------------------------------------------------------------------------
    MARK: - SidePanelView
   ----------------------------------------------------------------------------------------------------*/

struct SidePanelView: View {
    
    @EnvironmentObject private var globalVars: GlobalVars
    @EnvironmentObject private var settings:   UserSettings
    
    var body: some View {
        HStack(spacing:0) {
            
            Divider()
            
            GeometryReader { geometry in
                ScrollView {
                    VStack(alignment: .leading) {
                        CollapsibleSection(title: "Video information") {
                            if (settings.videoInfoPath) {
                                HStack{
                                    InfoRowView(id: "File path",   value: globalVars.vp!.getVideoNameString())
                                    Button(action: { NSWorkspace.shared.openFile(globalVars.vp!.getVideoNameString()) }) {
                                        Image(nsImage: NSImage(imageLiteralResourceName: NSImage.followLinkFreestandingTemplateName))
                                    }.buttonStyle(BorderlessButtonStyle())
                                }
                            }
                            if (settings.videoInfoEncoding)   {InfoRowView(id: "Encoding",   value: globalVars.vp!.getVideoCodecString()) }
                            if (settings.videoInfoFramerate)  {InfoRowView(id: "Frame rate", value: globalVars.vp!.getVideoFPSString()) }
                            if (settings.videoInfoLength)     {InfoRowView(id: "Length",     value: globalVars.vp!.getVideoLengthString()) }
                            if (settings.videoInfoFrames)     {InfoRowView(id: "Frames",     value: globalVars.vp!.getVideoNumOfFramesString()) }
                            if (settings.videoInfoDimensions) {InfoRowView(id: "Dimensions", value: globalVars.vp!.getVideoDimensionsString()) }
                        }
                        
                        Divider()
                        
                        CollapsibleSection(title: "Frame information") {
                            if (globalVars.selectedFrame == nil) {
                                Text("No frame selected")
                                    .font(fontRegular)
                                    .foregroundColor(colorFaded)
                            } else {
                                if (settings.frameInfoTimestamp) {InfoRowView(id: "Time stamp",   value: globalVars.selectedFrame == nil ? "-" : globalVars.selectedFrame!.getTimeStampString()     ) }
                                if (settings.frameInfoNumber) {InfoRowView(id: "Frame number", value: globalVars.selectedFrame == nil ? "-" : String(globalVars.selectedFrame!.getFrameNumber()) ) }
                            }
                        }
                        
                        Spacer()
                        
                        Divider()
                        
                        BasicConfigSection(title: "Configuration options", isCollapsible: true)
                        
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
