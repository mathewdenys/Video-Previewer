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
                .frame(maxWidth: 50, alignment: .trailing)
            Text(value)
                .foregroundColor(Color.black)
                .frame(maxWidth: .infinity, alignment: .leading)
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
                .fontWeight(.bold)
                .padding(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            ForEach(info) { i in InfoRow(info: i) }
                .padding(.horizontal, 30.0)
                .padding(.vertical, 5.0)
            //List(info) { i in InfoRow(info: i) }
        }
    }
    
}

struct SidePanel: View {
    var body: some View {
        HStack(spacing:0) {
            Divider()
            
            VStack(alignment: .leading) {
                InfoFrame(title: "Video Information",     info: testInfo1)
                Divider()
                InfoFrame(title: "Frame Information",     info: testInfo2)
                Spacer()
                Divider()
                InfoFrame(title: "Configuration Options", info: testInfo3)
            }
            .padding(.vertical, 10.0)
        }
        
    }
}

struct SidePanel_Previews: PreviewProvider {
    static var previews: some View {
        SidePanel()
    }
}
