//
//  GlobalVars.swift
//  Video-Previewer-GUI
//
//  Created by Mathew Denys on 3/02/21.
//

import SwiftUI

class GlobalVars: ObservableObject {
    @Published var vp:            NSVideoPreview?    = nil
    @Published var frames:        [NSFramePreview?]? = nil
    @Published var selectedFrame: NSFramePreview?    = nil
    
    // configUpdateCounter is incremented any time configuration options are updated in the GUI
    // It's actual value is not meaningful; all that matters is that it is @Published, so any View with a GlobalVars object will be updated
    // Further, arbitrary code can be run in its didSet{}
    @Published var configUpdateCounter: Int = 0 { didSet{ frames = vp!.getFrames() } }
}
