//
//  UserSettings.swift
//  Video-Previewer-GUI
//
//  Created by Mathew Denys on 19/02/21.
//

import SwiftUI

/*----------------------------------------------------------------------------------------------------
    MARK: - Default values
   ----------------------------------------------------------------------------------------------------*/

let defaultSettingsSidePanelVisibleVideo   = true           // Whether the the "Video information" section is shown in the side panel
let defaultSettingsSidePanelVisibleFrame   = true           // Whether the the "Frame information" section is shown in the side panel
let defaultSettingsSidePanelVisibleConfig  = true           // Whether the the "Configuration options" section is shown in the side panel

let defaultSettingsVideoInfoPath           = true           // Whether "Path" is displayed under "Video Information" in the side panel
let defaultSettingsVideoInfoEncoding       = false          // Whether "Encoding" is displayed under "Video Information" in the side panel
let defaultSettingsVideoInfoFramerate      = true           // Whether "Frame rate" is displayed under "Video Information" in the side panel
let defaultSettingsVideoInfoLength         = true           // Whether "Length" is displayed under "Video Information" in the side panel
let defaultSettingsVideoInfoFrames         = true           // Whether "Frames" is displayed under "Video Information" in the side panel
let defaultSettingsVideoInfoDimensions     = false          // Whether "Dimensions" is displayed under "Video Information" in the side panel

let defaultSettingsFrameInfoTimestamp      = true           // Whether "Timestamp" is displayed under "Frame Information" in the side panel
let defaultSettingsFrameInfoNumber         = true           // Whether "Frame number" is displayed under "Frame Information" in the side panel

let defaultSettingsFrameBorderColor        = colorBlue      // The color of the border around a selected frame
let defaultSettingsFrameBorderThickness    = 5.0            // The width of the border around a selected frame

let defaultSettingsPreviewSpaceBetweenRows = 10.0           // The vertical spacing between rows in the preview
let defaultSettingsPreviewSpaceBetweenCols = 0.0            // The horizontal spacing between columns in the preview



/*----------------------------------------------------------------------------------------------------
    MARK: - UserDefaults extension
        UserDefaults can only save certain types of data. The following extensions to UserDefaults are
        required to easily save colours (i.e. NSColor). I could not get this to work with Color, hence
        why NSColor is used for defaultSettingsFrameBorderColor
   ----------------------------------------------------------------------------------------------------*/

extension UserDefaults {
    
    func color(forKey key: String) -> NSColor? {
        var color: NSColor?
        if let colorData = data(forKey: key) {
            color = try! NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: colorData)
        }
        return color
    }

    func set(color: NSColor?, forKey key: String) {
        var colorData: NSData?
        if let color = color {
            colorData = try? NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: true) as NSData?
        }
        set(colorData, forKey: key)
    }
}


/*----------------------------------------------------------------------------------------------------
    MARK: - UserSettings
   ----------------------------------------------------------------------------------------------------*/

class UserSettings: ObservableObject {
    
    // Whenever a value is set, it is saved to UserDefaults
    @Published var sidePanelVisibleVideo:   Bool    { didSet { UserDefaults.standard.set(sidePanelVisibleVideo,   forKey: "sidePanelVisibleVideo") } }
    @Published var sidePanelVisibleFrame:   Bool    { didSet { UserDefaults.standard.set(sidePanelVisibleFrame,   forKey: "sidePanelVisibleFrame") } }
    @Published var sidePanelVisibleConfig:  Bool    { didSet { UserDefaults.standard.set(sidePanelVisibleConfig,  forKey: "sidePanelVisibleConfig") } }
    @Published var videoInfoPath:           Bool    { didSet { UserDefaults.standard.set(videoInfoPath,           forKey: "videoInfoPath") } }
    @Published var videoInfoEncoding:       Bool    { didSet { UserDefaults.standard.set(videoInfoEncoding,       forKey: "videoInfoEncoding") } }
    @Published var videoInfoFramerate:      Bool    { didSet { UserDefaults.standard.set(videoInfoFramerate,      forKey: "videoInfoFramerate") } }
    @Published var videoInfoLength:         Bool    { didSet { UserDefaults.standard.set(videoInfoLength,         forKey: "videoInfoLength") } }
    @Published var videoInfoFrames:         Bool    { didSet { UserDefaults.standard.set(videoInfoFrames,         forKey: "videoInfoFrames") } }
    @Published var videoInfoDimensions:     Bool    { didSet { UserDefaults.standard.set(videoInfoDimensions,     forKey: "videoInfoDimensions") } }
    @Published var frameInfoTimestamp:      Bool    { didSet { UserDefaults.standard.set(frameInfoTimestamp,      forKey: "frameInfoTimestamp") } }
    @Published var frameInfoNumber:         Bool    { didSet { UserDefaults.standard.set(frameInfoNumber,         forKey: "frameInfoNumber") } }
    @Published var frameBorderThickness:    Double  { didSet { UserDefaults.standard.set(frameBorderThickness,    forKey: "frameBorderThickness") } }
    @Published var frameBorderColor:        NSColor { didSet { UserDefaults.standard.set(color: frameBorderColor, forKey: "frameBorderColor") } }
    @Published var previewSpaceBetweenRows: Double  { didSet { UserDefaults.standard.set(previewSpaceBetweenRows, forKey: "previewSpaceBetweenRows") } }
    @Published var previewSpaceBetweenCols: Double  { didSet { UserDefaults.standard.set(previewSpaceBetweenCols, forKey: "previewSpaceBetweenCols") } }
    
    func resetToDefaultsSidePanel() {
        videoInfoPath          = defaultSettingsVideoInfoPath
        videoInfoEncoding      = defaultSettingsVideoInfoEncoding
        videoInfoFramerate     = defaultSettingsVideoInfoFramerate
        videoInfoLength        = defaultSettingsVideoInfoLength
        videoInfoFrames        = defaultSettingsVideoInfoFrames
        videoInfoDimensions    = defaultSettingsVideoInfoDimensions
        frameInfoTimestamp     = defaultSettingsFrameInfoTimestamp
        frameInfoNumber        = defaultSettingsFrameInfoNumber
        sidePanelVisibleVideo  = defaultSettingsSidePanelVisibleVideo
        sidePanelVisibleFrame  = defaultSettingsSidePanelVisibleFrame
        sidePanelVisibleConfig = defaultSettingsSidePanelVisibleConfig
    }
    
    func resetToDefaultsSelectedFrames() {
        frameBorderColor     = defaultSettingsFrameBorderColor
        frameBorderThickness = defaultSettingsFrameBorderThickness
    }
    
    func resetToDefaultsSpacing() {
        previewSpaceBetweenRows = defaultSettingsPreviewSpaceBetweenRows
        previewSpaceBetweenCols = defaultSettingsPreviewSpaceBetweenCols
    }
    
    func resetToDefaultsAll() {
        resetToDefaultsSidePanel()
        resetToDefaultsSelectedFrames()
        resetToDefaultsSpacing()
    }
    
    init() {
        // On initialization, load values that the user has set. If no value has been set, use the default value for each setting
        sidePanelVisibleVideo   = UserDefaults.standard.object(forKey: "sidePanelVisibleVideo")   as? Bool   ?? defaultSettingsSidePanelVisibleVideo
        sidePanelVisibleFrame   = UserDefaults.standard.object(forKey: "sidePanelVisibleFrame")   as? Bool   ?? defaultSettingsSidePanelVisibleFrame
        sidePanelVisibleConfig  = UserDefaults.standard.object(forKey: "sidePanelVisibleConfig")  as? Bool   ?? defaultSettingsSidePanelVisibleConfig
        videoInfoPath           = UserDefaults.standard.object(forKey: "videoInfoPath")           as? Bool   ?? defaultSettingsVideoInfoPath
        videoInfoEncoding       = UserDefaults.standard.object(forKey: "videoInfoEncoding")       as? Bool   ?? defaultSettingsVideoInfoEncoding
        videoInfoFramerate      = UserDefaults.standard.object(forKey: "videoInfoFramerate")      as? Bool   ?? defaultSettingsVideoInfoFramerate
        videoInfoLength         = UserDefaults.standard.object(forKey: "videoInfoLength")         as? Bool   ?? defaultSettingsVideoInfoLength
        videoInfoFrames         = UserDefaults.standard.object(forKey: "videoInfoFrames")         as? Bool   ?? defaultSettingsVideoInfoFrames
        videoInfoDimensions     = UserDefaults.standard.object(forKey: "videoInfoDimensions")     as? Bool   ?? defaultSettingsVideoInfoDimensions
        frameInfoTimestamp      = UserDefaults.standard.object(forKey: "frameInfoTimestamp")      as? Bool   ?? defaultSettingsFrameInfoTimestamp
        frameInfoNumber         = UserDefaults.standard.object(forKey: "frameInfoNumber")         as? Bool   ?? defaultSettingsFrameInfoNumber
        frameBorderColor        = UserDefaults.standard.color(forKey:  "frameBorderColor")                   ?? defaultSettingsFrameBorderColor
        frameBorderThickness    = UserDefaults.standard.object(forKey: "frameBorderThickness")    as? Double ?? defaultSettingsFrameBorderThickness
        previewSpaceBetweenRows = UserDefaults.standard.object(forKey: "previewSpaceBetweenRows") as? Double ?? defaultSettingsPreviewSpaceBetweenRows
        previewSpaceBetweenCols = UserDefaults.standard.object(forKey: "previewSpaceBetweenCols") as? Double ?? defaultSettingsPreviewSpaceBetweenCols
    }
}
