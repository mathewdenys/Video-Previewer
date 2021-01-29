//
//  NSPreviewCpp.hpp
//  Video-Previewer
//
//  An extension to PreviewWrapper.hpp including the Objective-C interface that should be exposed to C++ but not Swift
//
//  Created by Mathew Denys on 21/01/21.
//

#import "Preview.hpp"
#import "NSConfig.hpp"

/*----------------------------------------------------------------------------------------------------
    MARK: - NSConfigValue
   ----------------------------------------------------------------------------------------------------*/

@interface NSConfigValue (cpp_compatibility)

- (instancetype) initWithString:(const string&) val;

@end


/*----------------------------------------------------------------------------------------------------
    MARK: - NSConfigValue
   ----------------------------------------------------------------------------------------------------*/

@interface NSConfigOption (cpp_compatibility)

- (NSConfigOption*) initWithID: (const string&) IDIn withBoolValue:   (const bool)    val;
- (NSConfigOption*) initWithID: (const string&) IDIn withIntValue:    (const int)     val;
- (NSConfigOption*) initWithID: (const string&) IDIn withStringValue: (const string&) val;

@end

/*----------------------------------------------------------------------------------------------------
    MARK: - NSOptionInformation
   ----------------------------------------------------------------------------------------------------*/

@interface NSOptionInformation (cpp_compatibility)

- (instancetype) fromOptionInformation:(const OptionInformation&)optInfo withID: (const string&)id;

@end
