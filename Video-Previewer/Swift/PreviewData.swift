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
    
    // updateCounter is incremented any time configuration options are updated in the GUI. It's value is not
    // meaningful, but updating its value causes any View with a PreviewData member will be updated.
    @Published var updateCounter: Int = 0
    
    func refresh() {
        // Update the frames array if it contains a different number of frames than is required
        if (frames!.count != backend!.getNumOfFrames()!.intValue) {
            frames = backend!.getFrames()
        }
        
        // Refresh all relevant views
        updateCounter += 1
    }
}
