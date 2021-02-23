//
//  SidePanel.swift
//  Video-Previewer-GUI
//
//  Created by Mathew Denys on 13/01/21.
//

import SwiftUI


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
                .regularFont()
                .frame(width: infoDescriptionWidth, alignment: .trailing)
                .toolTip(tooltip)
            Text(value)
                .regularFont()
                .foregroundColor(colorBold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contextMenu {
                    Button("Copy", action: {
                        pasteBoard.clearContents()
                        pasteBoard.writeObjects([value as NSString])
                    })
                }
        }.padding(.bottom, infoRowBottomPadding)
    }
}


/*----------------------------------------------------------------------------------------------------
    MARK: - ConfigRowView
        A ConfigRowView is displayed for each recognised configuration option
        A different display is defined for each possible value of OptionInformation.getValidValues()
   ----------------------------------------------------------------------------------------------------*/

struct ConfigRowView: View {
    
    @EnvironmentObject private var preview: PreviewData
    
    let option: NSOptionInformation
    
    var body: some View {
        switch option.getValidValues() {
        
            case NSValidOptionValue.eBoolean:
                ConfigEditorBoolean(option: option)
                    .padding(.bottom, configRowBottomPadding)
                
            case NSValidOptionValue.ePositiveInteger:
                ConfigEditorPositiveInteger(option: option)
                    .padding(.bottom, configRowBottomPadding)
                
            case NSValidOptionValue.ePositiveIntegerOrAuto:
                ConfigEditorPositiveIntegerOrAuto(option: option)
                    .padding(.bottom, configRowBottomPadding)
                
            case NSValidOptionValue.ePositiveIntegerOrString:
                ConfigEditorPositiveIntegerOrString(option: option)
                    .padding(.bottom, configRowBottomPadding)
                
            case NSValidOptionValue.ePercentage:
                ConfigEditorPercentage(option: option)
                    .padding(.bottom, configRowBottomPadding)
                
            case NSValidOptionValue.eDecimal:
                ConfigEditorDecimal(option: option)
                    .padding(.bottom, configRowBottomPadding)
                
            case NSValidOptionValue.eDecimalOrAuto:
                ConfigEditorDecimalOrAuto(option: option)
                    .padding(.bottom, configRowBottomPadding)
                
            case NSValidOptionValue.eString:
                ConfigEditorString(option: option)
                    .padding(.bottom, configRowBottomPadding)

            default:
                Spacer()
        }
    }
}


/*----------------------------------------------------------------------------------------------------
    MARK: - BasicConfigSection
        This view displays just the "basic" configuration options. It is displayed in the side panel
        and in the preferences window.
   ----------------------------------------------------------------------------------------------------*/

struct BasicConfigSection: View {
    
    @EnvironmentObject private var preview: PreviewData
    
    var body: some View {
        VStack {
            ConfigRowView(option: preview.backend!.getOptionInformation("frames_to_show")!)
            ConfigRowView(option: preview.backend!.getOptionInformation("frame_size")!)
            ConfigRowView(option: preview.backend!.getOptionInformation("overlay_timestamp")!)
            ConfigRowView(option: preview.backend!.getOptionInformation("overlay_number")!)
        }
    }
}


/*----------------------------------------------------------------------------------------------------
    MARK: - AdvancedConfigSection
        This view displays just the "advanced" configuration options. It is displayed in the
        preferences window
   ----------------------------------------------------------------------------------------------------*/

struct AdvancedConfigSection: View {
    
    @EnvironmentObject private var preview: PreviewData
    
    var body: some View {
        
        let maximumFramesString = preview.backend!.getOptionValue("maximum_frames")!.getString() // nil if "maximum_frames" is not set of "auto"
            
        VStack {
            Text("The maximum number of frames that can be shown (i.e. the upper limit of \"Frames to show\") can be set directly, or determined automatically by setting the maximum percentage of total frames in the video that can be shown and/or the minimum sampling gap between frames.")
                .fixedSize(horizontal: false, vertical: true) // For multiline text wrapping
                .multilineTextAlignment(.leading)
                .noteFont()
            
            ConfigRowView(option: preview.backend!.getOptionInformation("maximum_frames")!)
            ConfigRowView(option: preview.backend!.getOptionInformation("maximum_percentage")!)
                .disabled( maximumFramesString == nil )
                .foregroundColor(maximumFramesString == nil ? colorFaded : colorBold)
            ConfigRowView(option: preview.backend!.getOptionInformation("minimum_sampling")!)
                .disabled( maximumFramesString == nil )
                .foregroundColor(maximumFramesString == nil ? colorFaded : colorBold)
        }
    }
}


/*----------------------------------------------------------------------------------------------------
    MARK: - SidePanelView
   ----------------------------------------------------------------------------------------------------*/

struct SidePanelView: View {
    
    @EnvironmentObject private var preview: PreviewData
    @EnvironmentObject private var settings:   UserSettings
    
    var body: some View {
        HStack(spacing:0) {
            
            Divider()
            
            GeometryReader { geometry in
                ScrollView {
                    VStack(alignment: .leading) {
                        if (settings.sidePanelVisibleFile) {
                            Section(title: "File information", isCollapsible: true) {
                                if (settings.fileInfoPath) {
                                    HStack{
                                        InfoRowView(id: "File path",   value: preview.backend!.getVideoPathString())
                                        Button(action: { NSWorkspace.shared.openFile(preview.backend!.getVideoPathString()) }) {
                                            Image(nsImage: NSImage(imageLiteralResourceName: NSImage.followLinkFreestandingTemplateName))
                                        }.buttonStyle(BorderlessButtonStyle())
                                    }
                                }
                                if (settings.fileInfoEncoding)   { InfoRowView(id: "Encoding",   value: preview.backend!.getVideoCodecString()) }
                                if (settings.fileInfoFramerate)  { InfoRowView(id: "Frame rate", value: preview.backend!.getVideoFPSString()) }
                                if (settings.fileInfoLength)     { InfoRowView(id: "Length",     value: preview.backend!.getVideoLengthString()) }
                                if (settings.fileInfoFrames)     { InfoRowView(id: "Frames",     value: preview.backend!.getVideoNumOfFramesString()) }
                                if (settings.fileInfoDimensions) { InfoRowView(id: "Dimensions", value: preview.backend!.getVideoDimensionsString()) }
                            }
                            Divider()
                        }
                        
                        if (settings.sidePanelVisibleFrame) {
                            Section(title: "Frame information", isCollapsible: true) {
                                if (preview.selectedFrame == nil) {
                                    Text("No frame selected")
                                        .regularFont()
                                        .foregroundColor(colorFaded)
                                } else {
                                    if (settings.frameInfoTimestamp) { InfoRowView(id: "Time stamp",   value: preview.selectedFrame == nil ? "-" : preview.selectedFrame!.getTimeStampString()     ) }
                                    if (settings.frameInfoNumber)    { InfoRowView(id: "Frame number", value: preview.selectedFrame == nil ? "-" : String(preview.selectedFrame!.getFrameNumber()) ) }
                                }
                            }
                            Divider()
                        }
                        
                        Spacer()
                        
                        if (settings.sidePanelVisibleConfig) {
                            Divider()
                            
                            Section(title: "Configuration options", isCollapsible: true) {
                                BasicConfigSection()
                            }
                        }
                    }
                    .padding(.vertical, 10.0)
                    .frame(minHeight: geometry.size.height) // Inside the GeometryReader, this keeps the ConfigInfoBlock at the bottom (by default the Spacer() does nothing in a ScrollView)
                }
            }
        }
    }
}
