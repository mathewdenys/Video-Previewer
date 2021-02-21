//
//  PreviewData.swift
//  Video-Previewer-GUI
//
//  Created by Mathew Denys on 3/02/21.
//

import SwiftUI

class PreviewData: ObservableObject {
    
    @Published var backend:       NSVideoPreview?    = nil
    @Published var frames:        [NSFramePreview?]? = nil { didSet{ selectedFrame = nil } } // When changed, unselect the currently selected frame
    @Published var selectedFrame: NSFramePreview?    = nil
    
    // updateCounter is incremented any time configuration options are updated in the GUI. It's value
    // is not meaningful, but any time updating its value means that any View with a PreviewData member
    // will be updated. Further, arbitrary code can be run in its didSet{}.
    @Published var updateCounter: Int = 0
    
    func refresh() {
        if (frames!.count != backend!.getNumOfFrames()!.intValue) {
            frames = backend!.getFrames()
        }
        updateCounter += 1
    }
}
