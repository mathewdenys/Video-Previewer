//
//  SidePanel.swift
//  Video-Previewer-GUI
//
//  Created by Mathew Denys on 13/01/21.
//

import SwiftUI

struct SidePanel: View {
    var body: some View {
        VStack(alignment: .leading) {
            VStack {
                Text("Video information")
                    .font(.headline)
                    .multilineTextAlignment(.leading)
                List {
                    InfoRow(id: "id",value: test?.getString() ?? "No text provided")
                    InfoRow(id: "id2",value: "val2")
                    InfoRow(id: "id",value: "val")
                    InfoRow(id: "id2",value: "val2")
                    InfoRow(id: "id",value: "val")
                    InfoRow(id: "id2",value: "val2")
                }
            }
            VStack {
                Text("Frame Information")
                    .font(.headline)
                    .multilineTextAlignment(.leading)
                List {
                    InfoRow(id: "id",value: "val")
                    InfoRow(id: "id2",value: "val2")
                    InfoRow(id: "id",value: "val")
                    InfoRow(id: "id2",value: "val2")
                    InfoRow(id: "id",value: "val")
                    InfoRow(id: "id2",value: "val2")
                }
            }
            
            Spacer()
            
            VStack {
                Text("Configuration Options")
                    .font(.headline)
                    .multilineTextAlignment(.leading)
                List {
                    InfoRow(id: "id",value: "val")
                    InfoRow(id: "id2",value: "val2")
                    InfoRow(id: "id",value: "val")
                    InfoRow(id: "id2",value: "val2")
                    InfoRow(id: "id",value: "val")
                    InfoRow(id: "id2",value: "val2")
                }
            }
        }
    }
}

struct SidePanel_Previews: PreviewProvider {
    static var previews: some View {
        SidePanel()
    }
}
