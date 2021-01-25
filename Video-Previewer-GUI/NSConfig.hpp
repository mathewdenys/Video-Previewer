//
//  NSPreview.hpp
//  Video-Previewer
//
//  Created by Mathew Denys on 13/01/21.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

/*----------------------------------------------------------------------------------------------------
    MARK: - NSConfigValue
   ----------------------------------------------------------------------------------------------------*/

@interface NSConfigValue : NSObject

- (instancetype) initWithBool:  (bool )    val;
- (instancetype) initWithInt:   (int )     val;

- (NSNumber*) getBool;
- (NSNumber*) getInt;
- (NSString*) getString;

@end


/*----------------------------------------------------------------------------------------------------
    MARK: - NSConfigOption
   ----------------------------------------------------------------------------------------------------*/

@interface NSConfigOption : NSObject

- (NSConfigValue*) getValue;
- (NSString*)      getID;

@end


/*----------------------------------------------------------------------------------------------------
    MARK: - NSOptionInformation
   ----------------------------------------------------------------------------------------------------*/

@interface NSOptionInformation : NSObject

- (instancetype)        initWithID:(NSString*)ID withDescription:(NSString*)description withValidValues:(NSString*)validValues;
- (instancetype)        initWithID:(NSString*)ID withDescription:(NSString*)description withValidValues:(NSString*)validValues withValidStrings:(NSMutableArray<NSString*>*)validStrings;

- (NSString*)           getID;
- (NSString*)           getDescription;
- (NSString*)           getValidValues;
- (NSArray<NSString*>*) getValidStrings;

@end
