//
//  PreviewPane.swift
//  Video-Previewer-GUI
//
//  Created by Mathew Denys on 14/01/21.
//

import SwiftUI

struct PreviewPane: View {
    var body: some View {
        ZStack {
            Color(red: 0.98, green: 0.98, blue: 0.98, opacity: 1.0).edgesIgnoringSafeArea(.all)
            Text(testString ?? "fail")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct PreviewPane_Previews: PreviewProvider {
    static var previews: some View {
        PreviewPane()
    }
}
