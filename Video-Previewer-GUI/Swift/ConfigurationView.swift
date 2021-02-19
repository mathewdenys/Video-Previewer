//
//  ConfigurationView.swift
//  Video-Previewer-GUI
//
//  Created by Mathew Denys on 2/02/21.
//

import SwiftUI

struct SettingsView: View {
    
    @EnvironmentObject private var globalVars: GlobalVars
    @EnvironmentObject private var settings:   UserSettings
    
    var body: some View {
        CollapsibleBlockView(title: "Settings", expandedByDefault: true) {
            VStack(alignment: .leading) {
                Text("Video information")
                    .font(fontSubheading)
                
                HStack {
                    Spacer()
                        .frame(width: settingsDescriptionWidth)
                    VStack {
                        HStack {
                            Toggle("File path", isOn: $settings.videoInfoPath)
                                .font(fontRegular)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Toggle("Encoding", isOn: $settings.videoInfoEncoding)
                                .font(fontRegular)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Toggle("Frame rate", isOn: $settings.videoInfoFramerate)
                                .font(fontRegular)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        HStack {
                            Toggle("Length", isOn: $settings.videoInfoLength)
                                .font(fontRegular)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Toggle("Frames", isOn: $settings.videoInfoFrames)
                                .font(fontRegular)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Toggle("Dimensions", isOn: $settings.videoInfoDimensions)
                                .font(fontRegular)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                
                Text("Frame information")
                    .font(fontSubheading)
                
                HStack {
                    Spacer()
                        .frame(width: settingsDescriptionWidth)
                    Toggle("Timestamp", isOn: $settings.frameInfoTimestamp)
                        .font(fontRegular)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Toggle("Frame number", isOn: $settings.frameInfoNumber)
                        .font(fontRegular)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Text("Frame selection")
                    .font(fontSubheading)
                
                HStack {
                    Text("Color")
                        .font(fontRegular)
                        .frame(width: settingsDescriptionWidth, alignment: .trailing)
                    
                    Picker(selection: $settings.frameBorderColor, label: Text("")) {
                        Text("Red")    .tag(Color.red)
                        Text("Blue")   .tag(Color.blue)
                        Text("Green")  .tag(Color.green)
                        Text("Yellow") .tag(Color.yellow)
                        Text("Orange") .tag(Color.orange)
                        Text("Purple") .tag(Color.purple)
                        Text("Pink")   .tag(Color.pink)
                        Text("Gray")   .tag(Color.gray)
                    }.labelsHidden()
                }
                
                HStack {
                    Text("Thickness")
                        .font(fontRegular)
                        .frame(width: settingsDescriptionWidth, alignment: .trailing)
                    
                    Slider(value: $settings.frameBorderThickness, in: 2...10, step: 0.5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Text("Vertical spacing between frames in preview")
                    .font(fontSubheading)
                
                HStack {
                    Spacer()
                        .frame(width: settingsDescriptionWidth)
                    
                    Slider(value: $settings.previewSpaceBetweenRows, in: 0...50, step: 5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}



struct ConfigurationView: View {
    
    @EnvironmentObject private var globalVars: GlobalVars
    @EnvironmentObject private var settings:   UserSettings
    
    var body: some View {
        
        if (globalVars.vp == nil) {
            Text("No video is being previewed")
        } else {
            VStack {
                SettingsView()
                
                Divider()
                
                BasicConfigBlockView(title: "Basic Configuration Options", expandedByDefault: false)
                
                Divider()
                
                CollapsibleBlockView(title: "Advanced Configuration Options") {
                    ConfigRowView(option: globalVars.vp!.getOptionInformation("maximum_percentage")!)
                    ConfigRowView(option: globalVars.vp!.getOptionInformation("minimum_sampling")!)
                    ConfigRowView(option: globalVars.vp!.getOptionInformation("maximum_frames")!)
                }
                
                Divider()
                
                CollapsibleBlockView(title: "Configuration Files", expandedByDefault: false) {
                    Text("Note: Editing the configuration files directly is not recommended. Changes to configuration files will not be reflected until a new video file is loaded.")
                        .font(fontNote)                               // small font
                        .fixedSize(horizontal: false, vertical: true) // for multi-line text
                        .multilineTextAlignment(.leading)
                        
                    ForEach(globalVars.vp!.getConfigFilePaths(), id: \.self) { configFilePath in
                        HStack {
                            ScrollView(.horizontal, showsIndicators: false, content: { Text(configFilePath).font(fontRegular).foregroundColor(colorFaded) })
                            Spacer()
                            Button(action: { NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: configFilePath)]) }) {
                                Image(nsImage: NSImage(imageLiteralResourceName: NSImage.followLinkFreestandingTemplateName))
                            }.buttonStyle(BorderlessButtonStyle())
                            
                        }.padding(.leading)
                    }
                }
            }
            .frame(width: 400)
            .padding(.vertical, 10)
        }
    }
}

struct Preferences_Previews: PreviewProvider {
    static var previews: some View {
        ConfigurationView()
    }
}
