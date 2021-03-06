//
//  NSPreview.mm
//  Video-Previewer
//
//  Created by Mathew Denys on 13/01/21.
//

#import "NSStringCpp.hpp"
#import "NSConfigCpp.hpp"
#import "NSPreviewCpp.hpp"

/*----------------------------------------------------------------------------------------------------
    MARK: - NSFramePreview
   ----------------------------------------------------------------------------------------------------*/

@implementation NSFramePreview
{
    @private
    NSImage*  image;
    NSString* timeStamp;
    int       frameNumber;
}

- (NSImage*)  getImage           { return image; }
- (NSString*) getTimeStampString { return timeStamp; }
- (int)       getFrameNumber     { return frameNumber; }

@end

// MARK: - NSFramePreview (cpp_compatibility)

@implementation NSFramePreview (cpp_compatibility)

// Iitialize an NSFramePreview from a Frame
// Adapted from https://docs.opencv.org/master/d3/def/tutorial_image_manipulation.html
- (NSFramePreview*) initFromFrame:(const Frame&)frameIn
{
    frameNumber = frameIn.getFrameNumberHumanReadable();
    timeStamp   = [NSString fromStdString:frameIn.gettimeStampString()];
    
    Mat cvMat;
    cv::cvtColor(frameIn.getData(), cvMat, cv::COLOR_RGB2BGR); // Convert from BGR to RGB

    NSData* data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;

    if (cvMat.elemSize() == 1)
        colorSpace = CGColorSpaceCreateDeviceGray();
    else
        colorSpace = CGColorSpaceCreateDeviceRGB();

    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);

    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                              //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,//bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );

    NSBitmapImageRep* bitmapRep = [[NSBitmapImageRep alloc] initWithCGImage:imageRef];
    image = [[NSImage alloc] init];
    [image addRepresentation:bitmapRep];

    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return self;
}

@end


/*----------------------------------------------------------------------------------------------------
    MARK: - NSVideoPreview
   ----------------------------------------------------------------------------------------------------*/

@implementation NSVideoPreview
{
    @private
    std::shared_ptr<VideoPreview> vp;
}

- (NSVideoPreview*) init:(NSString*)filePath
{
    std::string filePathStdStr = [filePath getStdString];
    vp = std::make_shared<VideoPreview>(filePathStdStr);
    
    try {
        [self loadVideo    ]; // Throws a FileException if file could not be loaded
        [self loadConfig   ];
        [self updatePreview];
    } catch (const FileException& exception) {
        std::cerr<< exception.what();
    }
    
    return self;
}

- (void)      loadVideo                 { vp->loadVideo();     }
- (void)      loadConfig                { vp->loadConfig();    }
- (void)      updatePreview             { vp->updatePreview(); }

- (NSString*) getVideoPathString        { return [NSString fromStdString:  vp->getVideoPathString()       ]; }
- (NSString*) getVideoFPSString         { return [NSString fromStdString:  vp->getVideoFPSString()        ]; }
- (NSString*) getVideoDimensionsString  { return [NSString fromStdWString: vp->getVideoDimensionsString() ]; }
- (NSString*) getVideoNumOfFramesString { return [NSString fromStdString:  vp->getVideoNumOfFramesString()]; }
- (NSString*) getVideoCodecString       { return [NSString fromStdString:  vp->getVideoCodecString()      ]; }
- (NSString*) getVideoLengthString      { return [NSString fromStdString:  vp->getVideoLengthString()     ]; }

- (NSNumber*) getVideoNumOfFrames       { return [NSNumber numberWithInt:    vp->getVideoNumOfFrames()]; }
- (NSNumber*) getVideoAspectRatio       { return [NSNumber numberWithDouble: vp->getVideoAspectRatio()]; }

- (NSConfigValue*) getOptionValue:(NSString*)optionID
{
    ConfigOptionPtr option = vp->getOption(std::string([optionID UTF8String]));
    return [[NSConfigValue alloc] init: option->getValue()];
}

- (NSString*) getOptionValueString:(NSString*)optionID
{
    ConfigOptionPtr option = vp->getOption(std::string([optionID UTF8String]));
    return option ? [NSString fromStdString:option->getValueAsString()] : @"-";    // If the option isn't specified, display "-"
}

- (NSString*) getOptionConfigString:(NSString*)optionID
{
    ConfigOptionPtr option = vp->getOption(std::string([optionID UTF8String]));
    return [NSString fromStdString:option->getConfigString()];
}

- (NSOptionInformation*) getOptionInformation:(NSString*)optionID
{
    return [[NSOptionInformation alloc] fromOptionInformation:vp->getOptionInformation([optionID getStdString]) withID: [optionID getStdString]];
}

- (NSArray<NSString*>*) getConfigFilePaths
{
    vector<string> pathsIn { vp->getConfigFilePaths() };
    NSMutableArray* pathsOut = [NSMutableArray new];
    for (string path : pathsIn)
        [pathsOut addObject: [NSString fromStdString:path]];
    return pathsOut;
}

- (void) setOptionValue:(NSString*)optionID withBool:(bool)val         { vp->setOption([optionID getStdString], val); }
- (void) setOptionValue:(NSString*)optionID withInt:(int)val           { vp->setOption([optionID getStdString], val); }
- (void) setOptionValue:(NSString*)optionID withDouble:(double)val     { vp->setOption([optionID getStdString], val); }
- (void) setOptionValue:(NSString*)optionID withString:(NSString *)val { vp->setOption([optionID getStdString], [val getStdString]); }

- (void) saveAllOptions:(NSString*)filePath                            { vp->saveAllOptions([filePath getStdString]); }

- (void) setRows:(const int)rows                                       { vp->setRowsInPreview(rows); }
- (void) setCols:(const int)cols                                       { vp->setColsInPreview(cols); }

- (NSNumber*) getRows                                                  { return [NSNumber numberWithInt: vp->getRowsInPreview()]; }
- (NSNumber*) getCols                                                  { return [NSNumber numberWithInt: vp->getColsInPreview()]; }

- (NSNumber*) getNumOfFrames                                           { return [NSNumber numberWithUnsignedLong: vp->getNumOfFrames()]; }

- (NSArray<NSFramePreview*>*) getFrames
{
    vector<Frame> frames = vp->getFrames();
    NSMutableArray* nsFrames = [NSMutableArray new];
    
    for (Frame frame: frames)
        [nsFrames addObject: [[NSFramePreview alloc] initFromFrame: frame]];
    
    return nsFrames;
}

@end
