//
//  NSString.mm
//  Video-Previewer
//
//  Created by Mathew Denys on 26/01/21.
//

#import "NSStringCpp.hpp"

/*----------------------------------------------------------------------------------------------------
    MARK: - NSString (cpp_additions)
        This category extends NSString to allow instances to be initialized from std::string and std::wstring
        From: https://stackoverflow.com/a/7424962
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
