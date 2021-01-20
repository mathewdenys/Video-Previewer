//
//  PreviewWrapperCpp.hpp
//  Video-Previewer
//
//  An extension to PreviewWrapper.hpp including the Objective-C interface that should be exposed to C++ but not Swift
//
//  Created by Mathew Denys on 21/01/21.
//

#import "PreviewWrapper.hpp"
#import "Preview.hpp"

@interface NSString (cppstring_additions)

+(NSString*) fromString:(const string&)s;
+(NSString*) fromWString:(const wstring&)ws;
-(string)    getString;
-(wstring)   getWString;

@end



class Frame;

@interface FrameWrapper (cpp_compatibility)

- (instancetype) initFromFrame:(const Frame&)frameIn;

@end
