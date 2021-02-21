//
//  SectionViews.swift
//  Video-Previewer-GUI
//
//  Created by Mathew Denys on 21/02/21.
//

import SwiftUI


/*----------------------------------------------------------------------------------------------------
    MARK: - Section
   ----------------------------------------------------------------------------------------------------*/

struct Section<Content: View>: View {
    
    private let  title:   String
    private let  content: Content
    
    init(title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title       = title
        self.content     = content()
    }
    
    var body: some View {
        VStack {
            HStack {
                Text(title)
                    .headingFont()
                Spacer()
            }
            content
        }.padding(.horizontal, sectionPaddingHorizontal)
    }
}

/*----------------------------------------------------------------------------------------------------
    MARK: - ResettableSection
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


struct ResettableSection<Content: View>: View {
    
    private let  title:       String
    private let  resetAction: () -> Void
    private let  content:     Content
    
    init(title: String, resetAction: @escaping () -> Void, @ViewBuilder content: @escaping () -> Content) {
        self.title       = title
        self.resetAction = resetAction
        self.content     = content()
    }
    
    var body: some View {
        VStack {
            HStack {
                Text(title)
                    .headingFont()
                Spacer()
                ResetButton(action:resetAction)
            }
            content
        }.padding(.horizontal, sectionPaddingHorizontal)
    }
}


/*----------------------------------------------------------------------------------------------------
    MARK: - CollapsibleSection
   ----------------------------------------------------------------------------------------------------*/

struct CollapsibleSection<Content: View>: View {

    @State
    private var isExpanded = true
    
    private var expandedByDefault = true
    
    private let title:              String
    private let collapsibleContent: Content

    // Initialise with a title and content
    init(title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.collapsibleContent = content()
    }
    
    // Initialise with a title, content, and an expandedByDefault bool. expandedByDefault determines the
    // value of isExapnded when the view appears. Unfortunately, because collpsibleContent is shown
    // conditionally on the valyeof isExpanded, the value of isExapnded cannot be set directly in the
    // initialiser, but mustbe set in an .onAppear() instead.
    init(title: String, expandedByDefault: Bool, @ViewBuilder content: @escaping () -> Content) {
        self.title              = title
        self.expandedByDefault  = expandedByDefault
        self.collapsibleContent = content()
    }
    
    var body: some View {
        VStack {
            HStack {
                Text(title)
                    .headingFont()
                    .frame(maxWidth: .infinity, alignment: .leading)
                Triangle()
                    .rotation(Angle(degrees: isExpanded ? 180 : 90))
                    .fill(colorBold)
                    .frame(width: 9, height: 6)
            }
            .background(colorInvisible) // Hackey way of making the whole HStack clickable
            .onTapGesture { isExpanded = !isExpanded; }
            
            if isExpanded { collapsibleContent }
        }
        .padding(.horizontal, sectionPaddingHorizontal)
        .onAppear(perform: {isExpanded = expandedByDefault})
    }
}
