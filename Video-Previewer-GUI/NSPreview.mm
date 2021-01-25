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

- (NSFramePreview*) initFromFrame:(const Frame&)frameIn
{
    frameNumber = frameIn.getFrameNumberHumanReadable();
    timeStamp   = [NSString fromStdString:frameIn.gettimeStampString()];
    
    // Adapted from https://docs.opencv.org/master/d3/def/tutorial_image_manipulation.html
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
    
    [self loadConfig   ];
    [self loadVideo    ];
    [self updatePreview];
    
    return self;
}

- (void)      loadConfig                { vp->loadConfig();    }
- (void)      loadVideo                 { vp->loadVideo();     }
- (void)      updatePreview             { vp->updatePreview(); }

- (NSString*) getVideoNameString        { return [NSString fromStdString:  vp->getVideoNameString()       ]; }
- (NSString*) getVideoFPSString         { return [NSString fromStdString:  vp->getVideoFPSString()        ]; }
- (NSString*) getVideoDimensionsString  { return [NSString fromStdWString: vp->getVideoDimensionsString() ]; }
- (NSString*) getVideoNumOfFramesString { return [NSString fromStdString:  vp->getVideoNumOfFramesString()]; }
- (NSString*) getVideoCodecString       { return [NSString fromStdString:  vp->getVideoCodecString()      ]; }
- (NSString*) getVideoLengthString      { return [NSString fromStdString:  vp->getVideoLengthString()     ]; }

- (NSNumber*) getVideoNumOfFrames       { return [NSNumber numberWithInt:vp->getVideoNumOfFrames()]; }

- (NSConfigValue*) getOptionValue:(NSString*)optionID
{
    ConfigOptionPtr option = vp->getOption(std::string([optionID UTF8String]));
    ConfigValuePtr  value  = option->getValue();
    
    if (value->getBool().has_value())
        return [[NSConfigValue alloc] initWithBool:value->getBool().value()];
    
    if (value->getInt().has_value())
        return [[NSConfigValue alloc] initWithInt: value->getInt().value()];
    
    return [[NSConfigValue alloc] initWithString:value->getString().value()];
}

- (NSString*) getOptionValueString:(NSString*)optionID
{
    ConfigOptionPtr option = vp->getOption(std::string([optionID UTF8String]));
    return option ? [NSString fromStdString:option->getValueAsString()] : @"-";    // If the option isn't specified, display "-"
}

- (NSArray<NSOptionInformation*>*) getOptionInformation
{
    ConfigOption::OptionInformationMap oim = vp->getRecognisedOptionInformation();
    
    NSMutableArray* options = [NSMutableArray new];
    for (auto opt: oim)
    {
        NSString* i = [NSString fromStdString:opt.first];
        NSString* d = [NSString fromStdString:opt.second.getDescription()];
        
        ValidOptionValue v = opt.second.getValidValues();
        NSString* v_string;
        switch (v)
        {
            case ValidOptionValue::eBoolean:
                v_string = [[NSString alloc] initWithUTF8String:"boolean"];
                 break;
                
            case ValidOptionValue::ePositiveInteger:
                v_string = [[NSString alloc] initWithUTF8String:"positiveInteger"];
                 break;
                
            case ValidOptionValue::ePositiveIntegerOrString:
                v_string = [[NSString alloc] initWithUTF8String:"positiveIntegerOrString"];
                 break;
                
            case ValidOptionValue::ePercentage:
                v_string = [[NSString alloc] initWithUTF8String:"percentage"];
                break;
                
            default:
                v_string = [[NSString alloc] initWithUTF8String:"string"];
                 break;
        }
        
        NSMutableArray* strings_ns = [NSMutableArray new];
        if (v == ValidOptionValue::eString || v == ValidOptionValue::ePositiveIntegerOrString)
        {
            vector<string> strings_std { opt.second.getValidStrings() };
            for (string s : strings_std)
                [strings_ns addObject: [NSString fromStdString:s]];
        }
        [options addObject: [[NSOptionInformation alloc] initWithID: i withDescription: d withValidValues:v_string withValidStrings:strings_ns] ];
    }
    
    return options;
}


- (void) setOptionValue:(NSString*)optionID withBool:(bool)val
{
    vp->setOption([optionID getStdString], val);
}

- (void) setOptionValue:(NSString*)optionID withInt:(int)val
{
    vp->setOption([optionID getStdString], val);
}

- (void) setOptionValue:(NSString*)optionID withString:(NSString *)val
{
    vp->setOption([optionID getStdString], [val getStdString]);
}


- (NSArray<NSFramePreview*>*) getFrames
{
    vector<Frame> frames = vp->getFrames();
    NSMutableArray* nsFrames = [NSMutableArray new];
    
    for (Frame frame: frames)
    {
        [nsFrames addObject: [[NSFramePreview alloc] initFromFrame: frame]];
    }
    
    return nsFrames;
}

@end

