//
//  ContentView.swift
//  Video-Previewer-GUI
//
//  Created by Mathew Denys on 13/01/21.
//

import SwiftUI

let test = TestWrapper()
let testString = test?.getString()

var vp = VideoPreviewWrapper("/Users/mathew/Projects/Video-Previewer/Video-Previewer/media/sunrise.mov") // Unable to access any files outside fo the container (?)

struct ContentView: View {
    var body: some View {
        
        HStack {

            Text(testString ?? "fail")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Image(nsImage: vp?.getFirstFrame() ?? NSImage())
                .resizable()
                .frame(width: 200.0, height: 200.0)
                
            SidePanel()
        }
        
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
