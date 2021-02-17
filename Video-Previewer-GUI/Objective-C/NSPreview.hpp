//
//  NSPreview.hpp
//  Video-Previewer
//
//  Created by Mathew Denys on 13/01/21.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "NSConfig.hpp"

/*----------------------------------------------------------------------------------------------------
    MARK: - NSFramePreview
   ----------------------------------------------------------------------------------------------------*/

@interface NSFramePreview : NSObject

- (NSImage*)  getImage;
- (NSString*) getTimeStampString;
- (int)       getFrameNumber;

@end


/*----------------------------------------------------------------------------------------------------
    MARK: - NSVideoPreview
   ----------------------------------------------------------------------------------------------------*/

@interface NSVideoPreview : NSObject

- (instancetype)              init:(NSString*)filePath;

// Wrapper functions for VideoPreview
- (void)                      loadConfig;
- (void)                      loadVideo;
- (void)                      updatePreview;

// Getter functions for displaying information about the video file
- (NSString*)                 getVideoNameString;
- (NSString*)                 getVideoCodecString;
- (NSString*)                 getVideoFPSString;
- (NSString*)                 getVideoLengthString;
- (NSString*)                 getVideoNumOfFramesString;
- (NSString*)                 getVideoDimensionsString;

- (NSNumber*)                 getVideoNumOfFrames;
- (NSNumber*)                 getVideoAspectRatio;

// Getter & setter functions for the configuration options
- (NSConfigValue*)            getOptionValue:(NSString*)optionID;        // Returns a NSConfigValue containing the value of the configuration option
- (NSString*)                 getOptionValueString:(NSString*)optionID;  // Returns a string corresponding to the value of the option corresponding to optionID
- (NSString*)                 getOptionConfigString:(NSString*)optionID; // Returns a string of the form "id = val" corresponding to optionID
- (NSOptionInformation*)      getOptionInformation:(NSString*)optionID;  // Returns an NSOptionInformation instance corresponding to optionID

- (NSArray<NSString*>*)       getConfigFilePaths;

- (void)                      setOptionValue:(NSString*)optionID withBool:(bool)val;
- (void)                      setOptionValue:(NSString*)optionID withInt:(int)val;
- (void)                      setOptionValue:(NSString*)optionID withDouble:(double)val;
- (void)                      setOptionValue:(NSString*)optionID withString:(NSString*)val;

- (void)                      saveAllOptions:(NSString*)filePath;

- (void)                      setRows:(const int)rows;
- (void)                      setCols:(const int)cols;
- (NSNumber*)                 getRows;
- (NSNumber*)                 getCols;


// Getter function for the preview video frames
- (NSArray<NSFramePreview*>*) getFrames;                                 // Returns an array consisting of a NSFramePreview for each frame in the preview

@end
