//
//  ContentView.swift
//  Video-Previewer-GUI
//
//  Created by Mathew Denys on 13/01/21.
//

import SwiftUI


struct ContentView: View {
    
    var vp = VideoPreviewWrapper("/Users/mathew/Library/Containers/mdenys.Video-Previewer-GUI/Data/sunrise.mov")
    
    var body: some View {
        HStack(spacing:0) {
            PreviewPane(vp: self.vp!)
            SidePanel(vp: self.vp!)
                .frame(minWidth: 250, maxWidth: 300)
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


/*----------------------------------------------------------------------------------------------------
    MARK: - Hide Indicators
        - The following code is a work around for a known bug whereby hiding a ScrollView's indicator breaks the ability to scroll
        - From: https://stackoverflow.com/a/60464182
   ----------------------------------------------------------------------------------------------------*/

extension View {
    func hideIndicators() -> some View {
        return PanelScrollView{ self }
    }
}

struct PanelScrollView<Content> : View where Content : View {
    let content: () -> Content

    var body: some View {
        PanelScrollViewControllerRepresentable(content: self.content())
    }
}

struct PanelScrollViewControllerRepresentable<Content>: NSViewControllerRepresentable where Content: View{
    func makeNSViewController(context: Context) -> PanelScrollViewHostingController<Content> {
        return PanelScrollViewHostingController(rootView: self.content)
    }

    func updateNSViewController(_ nsViewController: PanelScrollViewHostingController<Content>, context: Context) {
    }

    typealias NSViewControllerType = PanelScrollViewHostingController<Content>

    let content: Content
}

class PanelScrollViewHostingController<Content>: NSHostingController<Content> where Content : View {

    var scrollView: NSScrollView?

    override func viewDidAppear() {
        self.scrollView = findNSScrollView(view: self.view)
        self.scrollView?.scrollerStyle = .overlay
        self.scrollView?.hasVerticalScroller = false
        self.scrollView?.hasHorizontalScroller = false
        super.viewDidAppear()
    }

    func findNSScrollView(view: NSView?) -> NSScrollView? {
        if view?.isKind(of: NSScrollView.self) ?? false {
            return (view as? NSScrollView)
        }

        for v in view?.subviews ?? [] {
            if let vc = findNSScrollView(view: v) {
                return vc
            }
        }
        
        return nil
    }
}
