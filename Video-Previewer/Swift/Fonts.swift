//
//  Fonts.swift
//  Video-Previewer-GUI
//
//  Created by Mathew Denys on 22/02/21.
//

import SwiftUI


extension View {
    func regularFont() -> some View {
        self.font(Font.system(size: 12, weight: .regular,  design: .default))
    }
    
    func headingFont() -> some View {
        self
        .font(Font.system(size: 12, weight: .bold,     design: .default))
        .foregroundColor(colorBold)
    }
    
    func noteFont()    -> some View {
        self.font(Font.system(size: 10, weight: .regular,  design: .default))
    }
}
