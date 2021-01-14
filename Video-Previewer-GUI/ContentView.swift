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
    var body: some View {
        
        HStack(spacing:0) {
            PreviewPane()
            SidePanel()
                .frame(minWidth: 200, maxWidth: 250)
        }
    }
    
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
