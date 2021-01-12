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

@end
