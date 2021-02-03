//
//  Preferences.swift
//  Video-Previewer-GUI
//
//  Created by Mathew Denys on 2/02/21.
//

import SwiftUI


struct PreferencesView: View {
    
    @EnvironmentObject
    var globalVars: GlobalVars
    
    var body: some View {
        
        if (globalVars.vp == nil) {
            Text("No video is being previewed")
        } else {
            VStack {
                CollapsibleBlockView(title: "Basic options") {
                    ConfigRowView(option: globalVars.vp!.getOptionInformation("frame_info_overlay")!)
                    ConfigRowView(option: globalVars.vp!.getOptionInformation("action_on_hover")!)
                }
                
                Divider()
                
                CollapsibleBlockView(title: "Advanced options") {
                    ConfigRowView(option: globalVars.vp!.getOptionInformation("maximum_frames")!)
                    ConfigRowView(option: globalVars.vp!.getOptionInformation("maximum_percentage")!)
                    ConfigRowView(option: globalVars.vp!.getOptionInformation("minimum_sampling")!)
                }
                
                Divider()
                
                CollapsibleBlockView(title: "Configuration Files") {
                    Text("Note: Editing the configuration files directly is not recommended. Changes to configuration files will not be reflected until a new video file is loaded.")
                        .font(.caption)                               // small font
                        .fixedSize(horizontal: false, vertical: true) // for multi-line text
                        .multilineTextAlignment(.leading)
                        
                    ForEach(globalVars.vp!.getConfigFilePaths(), id: \.self) { configFilePath in
                        HStack {
                            ScrollView(.horizontal, showsIndicators: false, content: { Text(configFilePath).foregroundColor(colorFaded) })
                            Spacer()
                            Button(action: { NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: configFilePath)]) }) {
                                Image(nsImage: NSImage(imageLiteralResourceName: NSImage.followLinkFreestandingTemplateName))
                            }.buttonStyle(BorderlessButtonStyle())
                            
                        }.padding(.leading)
                    }
                }
            }
            .frame(width: 400)
            .padding(.vertical)
        }
    }
}

struct Preferences_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
    }
}
