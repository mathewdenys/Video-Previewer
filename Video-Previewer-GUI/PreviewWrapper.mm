//
//  PreviewWrapper.mm
//  Video-Previewer
//
//  Created by Mathew Denys on 13/01/21.
//

#include "PreviewWrapper.hpp"
#include "Preview.hpp"

/*----------------------------------------------------------------------------------------------------
    MARK: - NSString - std::string conversion
        - From: https://stackoverflow.com/a/7424962
   ----------------------------------------------------------------------------------------------------*/

@interface NSString (cppstring_additions)

+(NSString*) fromString:(const string&)s;
+(NSString*) fromWString:(const wstring&)ws;
-(string)    getString;
-(wstring)   getWString;

@end


@implementation NSString (cppstring_additions)

#if TARGET_RT_BIG_ENDIAN
const NSStringEncoding kEncoding_wchar_t = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingUTF32BE);
#else
const NSStringEncoding kEncoding_wchar_t = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingUTF32LE);
#endif

+(NSString*) fromString:(const string&)s
{
    NSString* result = [[NSString alloc] initWithUTF8String:s.c_str()];
    return result;
}

+(NSString*) fromWString:(const wstring&)ws
{
    char* data = (char*)ws.data();
    unsigned long size = ws.size() * sizeof(wchar_t);

    NSString* result = [[NSString alloc] initWithBytes:data length:size encoding:kEncoding_wchar_t];
    return result;
}

-(string) getString
{
    return [self UTF8String];
}

-(wstring) getWString
{
    NSData* asData = [self dataUsingEncoding:kEncoding_wchar_t];
    return std::wstring((wchar_t*)[asData bytes], [asData length] / sizeof(wchar_t));
}

@end


/*----------------------------------------------------------------------------------------------------
    MARK: - OptionInformation
   ----------------------------------------------------------------------------------------------------*/

@implementation OptionInformation {
@private
    NSString *ID;
    NSString *description;
}

- (OptionInformation*) initWithID:(NSString*)ID withDescription:(NSString*)description
{
    self->ID          = ID;
    self->description = description;
    return self;
}

- (NSString*) getID { return ID; }

- (NSString*) getDescription { return description; }

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
    std::string filePathStdStr = [filePath getString];
    vp = std::make_shared<VideoPreview>(filePathStdStr);
    return self;
}

- (void)      loadConfig          { vp->loadConfig();    }
- (void)      loadVideo           { vp->loadVideo();     }
- (void)      updatePreview       { vp->updatePreview(); }

- (NSString*) getVideoNameString        { return [NSString fromString:vp->getVideoNameString()       ]; }
- (NSString*) getVideoFPSString         { return [NSString fromString:vp->getVideoFPSString()        ]; }
- (NSString*) getVideoWidthString       { return [NSString fromString:vp->getVideoWidthString()      ]; }
- (NSString*) getVideoHeightString      { return [NSString fromString:vp->getVideoHeightString()     ]; }
- (NSString*) getVideoNumOfFramesString { return [NSString fromString:vp->getVideoNumOfFramesString()]; }
- (NSString*) getVideoCodecString       { return [NSString fromString:vp->getVideoCodecString()      ]; }
- (NSString*) getVideoLengthString      { return [NSString fromString:vp->getVideoLengthString()     ]; }

- (NSString*) getOptionValueString:(NSString*)optionID
{
    ConfigOptionPtr option = vp->getOption(std::string([optionID UTF8String]));
    return option ? [NSString fromString:option->getValueAsString()] : @"-";    // If the option isn't specified, display "-"
}

- (NSArray<OptionInformation*>*) getOptionInformation
{
    ConfigOption::OptionInformationMap oim = vp->getRecognisedOptionInformation();
    
    NSMutableArray* options = [NSMutableArray new];
    for (auto opt: oim)
    {
        NSString* i = [NSString stringWithUTF8String:(opt.first).c_str()];
        NSString* d = [NSString stringWithUTF8String:(opt.second.getDescription()).c_str()];
        [options addObject: [[OptionInformation alloc] initWithID: i withDescription: d] ];
    }
    
    return options;
}

// Adapted from https://docs.opencv.org/master/d3/def/tutorial_image_manipulation.html
- (NSArray<NSImage*>*) getFrames
{
    vector<Frame>   frames = vp->getFrames();
    NSMutableArray* images = [NSMutableArray new];
    
    Mat cvMat;
    for (auto frame: frames)
    {
        cv::cvtColor(frame.getData(), cvMat, cv::COLOR_RGB2BGR); // Convert from BGR to RGB
        
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

        NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithCGImage:imageRef];
        NSImage *image = [[NSImage alloc] init];
        [image addRepresentation:bitmapRep];

        CGImageRelease(imageRef);
        CGDataProviderRelease(provider);
        CGColorSpaceRelease(colorSpace);
        
        [images addObject: image];
    }
    
    return images;
}

@end


