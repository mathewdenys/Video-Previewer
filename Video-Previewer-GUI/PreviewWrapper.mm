//
//  PreviewWrapper.mm
//  Video-Previewer
//
//  Created by Mathew Denys on 13/01/21.
//

#include "PreviewWrapper.hpp"
#include "Preview.hpp"


@implementation OptionInformation {
@private
    NSString *optionID;
    NSString *description;
}

- (OptionInformation*) initWithID:(NSString*)optionID initWithDescription:(NSString*)description{
    self->optionID = optionID;
    self->description = description;
    return self;
}

- (NSString*) getID {
    return optionID;
}

- (NSString*) getDescription {
    return description;
}

@end



@implementation VideoPreviewWrapper {
@private
    std::shared_ptr<VideoPreview> vp;
}

- (VideoPreviewWrapper*) init:(NSString*)filePath {
    std::string filePathStdStr = std::string([filePath UTF8String]); // From https://stackoverflow.com/questions/8001677/how-do-i-convert-a-nsstring-into-a-stdstring
    vp = std::make_shared<VideoPreview>(filePathStdStr);
    return self;
}

- (void) loadConfig    { vp->loadConfig(); }
- (void) loadVideo     { vp->loadVideo();  }
- (void) updatePreview { vp->updatePreview(); }

- (NSArray<NSImage*>*) getFrames {
    vector<Frame> frames = vp->getFrames();
    
    NSMutableArray* images = [NSMutableArray new];
    
    Mat cvMatRGB;
    for (auto frame: frames)
    {
        Mat cvMatBGR { frame.getData()};
        cv::cvtColor(cvMatBGR, cvMatRGB, cv::COLOR_RGB2BGR);
        
        NSData* data = [NSData dataWithBytes:cvMatRGB.data length:cvMatRGB.elemSize()*cvMatRGB.total()];
        CGColorSpaceRef colorSpace;

          if (cvMatRGB.elemSize() == 1) {
              colorSpace = CGColorSpaceCreateDeviceGray();
          } else {
              colorSpace = CGColorSpaceCreateDeviceRGB();
          }

          CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);

          // Creating CGImage from cv::Mat
          CGImageRef imageRef = CGImageCreate(cvMatRGB.cols,                             //width
                                             cvMatRGB.rows,                              //height
                                             8,                                          //bits per component
                                             8 * cvMatRGB.elemSize(),                    //bits per pixel
                                             cvMatRGB.step[0],                           //bytesPerRow
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


- (NSString*) getOptionValueString:(NSString*)optionID {
    ConfigOptionPtr option = vp->getOption(std::string([optionID UTF8String]));
    if (!option)
        return @"-";
    return [NSString stringWithUTF8String:option->getValueAsString().c_str()];
}

- (NSArray<OptionInformation*>*) getOptionInformation {
    ConfigOption::OptionInformationMap oim = vp->getRecognisedOptionInformation();
    
    NSMutableArray* options = [NSMutableArray new];
    
    for (auto opt: oim)
    {
        NSString* i = [NSString stringWithUTF8String:(opt.first).c_str()];
        NSString* d = [NSString stringWithUTF8String:(opt.second.getDescription()).c_str()];
        [options addObject: [[OptionInformation alloc] initWithID: i initWithDescription: d] ];
    }
    
    return options;
}


- (NSString*) getVideoName        { return [NSString stringWithUTF8String:(vp->getVideoName()).c_str()]; }
- (NSString*) getVideoFPS         { return [NSString stringWithUTF8String:(vp->getVideoFPS()).c_str()]; }
- (NSString*) getVideoDimensions  { return [NSString stringWithUTF8String:(vp->getVideoDimensions()).c_str()]; }
- (NSString*) getVideoNumOfFrames { return [NSString stringWithUTF8String:(vp->getVideoNumOfFrames()).c_str()]; }
- (NSString*) getVideoCodec       { return [NSString stringWithUTF8String:(vp->getVideoCodec()).c_str()]; }
- (NSString*) getVideoLength      { return [NSString stringWithUTF8String:(vp->getVideoLength()).c_str()]; }

@end
