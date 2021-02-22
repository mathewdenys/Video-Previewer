//
//  PreferencesView.swift
//  Video-Previewer-GUI
//
//  Created by Mathew Denys on 2/02/21.
//

import SwiftUI

/*----------------------------------------------------------------------------------------------------
    MARK: - PreviewSettingsView
   ----------------------------------------------------------------------------------------------------*/

struct PreviewSettingsView: View {
    
    @EnvironmentObject private var preview:  PreviewData
    @EnvironmentObject private var settings: UserSettings
    
    var body: some View {
        VStack(alignment: .leading) {
            
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
            
            Spacer()
            
            
            /* ---------------------------------------------------------------------- */
            
//            Spacer()
//
//            HStack {
//                Spacer()
//                Button(action: settings.resetToDefaultsAll) { Text("Reset all to Defaults") }
//                Spacer()
//            }
            
            
        }.padding(.vertical, 10)
    }
}

/*----------------------------------------------------------------------------------------------------
    MARK: - FileSettingsView
   ----------------------------------------------------------------------------------------------------*/

struct FileSettingsView: View {
    
    @EnvironmentObject private var preview:  PreviewData
    @EnvironmentObject private var settings: UserSettings
    
    var body: some View {
        VStack(alignment: .leading) {
            
            Section(title: "Side panel", resetAction: settings.resetToDefaultsSidePanel) {
                
                VStack {
                    HStack(alignment: .top) {
                        Text("Show video file information in side panel")
                            .regularFont()
                        Toggle("", isOn: $settings.sidePanelVisibleVideo)
                            .regularFont()
                            .labelsHidden()
                        Spacer()
                    }
                    HStack {
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
                        .subsection()
                        .disabled(!settings.sidePanelVisibleVideo)
                    }
                }
            }
            
            Spacer()
        }.padding(.vertical, 10)
    }
}

/*----------------------------------------------------------------------------------------------------
    MARK: - FrameSettingsView
   ----------------------------------------------------------------------------------------------------*/


struct FrameSettingsView: View {
    
    @EnvironmentObject private var preview:  PreviewData
    @EnvironmentObject private var settings: UserSettings
    
    var body: some View {
        VStack(alignment: .leading) {
            
            Section(title: "Side panel", resetAction: settings.resetToDefaultsSidePanel) {
                
                VStack {
                    HStack(alignment: .top) {
                        Text("Show selected frame information in side panel")
                            .regularFont()
                        Toggle("", isOn: $settings.sidePanelVisibleFrame)
                            .regularFont()
                            .labelsHidden()
                        Spacer()
                    }
                    HStack {
                        Toggle("Timestamp", isOn: $settings.frameInfoTimestamp)
                            .regularFont()
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Toggle("Frame number", isOn: $settings.frameInfoNumber)
                        .regularFont()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .subsection()
                    .disabled(!settings.sidePanelVisibleFrame)
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
                            Text("Red")    .tag(colorRed)
                            Text("Blue")   .tag(colorBlue)
                            Text("Green")  .tag(colorGreen)
                            Text("Yellow") .tag(colorYellow)
                            Text("Orange") .tag(colorOrange)
                            Text("Purple") .tag(colorPurple)
                            Text("Gray")   .tag(colorGray)
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
            
            Spacer()
            
        }.padding(.vertical, 10)
    }
}


/*----------------------------------------------------------------------------------------------------
    MARK: - ConfigurationView
   ----------------------------------------------------------------------------------------------------*/

struct ConfigurationView: View {
    
    @EnvironmentObject private var preview:  PreviewData
    @EnvironmentObject private var settings: UserSettings
    
    var body: some View {
        if (preview.backend == nil) {
            Text("No video is being previewed")
        } else {
            VStack {
                Section(title: "Basic options", isCollapsible: false)  {
                    VStack {
                        HStack(alignment: .top) {
                            Text("Show in side panel")
                                .regularFont()
                            Toggle("", isOn: $settings.sidePanelVisibleConfig)
                                .regularFont()
                                .labelsHidden()
                            Spacer()
                        }
                        BasicConfigSection()
                            .subsection()
                    }
                }
                
                Divider()
                
                Section(title: "Advanced options") {
                    AdvancedConfigSection()
                        .subsection()
                        .padding(.top, 5)
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
            let configFilePaths = preview.backend!.getConfigFilePaths()
            
            VStack {
                if (configFilePaths!.isEmpty) {
                    Text("No associated configuration files found")
                        .regularFont()
                        .foregroundColor(colorFaded)
                    Spacer()
                } else {
                    Text("Note: Editing the configuration files directly is not recommended. Changes to configuration files will not be reflected until a new video file is loaded.")
                        .fixedSize(horizontal: false, vertical: true) // For multiline text wrapping
                        .multilineTextAlignment(.leading)
                        .noteFont()
                        
                    ForEach(preview.backend!.getConfigFilePaths(), id: \.self) { configFilePath in
                        HStack {
                            Text(configFilePath).regularFont().foregroundColor(colorFaded)
                                .fixedSize(horizontal: false, vertical: true) // For multiline text wrapping
                                .multilineTextAlignment(.leading)
                            Spacer()
                            Button(action: { NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: configFilePath)]) }) {
                                Image(nsImage: NSImage(imageLiteralResourceName: NSImage.followLinkFreestandingTemplateName))
                            }.buttonStyle(BorderlessButtonStyle())
                            
                        }.padding(.leading)
                    }
                    Spacer()
                }
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
            PreviewSettingsView()   .tabItem{ Text("Preview") }
            FileSettingsView()      .tabItem{ Text("File") }
            FrameSettingsView()     .tabItem{ Text("Frame") }
            ConfigurationView()     .tabItem{ Text("Config options") }
            ConfigurationFilesView().tabItem{ Text("Config files") }
        }
        .frame(width: 420, height: 450)
        .padding(.all, 15)
    }
}
