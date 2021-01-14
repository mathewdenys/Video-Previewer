//
//  SidePanel.swift
//  Video-Previewer-GUI
//
//  Created by Mathew Denys on 13/01/21.
//

import SwiftUI

var testInfo1 = [
    InfoPair(id: "id1", value: "vid_val1"),
    InfoPair(id: "id2", value: "vid_val2"),
    InfoPair(id: "idlong", value: "vid_val3"),
]

var testInfo2 = [
    InfoPair(id: "id1", value: "frame_val1"),
    InfoPair(id: "id2", value: "frame_val2"),
    InfoPair(id: "idlong", value: "frame_val3"),
]

var testInfo3 = [
    InfoPair(id: "id1", value: "config_val1"),
    InfoPair(id: "id2", value: "config_val2"),
    InfoPair(id: "idlong", value: "config_val3"),
]


struct InfoPair: Identifiable {
    var id:    String;
    var value: String;
}

struct InfoRow: View {
    
    var id:    String
    var value: String
    
    var body: some View {
        HStack {
            Text(id)
                .foregroundColor(Color.gray)
            
            Text(value)
                .foregroundColor(Color.black)
        }
    }
    
    init(info: InfoPair) {
        id    = info.id;
        value = info.value;
    }
}

struct InfoFrame: View {
    var title: String;
    var info:  [InfoPair];
    
    var body: some View {
        VStack {
            Text(title)
                .font(.headline)
                .multilineTextAlignment(.leading)
            List(info) { i in InfoRow(info: i) }
        }
    }
    
}

struct SidePanel: View {
    var body: some View {
        VStack(alignment: .leading) {
            InfoFrame(title: "Video Information",     info: testInfo1)
            InfoFrame(title: "Frame Information",     info: testInfo2)
            Spacer()
            InfoFrame(title: "Configuration Options", info: testInfo3)
        }
    }
}

struct SidePanel_Previews: PreviewProvider {
    static var previews: some View {
        SidePanel()
    }
}
