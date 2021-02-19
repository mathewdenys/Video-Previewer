//
//  UserSettings.swift
//  Video-Previewer-GUI
//
//  Created by Mathew Denys on 19/02/21.
//

import SwiftUI

// userDefaults can only save certain types of data
// The following extensions to UserDefaults are required to easily save colours (i.e. NSColor)
// Ideally this would be achieved with SwiftUI Colors, but for now I cna't get it to work, so NSColor will have to do
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


class UserSettings: ObservableObject {
    
    @Published var frameBorderThickness:    Double  { didSet { UserDefaults.standard.set(frameBorderThickness,    forKey: "frameBorderThickness") } }     // The width of the border around a selected frame
    @Published var frameBorderColor:        NSColor { didSet { UserDefaults.standard.set(color: frameBorderColor, forKey: "frameBorderColor") } }         // The color of the border around a selected frame
        
    @Published var previewSpaceBetweenRows: Double  { didSet { UserDefaults.standard.set(previewSpaceBetweenRows,  forKey: "previewSpaceBetweenRows") } } // The vertical spacing between rows in the preview
    
    @Published var videoInfoPath:           Bool    { didSet { UserDefaults.standard.set(videoInfoPath,            forKey: "videoInfoPath") } }           // Whether "Path" is displayed under "Video Information" in the side panel
    @Published var videoInfoEncoding:       Bool    { didSet { UserDefaults.standard.set(videoInfoEncoding,        forKey: "videoInfoEncoding") } }       // Whether "Encoding" is displayed under "Video Information" in the side panel
    @Published var videoInfoFramerate:      Bool    { didSet { UserDefaults.standard.set(videoInfoFramerate,       forKey: "videoInfoFramerate") } }      // Whether "Frame rate" is displayed under "Video Information" in the side panel
    @Published var videoInfoLength:         Bool    { didSet { UserDefaults.standard.set(videoInfoLength,          forKey: "videoInfoLength") } }         // Whether "Length" is displayed under "Video Information" in the side panel
    @Published var videoInfoFrames:         Bool    { didSet { UserDefaults.standard.set(videoInfoFrames,          forKey: "videoInfoFrames") } }         // Whether "Frames" is displayed under "Video Information" in the side panel
    @Published var videoInfoDimensions:     Bool    { didSet { UserDefaults.standard.set(videoInfoDimensions,      forKey: "videoInfoDimensions") } }     // Whether "Dimensions" is displayed under "Video Information" in the side panel
    
    @Published var frameInfoTimestamp:      Bool    { didSet { UserDefaults.standard.set(frameInfoTimestamp,       forKey: "frameInfoTimestamp") } }      // Whether "Timestamp" is displayed under "Frame Information" in the side panel
    @Published var frameInfoNumber:         Bool    { didSet { UserDefaults.standard.set(frameInfoNumber,          forKey: "frameInfoNumber") } }         // Whether "Frame number" is displayed under "Frame Information" in the side panel
    
    init() {
        // On initialization, load values that the user has set. If no value has been set, use the default value for each setting
        self.frameBorderColor        = UserDefaults.standard.color(forKey: "frameBorderColor")                    ?? defaultSettingsFrameBorderColor
        self.frameBorderThickness    = UserDefaults.standard.object(forKey: "frameBorderThickness")    as? Double ?? defaultSettingsFrameBorderThickness
        self.previewSpaceBetweenRows = UserDefaults.standard.object(forKey: "previewSpaceBetweenRows") as? Double ?? defaultSettingsPreviewSpaceBetweenRows
        self.videoInfoPath           = UserDefaults.standard.object(forKey: "videoInfoPath")           as? Bool   ?? defaultSettingsVideoInfoPath
        self.videoInfoEncoding       = UserDefaults.standard.object(forKey: "videoInfoEncoding")       as? Bool   ?? defaultSettingsVideoInfoEncoding
        self.videoInfoFramerate      = UserDefaults.standard.object(forKey: "videoInfoFramerate")      as? Bool   ?? defaultSettingsVideoInfoFramerate
        self.videoInfoLength         = UserDefaults.standard.object(forKey: "videoInfoLength")         as? Bool   ?? defaultSettingsVideoInfoLength
        self.videoInfoFrames         = UserDefaults.standard.object(forKey: "videoInfoFrames")         as? Bool   ?? defaultSettingsVideoInfoFrames
        self.videoInfoDimensions     = UserDefaults.standard.object(forKey: "videoInfoDimensions")     as? Bool   ?? defaultSettingsVideoInfoDimensions
        self.frameInfoTimestamp      = UserDefaults.standard.object(forKey: "frameInfoTimestamp")      as? Bool   ?? defaultSettingsFrameInfoTimestamp
        self.frameInfoNumber         = UserDefaults.standard.object(forKey: "frameInfoNumber")         as? Bool   ?? defaultSettingsFrameInfoNumber
    }
}
