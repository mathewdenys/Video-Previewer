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
