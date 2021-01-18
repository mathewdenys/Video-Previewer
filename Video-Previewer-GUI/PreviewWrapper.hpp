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

@interface OptionInformation : NSObject

- (instancetype) initWithID:(NSString*)optionID initWithDescription:(NSString*)description;
- (NSString*)    getID;
- (NSString*)    getDescription;

@end


@interface VideoPreviewWrapper : NSObject

- (instancetype) init:(NSString*)filePath;
- (void)         loadConfig;
- (void)         loadVideo;
- (void)         updatePreview;

- (NSArray<NSImage*>*) getFrames;

- (NSString*) getOptionValueString:(NSString*)optionID;
- (NSArray<OptionInformation*>*) getOptionInformation;

- (NSString*) getVideoName;
- (NSString*) getVideoFPS;
- (NSString*) getVideoDimensions;
- (NSString*) getVideoNumOfFrames;
- (NSString*) getVideoCodec;
- (NSString*) getVideoLength;

@end


#endif /* PreviewWrapper_h */
