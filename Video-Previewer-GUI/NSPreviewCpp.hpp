//
//  NSPreviewCpp.hpp
//  Video-Previewer
//
//  An extension to PreviewWrapper.hpp including the Objective-C interface that should be exposed to C++ but not Swift
//
//  Created by Mathew Denys on 21/01/21.
//

#import "Preview.hpp"
#import "NSPreview.hpp"

/*----------------------------------------------------------------------------------------------------
    MARK: - NSFramePreview
   ----------------------------------------------------------------------------------------------------*/

class Frame;

@interface NSFramePreview (cpp_compatibility)

- (instancetype) initFromFrame:(const Frame&)frameIn;

@end
