//
//  Preferences.swift
//  Video-Previewer-GUI
//
//  Created by Mathew Denys on 2/02/21.
//

import SwiftUI


struct PreferencesView: View {
    @EnvironmentObject var globalVars: GlobalVars
    
    var body: some View {
        
        if (globalVars.vp == nil) {
            Text("No video is being previewed")
        } else {
            VStack {
                
                CollapsibleBlockView(title: "Basic options") {
                    Group {
                        ConfigRowView(option: globalVars.vp!.getOptionInformation("frame_info_overlay")!)
                        ConfigRowView(option: globalVars.vp!.getOptionInformation("action_on_hover")!)
                    }
                    .padding(.horizontal, 5.0)
                    .padding(.vertical,   2.0)
                }
                
                CollapsibleBlockView(title: "Advanced options") {
                    Group {
                        ConfigRowView(option: globalVars.vp!.getOptionInformation("maximum_frames")!)
                        ConfigRowView(option: globalVars.vp!.getOptionInformation("maximum_percentage")!)
                        ConfigRowView(option: globalVars.vp!.getOptionInformation("minimum_sampling")!)
                    }
                    .padding(.horizontal, 5.0)
                    .padding(.vertical,   2.0)
                }
                
                CollapsibleBlockView(title: "Edit configuration files directly") {
                    ForEach(globalVars.vp!.getConfigFilePaths(), id: \.self) { configFilePath in
                        HStack {
                            ScrollView(.horizontal, showsIndicators: false, content: {
                                Text(configFilePath)
                            })
                            
                            Spacer()
                            Button("Edit", action: {
                                NSWorkspace.shared.openFile(configFilePath, withApplication: "Finder")
                            })
                        }
                    }
                }
            }
            .frame(width: 400)
            .padding(.all, 10)
        }
    }
}

struct Preferences_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
    }
}
