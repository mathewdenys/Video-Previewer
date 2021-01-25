//
//  PreviewWrapper.mm
//  Video-Previewer
//
//  Created by Mathew Denys on 13/01/21.
//

#import "PreviewWrapperCpp.hpp"

/*----------------------------------------------------------------------------------------------------
    MARK: - NSString
        - From: https://stackoverflow.com/a/7424962
   ----------------------------------------------------------------------------------------------------*/

@implementation NSString (cppstring_additions)

#if TARGET_RT_BIG_ENDIAN
const NSStringEncoding kEncoding_wchar_t = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingUTF32BE);
#else
const NSStringEncoding kEncoding_wchar_t = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingUTF32LE);
#endif

+(NSString*) fromStdString:(const string&)s
{
    NSString* result = [[NSString alloc] initWithUTF8String:s.c_str()];
    return result;
}

+(NSString*) fromStdWString:(const wstring&)ws
{
    char* data = (char*)ws.data();
    unsigned long size = ws.size() * sizeof(wchar_t);

    NSString* result = [[NSString alloc] initWithBytes:data length:size encoding:kEncoding_wchar_t];
    return result;
}

-(string) getStdString
{
    return [self UTF8String];
}

-(wstring) getStdWString
{
    NSData* asData = [self dataUsingEncoding:kEncoding_wchar_t];
    return std::wstring((wchar_t*)[asData bytes], [asData length] / sizeof(wchar_t));
}

@end


/*----------------------------------------------------------------------------------------------------
    MARK: - ConfigValueWrapper
   ----------------------------------------------------------------------------------------------------*/

@implementation ConfigValueWrapper {
@private
    NSNumber* boolVal;
    NSNumber* intVal;
    NSString* stringVal;
}

- (ConfigValueWrapper*) initWithBool:  (const bool)    val { boolVal   = [NSNumber numberWithBool: val]; return self; }
- (ConfigValueWrapper*) initWithInt:   (const int)     val { intVal    = [NSNumber numberWithInt:  val]; return self;  }
- (ConfigValueWrapper*) initWithString:(const string&) val { stringVal = [NSString fromStdString:  val]; return self;  }

- (NSNumber*) getBool   { return boolVal; }
- (NSNumber*) getInt    { return intVal; }
- (NSString*) getString { return stringVal; }

@end


/*----------------------------------------------------------------------------------------------------
    MARK: - ConfigOptionWrapper
   ----------------------------------------------------------------------------------------------------*/

@implementation ConfigOptionWrapper {
@private
    NSString* ID;
    ConfigValueWrapper* value;
}

- (ConfigOptionWrapper*) initWithID: (const string&) IDIn withBoolValue:   (const bool)    val { ID = [NSString fromStdString:IDIn]; value = [[ConfigValueWrapper alloc] initWithBool: val];   return self;}
- (ConfigOptionWrapper*) initWithID: (const string&) IDIn withIntValue:    (const int)     val { ID = [NSString fromStdString:IDIn]; value = [[ConfigValueWrapper alloc] initWithInt: val];    return self;}
- (ConfigOptionWrapper*) initWithID: (const string&) IDIn withStringValue: (const string&) val { ID = [NSString fromStdString:IDIn]; value = [[ConfigValueWrapper alloc] initWithString: val]; return self;}

- (ConfigValueWrapper*) getValue { return value; }
- (NSString*)           getID    { return ID;    }

@end


/*----------------------------------------------------------------------------------------------------
    MARK: - OptionInformation
   ----------------------------------------------------------------------------------------------------*/

@implementation OptionInformation {
@private
    NSString*           ID;
    NSString*           description;
    NSString*           validValues;
    NSArray<NSString*>* validStrings;
}

- (OptionInformation*) initWithID:(NSString*)ID withDescription:(NSString*)description withValidValues:(NSString*)validValues
{
    self->ID          = ID;
    self->description = description;
    self->validValues = validValues;
    
    return self;
}

- (OptionInformation*) initWithID:(NSString*)ID withDescription:(NSString*)description withValidValues:(NSString*)validValues withValidStrings:(NSArray<NSString*>*)validStrings
{
    self = [[OptionInformation alloc] initWithID: ID withDescription: description withValidValues: validValues];
    self->validStrings = validStrings;
    
    return self;
}

- (NSString*)           getID           { return ID; }
- (NSString*)           getDescription  { return description; }
- (NSString*)           getValidValues  { return validValues; }
- (NSArray<NSString*>*) getValidStrings { return validStrings; }

@end

/*----------------------------------------------------------------------------------------------------
    MARK: - FrameWrapper
   ----------------------------------------------------------------------------------------------------*/

@implementation FrameWrapper
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


@implementation FrameWrapper (cpp_compatibility)

- (FrameWrapper*) initFromFrame:(const Frame&)frameIn
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
    MARK: - VideoPreviewWrapper
   ----------------------------------------------------------------------------------------------------*/

@implementation VideoPreviewWrapper
{
    @private
    std::shared_ptr<VideoPreview> vp;
}

- (VideoPreviewWrapper*) init:(NSString*)filePath
{
    std::string filePathStdStr = [filePath getStdString];
    vp = std::make_shared<VideoPreview>(filePathStdStr);
    
    [self loadConfig   ];
    [self loadVideo    ];
    [self updatePreview];
    
    return self;
}

- (void)      loadConfig          { vp->loadConfig();    }
- (void)      loadVideo           { vp->loadVideo();     }
- (void)      updatePreview       { vp->updatePreview(); }

- (NSString*) getVideoNameString        { return [NSString fromStdString:  vp->getVideoNameString()       ]; }
- (NSString*) getVideoFPSString         { return [NSString fromStdString:  vp->getVideoFPSString()        ]; }
- (NSString*) getVideoDimensionsString  { return [NSString fromStdWString: vp->getVideoDimensionsString() ]; }
- (NSString*) getVideoNumOfFramesString { return [NSString fromStdString:  vp->getVideoNumOfFramesString()]; }
- (NSString*) getVideoCodecString       { return [NSString fromStdString:  vp->getVideoCodecString()      ]; }
- (NSString*) getVideoLengthString      { return [NSString fromStdString:  vp->getVideoLengthString()     ]; }

- (NSNumber*) getVideoNumOfFrames { return [NSNumber numberWithInt:vp->getVideoNumOfFrames()]; }

- (ConfigValueWrapper*) getOptionValue:(NSString*)optionID
{
    ConfigOptionPtr option = vp->getOption(std::string([optionID UTF8String]));
    ConfigValuePtr  value  = option->getValue();
    
    if (value->getBool().has_value())   { return [[ConfigValueWrapper alloc] initWithBool:value->getBool().value()]; }
    if (value->getInt().has_value())    { return [[ConfigValueWrapper alloc] initWithInt: value->getInt().value()];  }
    return [[ConfigValueWrapper alloc] initWithString:value->getString().value()];
}

- (NSString*) getOptionValueString:(NSString*)optionID
{
    ConfigOptionPtr option = vp->getOption(std::string([optionID UTF8String]));
    return option ? [NSString fromStdString:option->getValueAsString()] : @"-";    // If the option isn't specified, display "-"
}

- (NSArray<OptionInformation*>*) getOptionInformation
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
                
            case ValidOptionValue::ePercentage:
                v_string = [[NSString alloc] initWithUTF8String:"percentage"];
                break;
                
            default:
                v_string = [[NSString alloc] initWithUTF8String:"string"];
                 break;
        }
        
        NSMutableArray* strings_ns = [NSMutableArray new];
        if (v == ValidOptionValue::eString)
        {
            vector<string> strings_std { opt.second.getValidStrings() };
            for (string s : strings_std)
                [strings_ns addObject: [NSString fromStdString:s]];
        }
        [options addObject: [[OptionInformation alloc] initWithID: i withDescription: d withValidValues:v_string withValidStrings:strings_ns] ];
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


- (NSArray<FrameWrapper*>*) getFrames
{
    vector<Frame> frames = vp->getFrames();
    NSMutableArray* frameWrappers = [NSMutableArray new];
    
    for (Frame frame: frames)
    {
        [frameWrappers addObject: [[FrameWrapper alloc] initFromFrame: frame]];
    }
    
    return frameWrappers;
}

@end


