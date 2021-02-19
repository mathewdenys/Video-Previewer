//
//  UserSettings.swift
//  Video-Previewer-GUI
//
//  Created by Mathew Denys on 19/02/21.
//

import SwiftUI

class UserSettings: ObservableObject {
    @Published var frameBorderColor     = Color.red
    @Published var frameBorderThickness = 3.0 // The width of the border displayed around a selected frame
    
    @Published var previewSpaceBetweenRows     = 10.0 // The vertical spacing between rows in the preview
    
    @Published var videoInfoPath        = true
    @Published var videoInfoEncoding    = false
    @Published var videoInfoFramerate   = true
    @Published var videoInfoLength      = true
    @Published var videoInfoFrames      = true
    @Published var videoInfoDimensions  = false
    
    @Published var frameInfoTimestamp   = true
    @Published var frameInfoNumber      = true
}
