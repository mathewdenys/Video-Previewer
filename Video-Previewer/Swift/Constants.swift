//
//  Constants.swift
//  Video-Previewer-GUI
//
//  Created by Mathew Denys on 3/02/21.
//

import SwiftUI


let infoDescriptionWidth     = CGFloat(90)           // The width of the first column in Information sections
let configDescriptionWidth   = CGFloat(140)          // The width of the first column in Configuration sections
let settingsDescriptionWidth = CGFloat(75)           // The width of the first column in Settings sections

let horiontalRowSpacing      = CGFloat(8.0)          // The spacing between columns in InfoRowViews and ConfigRowViews

let infoRowBottomPadding     = CGFloat(10.0)         // The padding below the content of an InfoRowView
let configRowBottomPadding   = CGFloat(0.0)          // The padding below the content of an ConfigRowView

let sectionHorizontalPadding = CGFloat(10.0)         // The horizontal padding abour "sections" (in the side panel and preferences window)

let previewPadding           = 15.0                  // The padding around the frames in the video preview (the whole preview, not individual frames)
let scrollBarWidth           = 15.0                  // The width of a scrollbar in a ScrollView
let sidePanelWidth           = 300.0                 // The miniumum width of the side panel

let minFrameWidth            = 100.0                 // The minimum width of a frame in the preview
let maxFrameWidth            = 500.0                 // The maximum width of a frame in the preview


let pasteBoard               = NSPasteboard.general  // For copy-and-pasting
