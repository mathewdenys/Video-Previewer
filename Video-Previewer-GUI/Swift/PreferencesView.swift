//
//  PreferencesView.swift
//  Video-Previewer-GUI
//
//  Created by Mathew Denys on 2/02/21.
//

import SwiftUI


struct GUISettingsView: View {
    
    @EnvironmentObject private var globalVars: GlobalVars
    @EnvironmentObject private var settings:   UserSettings
    
    func resetSettingsToDefaultsSidePanel() {
        settings.videoInfoPath          = defaultSettingsVideoInfoPath
        settings.videoInfoEncoding      = defaultSettingsVideoInfoEncoding
        settings.videoInfoFramerate     = defaultSettingsVideoInfoFramerate
        settings.videoInfoLength        = defaultSettingsVideoInfoLength
        settings.videoInfoFrames        = defaultSettingsVideoInfoFrames
        settings.videoInfoDimensions    = defaultSettingsVideoInfoDimensions
        settings.frameInfoTimestamp     = defaultSettingsFrameInfoTimestamp
        settings.frameInfoNumber        = defaultSettingsFrameInfoNumber
        settings.sidePanelVisibleVideo  = defaultSettingsSidePanelVisibleVideo
        settings.sidePanelVisibleFrame  = defaultSettingsSidePanelVisibleFrame
        settings.sidePanelVisibleConfig = defaultSettingsSidePanelVisibleConfig
    }
    
    func resetSettingsToDefaultsSelectedFrames() {
        settings.frameBorderColor     = defaultSettingsFrameBorderColor
        settings.frameBorderThickness = defaultSettingsFrameBorderThickness
    }
    
    func resetSettingsToDefaultSpacing() {
        settings.previewSpaceBetweenRows = defaultSettingsPreviewSpaceBetweenRows
        settings.previewSpaceBetweenCols = defaultSettingsPreviewSpaceBetweenCols
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            
            ResettableSection(title: "Side panel", resetAction: resetSettingsToDefaultsSidePanel) {
                
                VStack(spacing: 10) {
                    HStack(alignment: .top) {
                        Text("Video information")
                            .font(fontRegular)
                            .foregroundColor(colorFaded)
                            .frame(width: settingsDescriptionWidth, alignment: .trailing)
                        Toggle("Visible", isOn: $settings.sidePanelVisibleVideo)
                            .font(fontRegular)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
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
                            }
                            HStack {
                                Toggle("Frame rate", isOn: $settings.videoInfoFramerate)
                                    .font(fontRegular)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Toggle("Length", isOn: $settings.videoInfoLength)
                                    .font(fontRegular)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            HStack {
                                Toggle("Frames", isOn: $settings.videoInfoFrames)
                                    .font(fontRegular)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Toggle("Dimensions", isOn: $settings.videoInfoDimensions)
                                    .font(fontRegular)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(.leading, 20)
                        .disabled(!settings.sidePanelVisibleVideo)
                    }
                    
                    VStack {
                        HStack(alignment: .top) {
                            Text("Frame information")
                                .font(fontRegular)
                                .foregroundColor(colorFaded)
                                .frame(width: settingsDescriptionWidth, alignment: .trailing)
                            Toggle("Visible", isOn: $settings.sidePanelVisibleFrame)
                                .font(fontRegular)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
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
                        .padding(.leading, 20)
                        .disabled(!settings.sidePanelVisibleFrame)
                    }
                    
                    HStack(alignment: .top) {
                        Text("Configuration options")
                            .font(fontRegular)
                            .foregroundColor(colorFaded)
                            .frame(width: settingsDescriptionWidth, alignment: .trailing)
                        Toggle("Visible", isOn: $settings.sidePanelVisibleConfig)
                            .font(fontRegular)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
//
//
//
//                VStack {
//                    HStack(alignment: .top) {
//                        Text("Sections")
//                            .font(fontRegular)
//                            .foregroundColor(colorFaded)
//                            .frame(width: settingsDescriptionWidth, alignment: .trailing)
//                        VStack {
//                            HStack {
//                                Toggle("Video information", isOn: $settings.sidePanelVisibleVideo)
//                                    .font(fontRegular)
//                                    .frame(maxWidth: .infinity, alignment: .leading)
//                                Toggle("Frame information", isOn: $settings.sidePanelVisibleFrame)
//                                    .font(fontRegular)
//                                    .frame(maxWidth: .infinity, alignment: .leading)
//                            }
//                            Toggle("Configuration options", isOn: $settings.sidePanelVisibleConfig)
//                                .font(fontRegular)
//                                .frame(maxWidth: .infinity, alignment: .leading)
//                        }
//                    }
//
//                    HStack(alignment: .top) {
//                        Text("Video information")
//                            .font(fontRegular)
//                            .foregroundColor(colorFaded)
//                            .frame(width: settingsDescriptionWidth, alignment: .trailing)
//                        VStack {
//                            HStack {
//                                Toggle("File path", isOn: $settings.videoInfoPath)
//                                    .font(fontRegular)
//                                    .frame(maxWidth: .infinity, alignment: .leading)
//                                Toggle("Encoding", isOn: $settings.videoInfoEncoding)
//                                    .font(fontRegular)
//                                    .frame(maxWidth: .infinity, alignment: .leading)
//                            }
//                            HStack {
//                                Toggle("Frame rate", isOn: $settings.videoInfoFramerate)
//                                    .font(fontRegular)
//                                    .frame(maxWidth: .infinity, alignment: .leading)
//                                Toggle("Length", isOn: $settings.videoInfoLength)
//                                    .font(fontRegular)
//                                    .frame(maxWidth: .infinity, alignment: .leading)
//                            }
//                            HStack {
//                                Toggle("Frames", isOn: $settings.videoInfoFrames)
//                                    .font(fontRegular)
//                                    .frame(maxWidth: .infinity, alignment: .leading)
//                                Toggle("Dimensions", isOn: $settings.videoInfoDimensions)
//                                    .font(fontRegular)
//                                    .frame(maxWidth: .infinity, alignment: .leading)
//                            }
//                        }
//                    }
//
//
//                    HStack(alignment: .top) {
//                        Text("Frame information")
//                            .font(fontRegular)
//                            .foregroundColor(colorFaded)
//                            .frame(width: settingsDescriptionWidth, alignment: .trailing)
//                        Toggle("Timestamp", isOn: $settings.frameInfoTimestamp)
//                            .font(fontRegular)
//                            .frame(maxWidth: .infinity, alignment: .leading)
//                        Toggle("Frame number", isOn: $settings.frameInfoNumber)
//                            .font(fontRegular)
//                            .frame(maxWidth: .infinity, alignment: .leading)
//                    }
                }
            }
            
            Divider()
            
            /* ---------------------------------------------------------------------- */
            
            ResettableSection(title: "Selected frame", resetAction: resetSettingsToDefaultsSelectedFrames) {
                VStack {
                    HStack {
                        Text("Color")
                            .font(fontRegular)
                            .foregroundColor(colorFaded)
                            .frame(width: settingsDescriptionWidth, alignment: .trailing)
                        
                        Picker(selection: $settings.frameBorderColor, label: Text("")) {
                            Text("Red")    .tag(NSColor.red)
                            Text("Blue")   .tag(NSColor.blue)
                            Text("Green")  .tag(NSColor.green)
                            Text("Yellow") .tag(NSColor.yellow)
                            Text("Orange") .tag(NSColor.orange)
                            Text("Purple") .tag(NSColor.purple)
                            Text("Gray")   .tag(NSColor.gray)
                        }.labelsHidden()
                    }
                    
                    HStack {
                        Text("Thickness")
                            .font(fontRegular)
                            .foregroundColor(colorFaded)
                            .frame(width: settingsDescriptionWidth, alignment: .trailing)
                        
                        Slider(value: $settings.frameBorderThickness, in: 2...10, step: 0.5)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            
            Divider()
            
            /* ---------------------------------------------------------------------- */
            
            ResettableSection(title: "Spacing between frames", resetAction: resetSettingsToDefaultSpacing) {
                VStack {
                    HStack {
                        Text("Vertical")
                            .font(fontRegular)
                            .foregroundColor(colorFaded)
                            .frame(width: settingsDescriptionWidth, alignment: .trailing)
                        
                        Slider(value: $settings.previewSpaceBetweenRows, in: 0...50, step: 5)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    HStack {
                        Text("Horizontal")
                            .font(fontRegular)
                            .foregroundColor(colorFaded)
                            .frame(width: settingsDescriptionWidth, alignment: .trailing)
                        
                        Slider(value: $settings.previewSpaceBetweenCols, in: 0...50, step: 5)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            
            
            /* ---------------------------------------------------------------------- */
            
            Spacer()
            
            HStack {
                Spacer()
                Button(action: {
                    resetSettingsToDefaultsSidePanel()
                    resetSettingsToDefaultsSelectedFrames()
                    resetSettingsToDefaultSpacing()
                }) {
                    Text("Reset all to Defaults")
                }
                Spacer()
            }
            
            
        }.padding(.vertical, 10)
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
                BasicConfigSection(title: "Basic options", isCollapsible: false)
                
                Divider()
                
                Section(title: "Advanced options") {
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
            }.padding(.vertical, 10).padding(.horizontal, sectionPaddingHorizontal)
        }
    }
}


/*----------------------------------------------------------------------------------------------------
    MARK: - PreferencesView
   ----------------------------------------------------------------------------------------------------*/

struct PreferencesView: View {
    
    @EnvironmentObject private var globalVars: GlobalVars
    @EnvironmentObject private var settings:   UserSettings
    
    var body: some View {
        TabView {
            GUISettingsView()       .tabItem{ Text("Interface") }
            ConfigurationView()     .tabItem{ Text("Config options") }
            ConfigurationFilesView().tabItem{ Text("Config files") }
        }.frame(width: 400, height: 475).padding(.all, 15)
    }
}
