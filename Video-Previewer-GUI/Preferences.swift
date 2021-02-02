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
                Group {
                    Text("Basic")
                        .fontWeight(.bold)
                        .foregroundColor(colorBold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    ConfigRowView(option: globalVars.vp!.getOptionInformation("maximum_frames")!)
                    ConfigRowView(option: globalVars.vp!.getOptionInformation("maximum_percentage")!)
                    ConfigRowView(option: globalVars.vp!.getOptionInformation("minimum_sampling")!)
                    Divider()
                    ConfigRowView(option: globalVars.vp!.getOptionInformation("frame_info_overlay")!)
                    ConfigRowView(option: globalVars.vp!.getOptionInformation("action_on_hover")!)
                    
                    Text("Advanced")
                        .fontWeight(.bold)
                        .foregroundColor(colorBold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    ConfigRowView(option: globalVars.vp!.getOptionInformation("maximum_percentage")!)
                    
                }
                .padding(.horizontal, 3.0)
                .padding(.vertical,   2.0)
                
                Text("Edit configuration files directly")
                    .fontWeight(.bold)
                    .foregroundColor(colorBold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
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
