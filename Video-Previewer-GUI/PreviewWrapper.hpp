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


@interface ConfigValueWrapper : NSObject

//- (instancetype) initWithBool:  (bool )    val;
//- (instancetype) initWithInt:   (int )     val;
//- (instancetype) initWithString:(const string&) val;

- (NSNumber*) getBool;
- (NSNumber*) getInt;
- (NSString*) getString;

@end


@interface ConfigOptionWrapper : NSObject

- (ConfigValueWrapper*) getValue;
- (NSString*)           getID;

@end


@interface OptionInformation : NSObject

//- (instancetype)        initWithID:(NSString*)ID withDescription:(NSString*)description withValidValues:(NSString*)validValues;
- (instancetype)        initWithID:(NSString*)ID withDescription:(NSString*)description withValidValues:(NSString*)validValues withValidStrings:(NSMutableArray<NSString*>*)validStrings;
- (NSString*)           getID;
- (NSString*)           getDescription;
- (NSString*)           getValidValues;
- (NSArray<NSString*>*) getValidStrings;

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

// Getter & setter functions for the configuration options
- (ConfigValueWrapper*)         getOptionValue:(NSString*)optionID;       // Returns a ConfigValueWrapper containing the value of the configuration option
- (NSString*)                    getOptionValueString:(NSString*)optionID; // Returns a string corresponding to the value of the option corresponding to optionID
- (NSArray<OptionInformation*>*) getOptionInformation;                     // Returns an array consisting of an OptionInformation instance for each recognised option

- (void)                         setOptionValue:(NSString*)optionID withBool:(bool)val;
- (void)                         setOptionValue:(NSString*)optionID withInt:(int)val;
- (void)                         setOptionValue:(NSString*)optionID withString:(NSString*)val;

// Getter function for the preview video frames
- (NSArray<FrameWrapper*>*)      getFrames;                               // Returns an array consisting of a FrameWrapper for each frame in the preview

@end
