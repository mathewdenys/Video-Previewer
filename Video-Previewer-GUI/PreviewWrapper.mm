//
//  PreviewWrapper.mm
//  Video-Previewer
//
//  Created by Mathew Denys on 13/01/21.
//

#include "PreviewWrapper.hpp"
#include "Preview.hpp"

@implementation TestWrapper {
@private
    std::shared_ptr<Test> test;
}

- (TestWrapper*) init {
    test = std::make_shared<Test>();
    return self;
}

- (NSString*) getString {
    // See for this (and potentially a better) solution: https://stackoverflow.com/a/7424962
    return [NSString stringWithUTF8String:test->getString().c_str()];
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

- (NSImage*) getFirstFrame {
    Mat cvMat { vp->getFirstFrame() };
    NSData* data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;

      if (cvMat.elemSize() == 1) {
          colorSpace = CGColorSpaceCreateDeviceGray();
      } else {
          colorSpace = CGColorSpaceCreateDeviceRGB();
      }

      CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);

      // Creating CGImage from cv::Mat
      CGImageRef imageRef = CGImageCreate(cvMat.cols,                                //width
                                         cvMat.rows,                                 //height
                                         8,                                          //bits per component
                                         8 * cvMat.elemSize(),                       //bits per pixel
                                         cvMat.step[0],                              //bytesPerRow
                                         colorSpace,                                 //colorspace
                                         kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
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

        return image;
}

@end
