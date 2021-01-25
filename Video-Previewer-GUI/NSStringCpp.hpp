//
//  NSStringCpp.hpp
//  Video-Previewer
//
//  The Objective-C interface for NSString that should be exposed to C++ but not Swift
//
//  Created by Mathew Denys on 26/01/21.
//

#import <Foundation/Foundation.h>
#import <string>

/*----------------------------------------------------------------------------------------------------
    MARK: - NSString
   ----------------------------------------------------------------------------------------------------*/

using std::string;
using std::wstring;

@interface NSString (cppstring_additions)

+(NSString*) fromStdString: (const string&)s;
+(NSString*) fromStdWString:(const wstring&)ws;
-(string)    getStdString;
-(wstring)   getStdWString;

@end
