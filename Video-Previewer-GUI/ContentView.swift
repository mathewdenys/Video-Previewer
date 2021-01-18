//
//  ContentView.swift
//  Video-Previewer-GUI
//
//  Created by Mathew Denys on 13/01/21.
//

import SwiftUI


/*----------------------------------------------------------------------------------------------------
    MARK: - ContentView
   ----------------------------------------------------------------------------------------------------*/

struct ContentView: View {
    let vp = VideoPreviewWrapper("/Users/mathew/Library/Containers/mdenys.Video-Previewer-GUI/Data/sunrise.mov")
    
    var body: some View {
        HStack(spacing:0) {
            PreviewPaneView(vp: self.vp!)
            SidePanelView(vp: self.vp!)
                .frame(maxWidth: 300)
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
