//
//  PreferencesView.swift
//  Video-Previewer-GUI
//
//  Created by Mathew Denys on 2/02/21.
//

import SwiftUI


/*----------------------------------------------------------------------------------------------------
    MARK: - GUISettingsView
   ----------------------------------------------------------------------------------------------------*/

struct ResetButton: View {
    
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(nsImage: NSImage(imageLiteralResourceName: NSImage.refreshTemplateName))
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .toolTip("Reset to defaults")
        }.buttonStyle(BorderlessButtonStyle())
    }
}

struct GUISettingsSection<Content: View>: View {
    
    let title: String
    let resetAction: () -> Void
    let content: Content
    
    init(title: String, resetAction: @escaping () -> Void, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.resetAction = resetAction
        self.content = content()
    }
    
    var body: some View {
        VStack {
            HStack {
                Text(title).font(fontHeading)
                Spacer()
                ResetButton(action:resetAction)
            }
            content
        }.padding(.horizontal, sectionPaddingHorizontal)
    }
}


struct GUISettingsView: View {
    
    @EnvironmentObject private var globalVars: GlobalVars
    @EnvironmentObject private var settings:   UserSettings
    
    func resetSettingsToDefaultsSidePanel() {
        settings.videoInfoPath       = defaultSettingsVideoInfoPath
        settings.videoInfoEncoding   = defaultSettingsVideoInfoEncoding
        settings.videoInfoFramerate  = defaultSettingsVideoInfoFramerate
        settings.videoInfoLength     = defaultSettingsVideoInfoLength
        settings.videoInfoFrames     = defaultSettingsVideoInfoFrames
        settings.videoInfoDimensions = defaultSettingsVideoInfoDimensions
        settings.frameInfoTimestamp  = defaultSettingsFrameInfoTimestamp
        settings.frameInfoNumber     = defaultSettingsFrameInfoNumber
    }
    
    func resetSettingsToDefaultsSelectedFrames() {
        settings.frameBorderColor     = defaultSettingsFrameBorderColor
        settings.frameBorderThickness = defaultSettingsFrameBorderThickness
    }
    
    func resetSettingsToDefaultSpacing() {
        settings.previewSpaceBetweenRows = defaultSettingsPreviewSpaceBetweenRows
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            
            GUISettingsSection(title: "Side Panel", resetAction: resetSettingsToDefaultsSidePanel) {
                VStack {
                    HStack(alignment: .top) {
                        Text("Video information")
                            .font(fontRegular)
                            .foregroundColor(colorFaded)
                            .frame(width: settingsDescriptionWidth, alignment: .trailing)
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
                    }.padding(.bottom, 5) // small gap so that "Video information" and "Frame information" settings are separated
                    
                    
                    HStack(alignment: .top) {
                        Text("Frame information")
                            .font(fontRegular)
                            .foregroundColor(colorFaded)
                            .frame(width: settingsDescriptionWidth, alignment: .trailing)
                        Toggle("Timestamp", isOn: $settings.frameInfoTimestamp)
                            .font(fontRegular)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Toggle("Frame number", isOn: $settings.frameInfoNumber)
                            .font(fontRegular)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            
            Divider()
            
            /* ---------------------------------------------------------------------- */
            
            GUISettingsSection(title: "Selected frame", resetAction: resetSettingsToDefaultsSelectedFrames) {
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
            
            GUISettingsSection(title: "Spacing between frames", resetAction: resetSettingsToDefaultSpacing) {
                HStack {
                    Text("Vertical")
                        .font(fontRegular)
                        .foregroundColor(colorFaded)
                        .frame(width: settingsDescriptionWidth, alignment: .trailing)
                    
                    Slider(value: $settings.previewSpaceBetweenRows, in: 0...50, step: 5)
                        .frame(maxWidth: .infinity, alignment: .leading)
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
        }.frame(width: 400, height: 450).padding(.all, 15)
    }
}
