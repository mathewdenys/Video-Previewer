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

- (instancetype) init:(const ConfigValuePtr&)valuePtr;

@end


/*----------------------------------------------------------------------------------------------------
    MARK: - NSConfigOption
   ----------------------------------------------------------------------------------------------------*/

@interface NSConfigOption (cpp_compatibility)

- (instancetype) init:(const ConfigOption&)option;

@end

/*----------------------------------------------------------------------------------------------------
    MARK: - NSOptionInformation
   ----------------------------------------------------------------------------------------------------*/

@interface NSOptionInformation (cpp_compatibility)

- (instancetype) fromOptionInformation:(const OptionInformation&)optInfo withID: (const string&)id;

@end
