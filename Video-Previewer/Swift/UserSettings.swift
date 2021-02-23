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

let defaultSettingsSidePanelVisibleFile    = true      // Whether the the "File information" section is shown in the side panel
let defaultSettingsSidePanelVisibleFrame   = true      // Whether the the "Frame information" section is shown in the side panel
let defaultSettingsSidePanelVisibleConfig  = true      // Whether the the "Configuration options" section is shown in the side panel

let defaultSettingsFileInfoPath            = true      // Whether "Path" is displayed under "File Information" in the side panel
let defaultSettingsFileInfoEncoding        = false     // Whether "Encoding" is displayed under "File Information" in the side panel
let defaultSettingsFileInfoFramerate       = true      // Whether "Frame rate" is displayed under "File Information" in the side panel
let defaultSettingsFileInfoLength          = true      // Whether "Length" is displayed under "File Information" in the side panel
let defaultSettingsFileInfoFrames          = true      // Whether "Frames" is displayed under "File Information" in the side panel
let defaultSettingsFileInfoDimensions      = false     // Whether "Dimensions" is displayed under "File Information" in the side panel

let defaultSettingsFrameInfoTimestamp      = true      // Whether "Timestamp" is displayed under "Frame Information" in the side panel
let defaultSettingsFrameInfoNumber         = true      // Whether "Frame number" is displayed under "Frame Information" in the side panel

let defaultSettingsFrameBorderColor        = colorBlue // The color of the border around a selected frame
let defaultSettingsFrameBorderThickness    = 5.0       // The width of the border around a selected frame

let defaultSettingsPreviewSpaceBetweenRows = 10.0      // The vertical spacing between rows in the preview
let defaultSettingsPreviewSpaceBetweenCols = 0.0       // The horizontal spacing between columns in the preview



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
            color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: colorData) ?? defaultSettingsFrameBorderColor
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
    @Published var sidePanelVisibleFile:    Bool    { didSet { UserDefaults.standard.set(sidePanelVisibleFile,   forKey: "sidePanelVisibleFile") } }
    @Published var sidePanelVisibleFrame:   Bool    { didSet { UserDefaults.standard.set(sidePanelVisibleFrame,   forKey: "sidePanelVisibleFrame") } }
    @Published var sidePanelVisibleConfig:  Bool    { didSet { UserDefaults.standard.set(sidePanelVisibleConfig,  forKey: "sidePanelVisibleConfig") } }
    @Published var fileInfoPath:            Bool    { didSet { UserDefaults.standard.set(fileInfoPath,            forKey: "fileInfoPath") } }
    @Published var fileInfoEncoding:        Bool    { didSet { UserDefaults.standard.set(fileInfoEncoding,        forKey: "fileInfoEncoding") } }
    @Published var fileInfoFramerate:       Bool    { didSet { UserDefaults.standard.set(fileInfoFramerate,       forKey: "fileInfoFramerate") } }
    @Published var fileInfoLength:          Bool    { didSet { UserDefaults.standard.set(fileInfoLength,          forKey: "fileInfoLength") } }
    @Published var fileInfoFrames:          Bool    { didSet { UserDefaults.standard.set(fileInfoFrames,          forKey: "fileInfoFrames") } }
    @Published var fileInfoDimensions:      Bool    { didSet { UserDefaults.standard.set(fileInfoDimensions,      forKey: "fileInfoDimensions") } }
    @Published var frameInfoTimestamp:      Bool    { didSet { UserDefaults.standard.set(frameInfoTimestamp,      forKey: "frameInfoTimestamp") } }
    @Published var frameInfoNumber:         Bool    { didSet { UserDefaults.standard.set(frameInfoNumber,         forKey: "frameInfoNumber") } }
    @Published var frameBorderThickness:    Double  { didSet { UserDefaults.standard.set(frameBorderThickness,    forKey: "frameBorderThickness") } }
    @Published var frameBorderColor:        NSColor { didSet { UserDefaults.standard.set(color: frameBorderColor, forKey: "frameBorderColor") } }
    @Published var previewSpaceBetweenRows: Double  { didSet { UserDefaults.standard.set(previewSpaceBetweenRows, forKey: "previewSpaceBetweenRows") } }
    @Published var previewSpaceBetweenCols: Double  { didSet { UserDefaults.standard.set(previewSpaceBetweenCols, forKey: "previewSpaceBetweenCols") } }
    
    func resetToDefaultsSidePanel() {
        fileInfoPath           = defaultSettingsFileInfoPath
        fileInfoEncoding       = defaultSettingsFileInfoEncoding
        fileInfoFramerate      = defaultSettingsFileInfoFramerate
        fileInfoLength         = defaultSettingsFileInfoLength
        fileInfoFrames         = defaultSettingsFileInfoFrames
        fileInfoDimensions     = defaultSettingsFileInfoDimensions
        frameInfoTimestamp     = defaultSettingsFrameInfoTimestamp
        frameInfoNumber        = defaultSettingsFrameInfoNumber
        sidePanelVisibleFile  = defaultSettingsSidePanelVisibleFile
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
    
    init() {
        // On initialization, load values that the user has set. If no value has been set, use the default value for each setting
        sidePanelVisibleFile    = UserDefaults.standard.object(forKey: "sidePanelVisibleFil")     as? Bool   ?? defaultSettingsSidePanelVisibleFile
        sidePanelVisibleFrame   = UserDefaults.standard.object(forKey: "sidePanelVisibleFrame")   as? Bool   ?? defaultSettingsSidePanelVisibleFrame
        sidePanelVisibleConfig  = UserDefaults.standard.object(forKey: "sidePanelVisibleConfig")  as? Bool   ?? defaultSettingsSidePanelVisibleConfig
        fileInfoPath            = UserDefaults.standard.object(forKey: "fileInfoPath")            as? Bool   ?? defaultSettingsFileInfoPath
        fileInfoEncoding        = UserDefaults.standard.object(forKey: "fileInfoEncoding")        as? Bool   ?? defaultSettingsFileInfoEncoding
        fileInfoFramerate       = UserDefaults.standard.object(forKey: "fileInfoFramerate")       as? Bool   ?? defaultSettingsFileInfoFramerate
        fileInfoLength          = UserDefaults.standard.object(forKey: "fileInfoLength")          as? Bool   ?? defaultSettingsFileInfoLength
        fileInfoFrames          = UserDefaults.standard.object(forKey: "fileInfoFrames")          as? Bool   ?? defaultSettingsFileInfoFrames
        fileInfoDimensions      = UserDefaults.standard.object(forKey: "fileInfoDimensions")      as? Bool   ?? defaultSettingsFileInfoDimensions
        frameInfoTimestamp      = UserDefaults.standard.object(forKey: "frameInfoTimestamp")      as? Bool   ?? defaultSettingsFrameInfoTimestamp
        frameInfoNumber         = UserDefaults.standard.object(forKey: "frameInfoNumber")         as? Bool   ?? defaultSettingsFrameInfoNumber
        frameBorderColor        = UserDefaults.standard.color(forKey:  "frameBorderColor")                   ?? defaultSettingsFrameBorderColor
        frameBorderThickness    = UserDefaults.standard.object(forKey: "frameBorderThickness")    as? Double ?? defaultSettingsFrameBorderThickness
        previewSpaceBetweenRows = UserDefaults.standard.object(forKey: "previewSpaceBetweenRows") as? Double ?? defaultSettingsPreviewSpaceBetweenRows
        previewSpaceBetweenCols = UserDefaults.standard.object(forKey: "previewSpaceBetweenCols") as? Double ?? defaultSettingsPreviewSpaceBetweenCols
    }
}
