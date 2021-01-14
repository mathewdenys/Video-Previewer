//
//  SidePanel.swift
//  Video-Previewer-GUI
//
//  Created by Mathew Denys on 13/01/21.
//

import SwiftUI

// For text and shapes
let colorNearBlack = Color(red: 0.2, green: 0.2, blue: 0.2, opacity: 1.0);


var testInfo1 = [
    InfoPair(id: "id1", value: "vid_val1"),
    InfoPair(id: "id2", value: "vid_val2"),
    InfoPair(id: "idlong", value: "vid_val3"),
]

var testInfo2 = [
    InfoPair(id: "id1", value: "frame_val1"),
    InfoPair(id: "id2", value: "frame_val2"),
    InfoPair(id: "idlong", value: "frame_val3"),
    InfoPair(id: "id1", value: "frame_val1"),
    InfoPair(id: "id2", value: "frame_val2"),
    InfoPair(id: "idlong", value: "frame_val3"),
    InfoPair(id: "id1", value: "frame_val1"),
    InfoPair(id: "id2", value: "frame_val2"),
    InfoPair(id: "idlong", value: "frame_val3"),
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

struct InfoRow: View, Identifiable {
    
    var id:    String
    var value: String
    
    var body: some View {
        HStack {
            Text(id)
                .foregroundColor(Color.gray)
                .frame(maxWidth: 50, alignment: .trailing)
            Text(value)
                .foregroundColor(colorNearBlack)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    init(info: InfoPair) {
        id    = info.id;
        value = info.value;
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))

        return path
    }
}

struct InfoBlock: View {
    var title: String;
    var info:  [InfoPair];
    
    @State private var isExpanded = true;
    
    var body: some View {
        VStack {
            HStack {
                Text(title)
                    .fontWeight(.bold)
                    .foregroundColor(colorNearBlack)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Triangle()
                    .rotation(Angle(degrees: isExpanded ? 0 : 180))
                    .fill(colorNearBlack)
                    .frame(width: 9, height: 6)
            }
            .padding(.horizontal)
            .background(Color(red: 1.0, green: 1.0, blue: 1.0, opacity: 0.01)) // Hackey way of making the whole HStack clickable (FIX)
            .onTapGesture { isExpanded = !isExpanded; }
            
            if isExpanded {
                ForEach(info) { i in InfoRow(info: i) }
                    .padding(.horizontal, 30.0)
                    .padding(.vertical, 5.0)
                //List(info) { i in InfoRow(info: i) }
            }
        }
    }
}


// TODO: Make ConfigInfoBlock "extend" InfoBlock?
struct ConfigInfoBlock: View {
    var title: String;
    var info:  [InfoPair];
    
    @State private var isExpanded = true;
    
    var body: some View {
        VStack {
            HStack {
                Text(title)
                    .fontWeight(.bold)
                    .foregroundColor(colorNearBlack)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Triangle()
                    .rotation(Angle(degrees: isExpanded ? 180 : 0))
                    .fill(colorNearBlack)
                    .frame(width: 9, height: 6)
            }
            .padding(.horizontal)
            .background(Color(red: 1.0, green: 1.0, blue: 1.0, opacity: 0.01)) // Hackey way of making the whole HStack clickable (FIX)
            .onTapGesture { isExpanded = !isExpanded; }
            
            if isExpanded {
                ForEach(info) { i in InfoRow(info: i) }
                    .padding(.horizontal, 30.0)
                    .padding(.vertical, 5.0)
                //List(info) { i in InfoRow(info: i) }
                HStack(alignment: .center) {
                    Button("Save", action: doNothing)
                    Button("Export", action: doNothing)
                }
                .padding(.horizontal)
            }
        }
    }
}

func doNothing() { }

struct SidePanel: View {
    var body: some View {
        HStack(spacing:0) {
            Divider()
            
            GeometryReader { geometry in
                ScrollView {
                    VStack(alignment: .leading) {
                        InfoBlock(title: "Video Information",     info: testInfo1)
                        Divider()
                        InfoBlock(title: "Frame Information",     info: testInfo2)
                        Spacer()
                        Divider()
                        ConfigInfoBlock(title: "Configuration Options", info: testInfo3)
                    }
                    .padding(.vertical, 10.0)
                    .frame(minHeight: geometry.size.height) // Inside the GeometryReader, this keeps the ConfigInfoBlock at the bottom (by default the Spacer() does nothing in a ScrollView)
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
