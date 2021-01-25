//
//  NSPreview.hpp
//  Video-Previewer
//
//  Created by Mathew Denys on 13/01/21.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

/*----------------------------------------------------------------------------------------------------
    MARK: - NSValidOptionValue
   ----------------------------------------------------------------------------------------------------*/

typedef NS_ENUM(NSInteger, NSValidOptionValue){
    eBoolean,
    ePositiveInteger,
    ePositiveIntegerOrString,
    ePercentage,
    eString,
};


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

- (instancetype)        initWithID:(NSString*)ID withDescription:(NSString*)description withValidValues:(NSValidOptionValue)validValues;
- (instancetype)        initWithID:(NSString*)ID withDescription:(NSString*)description withValidValues:(NSValidOptionValue)validValues withValidStrings:(NSMutableArray<NSString*>*)validStrings;

- (NSString*)           getID;
- (NSString*)           getDescription;
- (NSValidOptionValue)  getValidValues;
- (NSArray<NSString*>*) getValidStrings;

@end
