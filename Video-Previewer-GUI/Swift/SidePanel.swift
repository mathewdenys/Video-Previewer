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
    MARK: - ConfigRowView
        A ConfigRowView is displayed for each recognised configuration option
        A different display is defined for each possible value of OptionInformation.getValidValues()
   ----------------------------------------------------------------------------------------------------*/

struct ConfigRowView: View {
    
    @EnvironmentObject
    private var globalVars: GlobalVars
    
    // Information relating to the configuration option being displayed
    private var id:           String
    private var tooltip:      String
    private let valueType:    NSValidOptionValue
    private let validStrings: Array<String>
    
    // Storing the value of the option. Initial values are assigned here; a "proper" value
    // from vp is assigned in the HStack.onAppear{} modifier
    @State private var inputBool:   Bool   = false
    @State private var inputInt:    Int    = 0
    @State private var inputDouble: Double = 0.0
    @State private var inputString: String = ""
    
    init(option: NSOptionInformation) {
        id           = option.getID()
        tooltip      = option.getDescription()
        valueType    = option.getValidValues()
        validStrings = option.getValidStrings() ?? [String]()
    }
    
    var body: some View {
        
        // The following Bindings allow me to update vp when the inputX variables
        // are updated. They are required because the SwiftUI Toggle, Stepper, Picker etc. use
        // two-way bindings when setting their value, and I need to be able to sneak in an run
        // some additional code, rather than just updating the local variable.
        // Another approach would be to use a didSet{} method on the inputX variables, but this
        // has the rather significant downside of being called when the inputX variables are
        // initialised in the .onAppear{}.
        
        let bindBool = Binding<Bool> (
            get: { self.inputBool },
            set: { self.inputBool = $0
                   globalVars.vp!.setOptionValue(id, with: inputBool)
                   globalVars.configUpdateCounter += 1
                 }
        )

        let bindInt = Binding<Int>(
            get: { self.inputInt },
            set: { self.inputInt = $0
                   globalVars.vp!.setOptionValue(id, with: Int32(inputInt))
                   globalVars.configUpdateCounter += 1
                 }
        )
        
        let bindDouble = Binding<Double>(
            get: { self.inputDouble },
            set: { self.inputDouble = $0
                   globalVars.vp!.setOptionValue(id, with: Double(inputDouble))
                   globalVars.configUpdateCounter += 1
                 }
        )

        let bindString = Binding<String>(
            get: { self.inputString },
            set: { self.inputString = $0
                   globalVars.vp!.setOptionValue(id, with: inputString)
                   globalVars.configUpdateCounter += 1
                 }
        )
        
        HStack(alignment: .top) {
            
            // Left hand column: option ID
            Text(id.capitalizingFirstLetter().replacingOccurrences(of: "_", with: " "))
                .foregroundColor(colorFaded)
                .frame(width: configDescriptionWidth, alignment: .trailing)
                .toolTip(tooltip)
                .contextMenu {
                    Button("Copy id", action: {
                        pasteBoard.clearContents()
                        pasteBoard.writeObjects([id as NSString])
                    })
                    Button("Copy value", action: {
                        pasteBoard.clearContents()
                        pasteBoard.writeObjects([globalVars.vp!.getOptionValueString(id) as NSString])
                    })
                    Button("Copy configuration string", action: {
                        pasteBoard.clearContents()
                        pasteBoard.writeObjects([globalVars.vp!.getOptionConfigString(id) as NSString])
                    })
                }
            
            // Right hand column: option value (editable)
            switch valueType {
            
                /*------------------------------------------------------------
                    Boolean value
                 ------------------------------------------------------------*/
                case NSValidOptionValue.eBoolean:

                    Toggle("", isOn: bindBool)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .labelsHidden()
                    
                /*------------------------------------------------------------
                    Positive integer value
                 ------------------------------------------------------------*/
                case NSValidOptionValue.ePositiveInteger:

                    TextField("", value: bindInt, formatter: NumberFormatter())
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Stepper("", value: bindInt)
                        .labelsHidden()

                /*------------------------------------------------------------
                    Positive integer OR string value
                 ------------------------------------------------------------*/
                case NSValidOptionValue.ePositiveIntegerOrString:

                    TextField("", value: bindInt, formatter: NumberFormatter())
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Stepper("", value: bindInt)
                        .labelsHidden()

                    Picker("",selection: bindString) {
                        ForEach(validStrings, id: \.self) { string in Text(string) }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .labelsHidden()

                /*------------------------------------------------------------
                    Percentage (integer) value
                 ------------------------------------------------------------*/
                case NSValidOptionValue.ePercentage:

                    TextField("", value: bindInt, formatter: NumberFormatter())
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Stepper("", value: bindInt)
                        .labelsHidden()
                    
                /*------------------------------------------------------------
                    Decimal (number between 0 and 1) value
                 ------------------------------------------------------------*/
                case NSValidOptionValue.eDecimal:

                    Slider(value: bindDouble, in: 0...1)

                /*------------------------------------------------------------
                    String value
                 ------------------------------------------------------------*/
                case NSValidOptionValue.eString:

                    Picker("",selection: bindString) {
                        ForEach(validStrings, id: \.self) { string in Text(string) }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .labelsHidden()

                /*------------------------------------------------------------
                    Default value (should never be reached)
                 ------------------------------------------------------------*/
                default:
                    Spacer()
            }
        }
        .padding(.vertical, configRowVPadding)
        .foregroundColor(colorBold)
        .onAppear {
            if let b = globalVars.vp!.getOptionValue(id)?.getBool()   { inputBool   = b.boolValue }
            if let i = globalVars.vp!.getOptionValue(id)?.getInt()    { inputInt    = i.intValue }
            if let d = globalVars.vp!.getOptionValue(id)?.getDouble() { inputDouble = d.doubleValue }
            if let s = globalVars.vp!.getOptionValue(id)?.getString() { inputString = s }
        }
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
                            InfoRowView(id: "File path",   value: globalVars.vp!.getVideoNameString())
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
                        
                        CollapsibleBlockView(title: "Configuration Options") {
                            ConfigRowView(option: globalVars.vp!.getOptionInformation("overlay_timestamp")!)
                            ConfigRowView(option: globalVars.vp!.getOptionInformation("overlay_number")!)
                            ConfigRowView(option: globalVars.vp!.getOptionInformation("frame_size")!)
                            ConfigRowView(option: globalVars.vp!.getOptionInformation("action_on_hover")!)
                            Button("Advanced Options", action: {
                                NSApp.sendAction(#selector(AppDelegate.openConfigurationWindow), to: nil, from:nil)
                            })
                        }
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
