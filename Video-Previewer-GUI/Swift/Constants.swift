//
//  Constants.swift
//  Video-Previewer-GUI
//
//  Created by Mathew Denys on 3/02/21.
//

import SwiftUI

// Colors are defined in Assets.xassets for light and dark themes
let colorBackground        = NSColor(named: NSColor.Name("colorBackground"))!
let colorOverlayForeground = Color(NSColor(named: NSColor.Name("colorOverlayForeground"))!)
let colorOverlayBackground = Color(NSColor(named: NSColor.Name("colorOverlayBackground"))!)
let colorBold              = Color(NSColor(named: NSColor.Name("colorBold"))!)
let colorFaded             = Color(NSColor(named: NSColor.Name("colorFaded"))!)
let colorInvisible         = Color(NSColor(named: NSColor.Name("colorInvisible"))!)

let frameBorderWidth       = CGFloat(3.0)          // The width of the border displayed around a selected frame
let infoDescriptionWidth   = CGFloat(100)          // The width of the first column in the information blocks
let configDescriptionWidth = CGFloat(120)          // The width of the first column in the configuration blocks

let minFrameWidth          = 100.0                 // The minimum width of a frame in the preview
let maxFrameWidth          = 500.0                 // The maximum width of a frame in the preview

let previewPadding         = 15.0                  // The padding around the frames in the video preview
let scrollBarWidth         = 15.0                  // The width of a scrollbar in a ScrollView
let sidePanelWidth         = 300.0                 // The miniumum width of the side panel

let infoRowVPadding        = CGFloat(5.0)          // The vertical padding around the content of an InfoRowView
let configRowVPadding      = CGFloat(0.0)          // The vertical padding around the content of an ConfigRowView

let pasteBoard             = NSPasteboard.general  // For copy-and-pasting
