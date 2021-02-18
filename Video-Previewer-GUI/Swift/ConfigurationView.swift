//
//  ConfigurationView.swift
//  Video-Previewer-GUI
//
//  Created by Mathew Denys on 2/02/21.
//

import SwiftUI


struct ConfigurationView: View {
    
    @EnvironmentObject
    var globalVars: GlobalVars
    
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
                
                Divider()
                
                CollapsibleBlockView(title: "Configuration Files", expandedByDefault: false) {
                    Text("Note: Editing the configuration files directly is not recommended. Changes to configuration files will not be reflected until a new video file is loaded.")
                        .font(fontNote)                               // small font
                        .fixedSize(horizontal: false, vertical: true) // for multi-line text
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
                }
            }
            .frame(width: 400)
            .padding(.vertical, 10)
        }
    }
}

struct Preferences_Previews: PreviewProvider {
    static var previews: some View {
        ConfigurationView()
    }
}
