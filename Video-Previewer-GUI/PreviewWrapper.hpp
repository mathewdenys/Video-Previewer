//
//  PreviewWrapper.hpp
//  Video-Previewer
//
//  Created by Mathew Denys on 13/01/21.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@interface FrameWrapper : NSObject
//
- (NSImage*)  getImage;
- (NSString*) getTimeStampString;
- (int)       getFrameNumber;
//
@end


@interface ConfigOptionWrapper : NSObject

//- (instancetype) initWithBool:  (bool )    val;
//- (instancetype) initWithInt:   (int )     val;
//- (instancetype) initWithString:(const string&) val;

- (NSNumber*)      getBool;
- (NSNumber*)       getInt;
- (NSString*) getString;

@end


@interface OptionInformation : NSObject

- (instancetype) initWithID:(NSString*)optionID withDescription:(NSString*)description;
- (NSString*)    getID;
- (NSString*)    getDescription;

@end


@interface VideoPreviewWrapper : NSObject

- (instancetype)                 init:(NSString*)filePath;

// Wrapper functions for VideoPreview
- (void)                         loadConfig;
- (void)                         loadVideo;
- (void)                         updatePreview;

// Getter functions for displaying information about the video file
- (NSString*)                    getVideoNameString;
- (NSString*)                    getVideoCodecString;
- (NSString*)                    getVideoFPSString;
- (NSString*)                    getVideoLengthString;
- (NSString*)                    getVideoNumOfFramesString;
- (NSString*)                    getVideoDimensionsString;

// Getter functions for the configuration options
- (ConfigOptionWrapper*)         getOptionValue:(NSString*)optionID;       // Returns a ConfigOptionWrapper containing the value of the configuration option
- (NSString*)                    getOptionValueString:(NSString*)optionID; // Returns a string corresponding to the value of the option corresponding to optionID
- (NSArray<OptionInformation*>*) getOptionInformation;                     // Returns an array consisting of an OptionInformation instance for each recognised option

// Getter function for the preview video frames
- (NSArray<FrameWrapper*>*)       getFrames;                               // Returns an array consisting of a FrameWrapper for each frame in the preview

@end
