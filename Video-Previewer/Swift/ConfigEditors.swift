//
//  ConfigEditors.swift
//  Video-Previewer
//
//  Created by Mathew Denys on 23/02/21.
//

import SwiftUI


/*----------------------------------------------------------------------------------------------------
    MARK: - Tooltip
        From: https://stackoverflow.com/questions/63217860/how-to-add-tooltip-on-macos-10-15-with-swiftui
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
    MARK: - ConfigIDText
   ----------------------------------------------------------------------------------------------------*/

extension String {
    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }
}


struct ConfigIDText: View {
    
    @EnvironmentObject private var preview: PreviewData
    
    var option: NSOptionInformation
    
    var body: some View {
        Text(option.getID().capitalizingFirstLetter().replacingOccurrences(of: "_", with: " "))
            .regularFont()
            .frame(width: configDescriptionWidth, alignment: .trailing)
            .toolTip(option.getDescription())
            .contextMenu {
                Button("Copy id", action: {
                    pasteBoard.clearContents()
                    pasteBoard.writeObjects([option.getID() as NSString])
                })
                Button("Copy value", action: {
                    pasteBoard.clearContents()
                    pasteBoard.writeObjects([preview.backend!.getOptionValueString(option.getID()) as NSString])
                })
                Button("Copy configuration string", action: {
                    pasteBoard.clearContents()
                    pasteBoard.writeObjects([preview.backend!.getOptionConfigString(option.getID()) as NSString])
                })
            }
    }
}


/*----------------------------------------------------------------------------------------------------
    MARK: - ConfigEditorBoolean
   ----------------------------------------------------------------------------------------------------*/

struct ConfigEditorBoolean: View {
    
    @EnvironmentObject private var preview: PreviewData
    
    var option: NSOptionInformation
    
    var body: some View {
        
        let bindBool = Binding<Bool> (
            get: { preview.backend!.getOptionValue(option.getID())!.getBool()?.boolValue ?? false },
            set: { preview.backend!.setOptionValue(option.getID(), with: $0)
                   preview.refresh()
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
    
    @EnvironmentObject private var preview: PreviewData
    
    var option: NSOptionInformation
    
    var body: some View {
        
        let bindInt = Binding<Int>(
            get: { preview.backend!.getOptionValue(option.getID())!.getInt()?.intValue ?? 0 },
            set: { var newValue = $0
                   if ($0 < 1) { newValue = 1 }   // An ePositiveInteger can't have a value less than 1
                   preview.backend!.setOptionValue(option.getID(), with: Int32(newValue))
                   preview.refresh()
                 }
        )
        
        HStack(spacing: horiontalRowSpacing) {
            ConfigIDText(option: option)
            
            TextField("", value: bindInt, formatter: NumberFormatter())
                .regularFont()
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
    
    @EnvironmentObject private var preview: PreviewData
    
    var option: NSOptionInformation
    
    @State private var intValue: Int = 100 // Default value (this should really be implemented on the backend)
    
    var body: some View {
        
        let bindInt = Binding<Int>(
            get: { preview.backend!.getOptionValue(option.getID())!.getInt()?.intValue ?? intValue },
            set: { var newValue = Int32($0)
                   if (newValue < 1) { newValue = 1 } // An ePositiveInteger can't have a value less than 1
                   preview.backend!.setOptionValue(option.getID(), with: newValue)
                   preview.refresh()
            }
        )
        
        let bindBool = Binding<Bool> (
            get: { return (preview.backend!.getOptionValue(option.getID())!.getString()) == nil ? false : true },
            set: {
                if ( $0 == true)  {                                                        // If "auto" is turned on
                    intValue = bindInt.wrappedValue                                        // Save the Int value (so that value is not lost when "auto" is turned off)
                    preview.backend!.setOptionValue(option.getID(), with: "auto")          // Set the option value to be "auto" in vp
                    
                }
                
                if ( $0 == false) {                                                        // If "auto" is turned off
                    preview.backend!.setOptionValue(option.getID(), with: Int32(intValue)) // Recover the Int value
                    
                }
                preview.refresh()
            }
        )
        
        HStack {
            ConfigIDText(option: option)
            
            Toggle("Automatic", isOn: bindBool)
                .regularFont()
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if (!bindBool.wrappedValue) {
                TextField("", value: bindInt, formatter: NumberFormatter())
                    .regularFont()
                    .frame(maxWidth: .infinity, alignment: .leading)

                Stepper("", value: bindInt)
                    .labelsHidden()
            }
        }.frame(height: 20) // Prevent height from changing when content changes
    }
}


/*----------------------------------------------------------------------------------------------------
    MARK: - ConfigEditorPositiveIntegerOrString
   ----------------------------------------------------------------------------------------------------*/

struct ConfigEditorPositiveIntegerOrString: View {
    
    @EnvironmentObject private var preview: PreviewData
    
    var option: NSOptionInformation
    
    var body: some View {
        
        let bindInt = Binding<Int>(
            get: { preview.backend!.getOptionValue(option.getID())!.getInt()?.intValue ?? 0 },
            set: { var newValue = $0
                   if ($0 < 1) { newValue = 1 }   // An ePositiveInteger can't have a value less than 1
                   preview.backend!.setOptionValue(option.getID(), with: Int32(newValue))
                   preview.refresh()
                 }
        )
        
        let bindString = Binding<String>(
            get: { preview.backend!.getOptionValue(option.getID())!.getString() ?? "" },
            set: { preview.backend!.setOptionValue(option.getID(), with: $0)
                   preview.refresh()
                 }
        )
        
        HStack(spacing: horiontalRowSpacing) {
            ConfigIDText(option: option)
            
            TextField("", value: bindInt, formatter: NumberFormatter())
                .regularFont()
                .frame(maxWidth: .infinity, alignment: .leading)

            Stepper("", value: bindInt)
                .labelsHidden()

            Picker("",selection: bindString) {
                ForEach(option.getValidStrings(), id: \.self) { string in Text(string).regularFont() }
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
    
    @EnvironmentObject private var preview: PreviewData
    
    var option: NSOptionInformation
    
    var body: some View {
        
        let bindInt = Binding<Int>(
            get: { preview.backend!.getOptionValue(option.getID())!.getInt()?.intValue ?? 0 },
            set: { var newValue = $0
                   if ($0 < 1)   { newValue = 1 }   // An ePercentage can't have a value less than 1
                   if ($0 > 100) { newValue = 100 } // An ePercentage can't have a value greater than 100
                   preview.backend!.setOptionValue(option.getID(), with: Int32(newValue))
                   preview.refresh()
                 }
        )
        
        HStack(spacing: horiontalRowSpacing) {
            ConfigIDText(option: option)
            
            TextField("", value: bindInt, formatter: NumberFormatter())
                .regularFont()
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
    
    @EnvironmentObject private var preview: PreviewData
    
    var option: NSOptionInformation
    
    var body: some View {
        
        let bindDouble = Binding<Double>(
            get: { preview.backend!.getOptionValue(option.getID())!.getDouble()?.doubleValue ?? 0.0 },
            set: { preview.backend!.setOptionValue(option.getID(), with: Double($0))
                   preview.refresh()
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
    
    @EnvironmentObject private var preview: PreviewData
    
    var option: NSOptionInformation
    
    @State private var doubleValue: Double = 0.5 // Default value (this should really be implemented on the backend)
    
    var body: some View {
        
        let bindDouble = Binding<Double>(
            get: { preview.backend!.getOptionValue(option.getID())!.getDouble()?.doubleValue ?? doubleValue },
            set: { preview.backend!.setOptionValue(option.getID(), with: Double($0))
                   preview.refresh()
                 }
        )
        
        let bindBool = Binding<Bool> (
            get: { return (preview.backend!.getOptionValue(option.getID())!.getString()) == nil ? false : true },
            set: {
                if ($0 == true) {                                                      // If "auto" is turned on
                    doubleValue = bindDouble.wrappedValue                              // Save the Double value (so that value is not lost when "auto" is turned off)
                    preview.backend!.setOptionValue(option.getID(), with: "auto");     // Set the option value to be "auto" in vp
                }
                
                if ($0 == false) {                                                     // If "auto" is turned off
                    preview.backend!.setOptionValue(option.getID(), with: doubleValue) // Recover the Double value
                }
                
                preview.refresh()
            }
        )
        
        VStack {
            HStack(spacing: horiontalRowSpacing) {
                ConfigIDText(option: option)
                Toggle("Automatic", isOn: bindBool)
                    .regularFont()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            HStack(spacing: horiontalRowSpacing) {
                Spacer().frame(width: configDescriptionWidth)
                Slider(value: bindDouble, in: 0...1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, -6)
                    .disabled(bindBool.wrappedValue)
            }
        }
    }
}


/*----------------------------------------------------------------------------------------------------
    MARK: - ConfigEditorString
   ----------------------------------------------------------------------------------------------------*/

struct ConfigEditorString: View {
    
    @EnvironmentObject private var preview: PreviewData
    
    var option: NSOptionInformation
    
    var body: some View {
        
        let bindString = Binding<String>(
            get: { preview.backend!.getOptionValue(option.getID())!.getString() ?? "" },
            set: { preview.backend!.setOptionValue(option.getID(), with: $0)
                   preview.refresh()
                 }
        )
        
        HStack(spacing: horiontalRowSpacing) {
            ConfigIDText(option: option)
            
            Picker("", selection: bindString) {
                ForEach(option.getValidStrings(), id: \.self) { string in Text(string).regularFont() }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .labelsHidden()
        }
    }
}


