//
//  Section.swift
//  Video-Previewer-GUI
//
//  Created by Mathew Denys on 21/02/21.
//

import SwiftUI

struct ResetButton: View {

    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(nsImage: NSImage(imageLiteralResourceName: NSImage.refreshTemplateName))
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .toolTip("Reset to defaults")
        }.buttonStyle(BorderlessButtonStyle())
    }
}


struct Section<Content: View>: View {
    
    private let  title:            String
    private let  content:          Content
    
    private var  isResettable:     Bool       = false
    private var  resetAction:      () -> Void = { return }
    
    private var  isCollapsible:    Bool       = false
    @State private var isExpanded: Bool       = true
    
    init(title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title       = title
        self.content     = content()
    }
    
    init(title: String, isCollapsible: Bool, @ViewBuilder content: @escaping () -> Content) {
        self.title         = title
        self.content       = content()
        self.isCollapsible = isCollapsible
    }
    
    init(title: String, resetAction: @escaping () -> Void, @ViewBuilder content: @escaping () -> Content) {
        self.title        = title
        self.content      = content()
        self.isResettable = true
        self.resetAction  = resetAction
    }
    
    init(title: String, isCollapsible: Bool, resetAction: @escaping () -> Void, @ViewBuilder content: @escaping () -> Content) {
        self.title        = title
        self.content      = content()
        self.isResettable = true
        self.resetAction  = resetAction
        self.isCollapsible = isCollapsible
    }
    
    var body: some View {
        VStack {
            HStack {
                Text(title)
                    .headingFont()
                Spacer()
                if (isResettable) {
                    ResetButton(action:resetAction)
                }
                if (isCollapsible) {
                    Triangle()
                        .rotation(Angle(degrees: isExpanded ? 180 : 90))
                        .fill(colorBold)
                        .frame(width: 9, height: 6)
                }
            }
            .background(colorInvisible) // Hackey way of making the whole HStack clickable (for collapsing and expanding)
            .onTapGesture { isExpanded = !isExpanded; }
            
            if (isCollapsible) {
                if (isExpanded) {
                    content
                }
            } else {
                content
            }
        }.padding(.horizontal, sectionPaddingHorizontal)
    }
}
