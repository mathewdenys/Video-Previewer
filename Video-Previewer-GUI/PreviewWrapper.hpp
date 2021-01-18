//
//  PreviewWrapper.hpp
//  Video-Previewer
//
//  Created by Mathew Denys on 13/01/21.
//

#ifndef PreviewWrapper_h
#define PreviewWrapper_h

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@interface VideoPreviewWrapper : NSObject

- (instancetype) init:(NSString*)filePath;
- (void)         loadConfig;
- (void)         loadVideo;
- (void)         updatePreview;

- (NSArray<NSImage*>*) getFrames;

- (NSString*) getOptionValueString:(NSString*)optionID;
- (NSString*) getOptionDescription:(NSString*)optionID;

@end


#endif /* PreviewWrapper_h */
