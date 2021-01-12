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
        
        HStack {
            Text(testString ?? "fail")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            SidePanel()
        }
        
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
