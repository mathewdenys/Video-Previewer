//
//  Section.swift
//  Video-Previewer-GUI
//
//  Created by Mathew Denys on 21/02/21.
//

import SwiftUI


/*----------------------------------------------------------------------------------------------------
    MARK: - ResetButton
   ----------------------------------------------------------------------------------------------------*/

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


/*----------------------------------------------------------------------------------------------------
    MARK: - Triangle
        Used as the icon for collapsing / expanding sections
   ----------------------------------------------------------------------------------------------------*/

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))

        return path
    }
}


/*----------------------------------------------------------------------------------------------------
    MARK: - Section
   ----------------------------------------------------------------------------------------------------*/

struct Section<Content: View>: View {
    
    private let  title:            String
    private let  content:          Content
    
    private var  isResettable:     Bool       = false
    private var  resetAction:      () -> Void = { return }
    
    private var  isCollapsible:    Bool       = false
    @State private var isExpanded: Bool       = true
    
    // Plain section
    init(title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title       = title
        self.content     = content()
    }
    
    // Collapsible (optionally) section
    init(title: String, isCollapsible: Bool, @ViewBuilder content: @escaping () -> Content) {
        self.init(title: title, content: content)
        self.isCollapsible = isCollapsible
    }
    
    // Resettable (optionally) section
    init(title: String, resetAction: @escaping () -> Void, @ViewBuilder content: @escaping () -> Content) {
        self.init(title: title, content: content)
        self.isResettable = true
        self.resetAction  = resetAction
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
        }.padding(.horizontal, sectionHorizontalPadding)
    }
}


/*----------------------------------------------------------------------------------------------------
    MARK: - Subsection (modifier)
   ----------------------------------------------------------------------------------------------------*/

extension View {
    func subsection() -> some View {
        self.padding(5)
            .border(Color.black.opacity(0.07), width: 0.3)
            .background(Color.black.opacity(0.03))
            .cornerRadius(4)
            .padding(.leading, 15)
    }
}
