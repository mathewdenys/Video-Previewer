//
//  Fonts.swift
//  Video-Previewer-GUI
//
//  Created by Mathew Denys on 22/02/21.
//

import SwiftUI

struct FontStyleRegular: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Font.system(size: 12, weight: .regular,  design: .default))
    }
}

struct FontStyleHeading: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Font.system(size: 12, weight: .bold,     design: .default))
            .foregroundColor(colorBold)
    }
}


struct FontStyleNote: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Font.system(size: 10, weight: .regular,  design: .default))
    }
}

extension View {
    func regularFont() -> some View { self.modifier(FontStyleRegular()) }
    func headingFont() -> some View { self.modifier(FontStyleHeading()) }
    func noteFont()    -> some View { self.modifier(FontStyleNote()) }
}
