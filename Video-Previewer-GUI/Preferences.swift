//
//  Preferences.swift
//  Video-Previewer-GUI
//
//  Created by Mathew Denys on 2/02/21.
//

import SwiftUI

struct PreferencesGeneralView: View {
    var body: some View {
        Text("one")
    }
}

struct PreferencesConfigView: View {
    var body: some View {
        Text("two")
    }
}

struct PreferencesView: View {
    var body: some View {
        
        HStack {
            TabView {
                PreferencesGeneralView()
                    .tabItem {
//                        Image(systemName: "1.square.fill")
                        Text("First")
                    }
                PreferencesConfigView()
                    .tabItem {
//                        Image(systemName: "2.square.fill")
                        Text("Second")
                    }
                Text("The Last Tab")
                    .tabItem {
//                        Image(systemName: "3.square.fill")
                        Text("Third")
                    }
            }
        }.frame(width: 200, height: 300)
        
    }
}

struct Preferences_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
    }
}
