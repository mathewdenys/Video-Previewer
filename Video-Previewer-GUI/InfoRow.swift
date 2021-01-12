//
//  InfoRow.swift
//  Video-Previewer-GUI
//
//  Created by Mathew Denys on 13/01/21.
//

import SwiftUI

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
}

//struct InfoRow_Previews: PreviewProvider {
//    static var previews: some View {
//        InfoRow()
//    }
//}

