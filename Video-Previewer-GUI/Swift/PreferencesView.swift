//
//  PreferencesView.swift
//  Video-Previewer-GUI
//
//  Created by Mathew Denys on 2/02/21.
//

import SwiftUI


/*----------------------------------------------------------------------------------------------------
    MARK: - SettingsView
   ----------------------------------------------------------------------------------------------------*/

struct SettingsView: View {
    
    @EnvironmentObject private var globalVars: GlobalVars
    @EnvironmentObject private var settings:   UserSettings
    
    var body: some View {
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
            
            Spacer()
        }.padding(.vertical, 10).padding(.horizontal, horiontalRowSpacing)
    }
}


/*----------------------------------------------------------------------------------------------------
    MARK: - ConfigurationView
   ----------------------------------------------------------------------------------------------------*/

struct ConfigurationView: View {
    
    @EnvironmentObject private var globalVars: GlobalVars
    
    var body: some View {
        if (globalVars.vp == nil) {
            Text("No video is being previewed")
        } else {
            VStack {
                BasicConfigBlockView(title: "Basic Options", expandedByDefault: false)
                
                Divider()
                
                CollapsibleBlockView(title: "Advanced Options") {
                    ConfigRowView(option: globalVars.vp!.getOptionInformation("maximum_percentage")!)
                    ConfigRowView(option: globalVars.vp!.getOptionInformation("minimum_sampling")!)
                    ConfigRowView(option: globalVars.vp!.getOptionInformation("maximum_frames")!)
                }
                
                Spacer()
            }.padding(.vertical, 10)
        }
    }
}


/*----------------------------------------------------------------------------------------------------
    MARK: - ConfigurationFilesView
   ----------------------------------------------------------------------------------------------------*/

struct ConfigurationFilesView: View {
    
    @EnvironmentObject private var globalVars: GlobalVars
    
    var body: some View {
        
        if (globalVars.vp == nil) {
            Text("No video is being previewed")
        } else {
            VStack {
                Text("Note: Editing the configuration files directly is not recommended. Changes to configuration files will not be reflected until a new video file is loaded.")
                    .font(fontNote)                               // Small font
                    .fixedSize(horizontal: false, vertical: true) // For multiline text wrapping
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
                
                Spacer()
            }.padding(.vertical, 10).padding(.horizontal, horiontalRowSpacing)
        }
    }
}


/*----------------------------------------------------------------------------------------------------
    MARK: - PreferencesView
   ----------------------------------------------------------------------------------------------------*/

struct PreferencesView: View {
    
    @EnvironmentObject private var globalVars: GlobalVars
    @EnvironmentObject private var settings:   UserSettings
    
    var defaultUserSettings = UserSettings()
    
    var body: some View {
        TabView {
            SettingsView().tabItem{ Text("Settings") }
            ConfigurationView().tabItem{ Text("Config options") }
            ConfigurationFilesView().tabItem{ Text("Config files") }
        }.frame(width: 350, height: 400).padding(.all, 20)
    }
}
