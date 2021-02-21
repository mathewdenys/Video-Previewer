//
//  Constants.swift
//  Video-Previewer-GUI
//
//  Created by Mathew Denys on 3/02/21.
//

import SwiftUI

let defaultSettingsFrameBorderColor        = NSColor.gray
let defaultSettingsFrameBorderThickness    = 5.0
let defaultSettingsPreviewSpaceBetweenRows = 10.0
let defaultSettingsPreviewSpaceBetweenCols = 0.0
let defaultSettingsVideoInfoPath           = true
let defaultSettingsVideoInfoEncoding       = false
let defaultSettingsVideoInfoFramerate      = true
let defaultSettingsVideoInfoLength         = true
let defaultSettingsVideoInfoFrames         = true
let defaultSettingsVideoInfoDimensions     = false
let defaultSettingsFrameInfoTimestamp      = true
let defaultSettingsFrameInfoNumber         = true

// Colors are defined in Assets.xassets for light and dark themes
let colorBackground          = NSColor(named: NSColor.Name("colorBackground"))!
let colorOverlayForeground   = Color(NSColor(named: NSColor.Name("colorOverlayForeground"))!)
let colorOverlayBackground   = Color(NSColor(named: NSColor.Name("colorOverlayBackground"))!)
let colorBold                = Color(NSColor(named: NSColor.Name("colorBold"))!)
let colorFaded               = Color(NSColor(named: NSColor.Name("colorFaded"))!)
let colorInvisible           = Color(NSColor(named: NSColor.Name("colorInvisible"))!)

let fontHeading              = Font.system(size: 12, weight: .bold,     design: .default)
let fontRegular              = Font.system(size: 12, weight: .regular,  design: .default)
let fontNote                 = Font.system(size: 10, weight: .regular,  design: .default)

let infoDescriptionWidth     = CGFloat(90)           // The width of the first column in the information blocks
let configDescriptionWidth   = CGFloat(140)          // The width of the first column in the configuration blocks
let settingsDescriptionWidth = CGFloat(120)          // The width of the first column in the settings block
let horiontalRowSpacing      = CGFloat(8.0)          // The horizontal spacing between columns in info row and config rows
let infoRowVPadding          = CGFloat(5.0)          // The vertical padding around the content of an InfoRowView
let configRowVPadding        = CGFloat(0.0)          // The vertical padding around the content of an ConfigRowView
let sectionPaddingHorizontal = CGFloat(10.0)         // The horizontal padding abour "sections" (in the side panel and preferences window)

let minFrameWidth            = 100.0                 // The minimum width of a frame in the preview
let maxFrameWidth            = 500.0                 // The maximum width of a frame in the preview

let previewPadding           = 15.0                  // The padding around the frames in the video preview (the whole preview, not individual frames)
let scrollBarWidth           = 15.0                  // The width of a scrollbar in a ScrollView
let sidePanelWidth           = 300.0                 // The miniumum width of the side panel

let pasteBoard               = NSPasteboard.general  // For copy-and-pasting
