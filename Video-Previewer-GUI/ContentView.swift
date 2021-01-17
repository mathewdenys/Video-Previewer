//
//  ContentView.swift
//  Video-Previewer-GUI
//
//  Created by Mathew Denys on 13/01/21.
//

import SwiftUI

let test = TestWrapper()
let testString = test?.getString()


struct ContentView: View {
    
    var vp = VideoPreviewWrapper("/Users/mathew/Library/Containers/mdenys.Video-Previewer-GUI/Data/sunrise.mov")
    
    var body: some View {
        HStack(spacing:0) {
            PreviewPane(vp: self.vp!)
            SidePanel(vp: self.vp!)
                .frame(minWidth: 200, maxWidth: 250)
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
