//
//  Constants.swift
//  Video-Previewer-GUI
//
//  Created by Mathew Denys on 3/02/21.
//

import SwiftUI

let infoDescriptionWidth     = CGFloat(90)           // The width of the first column in the Information sections
let configDescriptionWidth   = CGFloat(140)          // The width of the first column in the Configuration sections
let settingsDescriptionWidth = CGFloat(130)          // The width of the first column in the Settings sections
let horiontalRowSpacing      = CGFloat(8.0)          // The spacing between columns in info row and config rows
let infoRowVPadding          = CGFloat(5.0)          // The vertical padding around the content of an InfoRowView
let configRowVPadding        = CGFloat(0.0)          // The vertical padding around the content of an ConfigRowView
let sectionPaddingHorizontal = CGFloat(10.0)         // The horizontal padding abour "sections" (in the side panel and preferences window)

let minFrameWidth            = 100.0                 // The minimum width of a frame in the preview
let maxFrameWidth            = 500.0                 // The maximum width of a frame in the preview

let previewPadding           = 15.0                  // The padding around the frames in the video preview (the whole preview, not individual frames)
let scrollBarWidth           = 15.0                  // The width of a scrollbar in a ScrollView
let sidePanelWidth           = 300.0                 // The miniumum width of the side panel

let pasteBoard               = NSPasteboard.general  // For copy-and-pasting
