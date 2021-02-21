//
//  PreferencesView.swift
//  Video-Previewer-GUI
//
//  Created by Mathew Denys on 2/02/21.
//

import SwiftUI


struct GUISettingsView: View {
    
    @EnvironmentObject private var preview:  PreviewData
    @EnvironmentObject private var settings: UserSettings
    
    var body: some View {
        VStack(alignment: .leading) {
            
            Section(title: "Side panel", resetAction: settings.resetToDefaultsSidePanel) {
                
                VStack(spacing: 10) {
                    HStack(alignment: .top) {
                        Text("Video information")
                            .regularFont()
                            .frame(width: settingsDescriptionWidth, alignment: .trailing)
                        Toggle("Visible", isOn: $settings.sidePanelVisibleVideo)
                            .regularFont()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    HStack {
                        Spacer()
                            .frame(width: settingsDescriptionWidth)
                        VStack {
                            HStack {
                                Toggle("File path", isOn: $settings.videoInfoPath)
                                    .regularFont()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Toggle("Encoding", isOn: $settings.videoInfoEncoding)
                                .regularFont()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            HStack {
                                Toggle("Frame rate", isOn: $settings.videoInfoFramerate)
                                    .regularFont()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Toggle("Length", isOn: $settings.videoInfoLength)
                                .regularFont()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            HStack {
                                Toggle("Frames", isOn: $settings.videoInfoFrames)
                                    .regularFont()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Toggle("Dimensions", isOn: $settings.videoInfoDimensions)
                                .regularFont()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(.leading, 20)
                        .disabled(!settings.sidePanelVisibleVideo)
                    }
                    
                    VStack {
                        HStack(alignment: .top) {
                            Text("Frame information")
                                .regularFont()
                                .frame(width: settingsDescriptionWidth, alignment: .trailing)
                            Toggle("Visible", isOn: $settings.sidePanelVisibleFrame)
                            .regularFont()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        HStack {
                            Spacer()
                                .frame(width: settingsDescriptionWidth)
                            Toggle("Timestamp", isOn: $settings.frameInfoTimestamp)
                                .regularFont()
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Toggle("Frame number", isOn: $settings.frameInfoNumber)
                            .regularFont()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.leading, 20)
                        .disabled(!settings.sidePanelVisibleFrame)
                    }
                    
                    HStack(alignment: .top) {
                        Text("Configuration options")
                            .regularFont()
                            .frame(width: settingsDescriptionWidth, alignment: .trailing)
                        Toggle("Visible", isOn: $settings.sidePanelVisibleConfig)
                            .regularFont()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            
            Divider()
            
            /* ---------------------------------------------------------------------- */
            
            Section(title: "Selected frame", resetAction: settings.resetToDefaultsSelectedFrames) {
                VStack {
                    HStack {
                        Text("Color")
                            .regularFont()
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
                            .regularFont()
                            .frame(width: settingsDescriptionWidth, alignment: .trailing)
                        
                        Slider(value: $settings.frameBorderThickness, in: 2...10, step: 0.5)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            
            Divider()
            
            /* ---------------------------------------------------------------------- */
            
            Section(title: "Spacing between frames", resetAction: settings.resetToDefaultsSpacing) {
                VStack {
                    HStack {
                        Text("Vertical")
                            .regularFont()
                            .frame(width: settingsDescriptionWidth, alignment: .trailing)
                        
                        Slider(value: $settings.previewSpaceBetweenRows, in: 0...50, step: 5)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    HStack {
                        Text("Horizontal")
                            .regularFont()
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
                Button(action: settings.resetToDefaultsAll) { Text("Reset all to Defaults") }
                Spacer()
            }
            
            
        }.padding(.vertical, 10)
    }
}


/*----------------------------------------------------------------------------------------------------
    MARK: - ConfigurationView
   ----------------------------------------------------------------------------------------------------*/

struct ConfigurationView: View {
    
    @EnvironmentObject private var preview: PreviewData
    
    var body: some View {
        if (preview.backend == nil) {
            Text("No video is being previewed")
        } else {
            VStack {
                BasicConfigSection(title: "Basic options", isCollapsible: false)
                
                Divider()
                
                Section(title: "Advanced options") {
                    ConfigRowView(option: preview.backend!.getOptionInformation("maximum_percentage")!)
                    ConfigRowView(option: preview.backend!.getOptionInformation("minimum_sampling")!)
                    ConfigRowView(option: preview.backend!.getOptionInformation("maximum_frames")!)
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
    
    @EnvironmentObject private var preview: PreviewData
    
    var body: some View {
        
        if (preview.backend == nil) {
            Text("No video is being previewed")
        } else {
            VStack {
                Text("Note: Editing the configuration files directly is not recommended. Changes to configuration files will not be reflected until a new video file is loaded.")
                    .noteFont()                                   // Small font
                    .fixedSize(horizontal: false, vertical: true) // For multiline text wrapping
                    .multilineTextAlignment(.leading)
                    
                ForEach(preview.backend!.getConfigFilePaths(), id: \.self) { configFilePath in
                    HStack {
                        ScrollView(.horizontal, showsIndicators: false, content: { Text(configFilePath).regularFont().foregroundColor(colorFaded) })
                        Spacer()
                        Button(action: { NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: configFilePath)]) }) {
                            Image(nsImage: NSImage(imageLiteralResourceName: NSImage.followLinkFreestandingTemplateName))
                        }.buttonStyle(BorderlessButtonStyle())
                        
                    }.padding(.leading)
                }
                Spacer()
            }.padding(.vertical, 10).padding(.horizontal, sectionHorizontalPadding)
        }
    }
}


/*----------------------------------------------------------------------------------------------------
    MARK: - PreferencesView
   ----------------------------------------------------------------------------------------------------*/

struct PreferencesView: View {
    
    @EnvironmentObject private var preview: PreviewData
    @EnvironmentObject private var settings:   UserSettings
    
    var body: some View {
        TabView {
            GUISettingsView()       .tabItem{ Text("Interface") }
            ConfigurationView()     .tabItem{ Text("Config options") }
            ConfigurationFilesView().tabItem{ Text("Config files") }
        }.frame(width: 400, height: 475).padding(.all, 15)
    }
}
