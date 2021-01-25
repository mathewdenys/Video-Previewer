//
//  NSPreview.mm
//  Video-Previewer
//
//  Created by Mathew Denys on 13/01/21.
//

#import "NSStringCpp.hpp"
#import "NSConfigCpp.hpp"

/*----------------------------------------------------------------------------------------------------
    MARK: - NSConfigValue
   ----------------------------------------------------------------------------------------------------*/

@implementation NSConfigValue {
@private
    NSNumber* boolVal;
    NSNumber* intVal;
    NSString* stringVal;
}

- (NSConfigValue*) initWithBool:(const bool)val
{
    boolVal = [NSNumber numberWithBool: val];
    return self;
}

- (NSConfigValue*) initWithInt:(const int)val
{
    intVal = [NSNumber numberWithInt:  val];
    return self;
}

- (NSNumber*) getBool   { return boolVal; }
- (NSNumber*) getInt    { return intVal; }
- (NSString*) getString { return stringVal; }

@end

// MARK: - NSConfigValue (cpp_compatibility)

@implementation NSConfigValue (cpp_compatibility)

- (NSConfigValue*) initWithString:(const string&)val
{
    stringVal = [NSString fromStdString:  val];
    return self;
}

@end


/*----------------------------------------------------------------------------------------------------
    MARK: - NSConfigOption
   ----------------------------------------------------------------------------------------------------*/

@implementation NSConfigOption {
@private
    NSString* ID;
    NSConfigValue* value;
}

- (NSConfigValue*) getValue { return value; }
- (NSString*)      getID    { return ID;    }

@end

// MARK: - NSConfigOption (cpp_compatibility)

@implementation NSConfigOption (cpp_compatibility)

- (NSConfigOption*) initWithID: (const string&) IDIn withBoolValue:(const bool)val
{
    ID = [NSString fromStdString:IDIn];
    value = [[NSConfigValue alloc] initWithBool: val];
    return self;
}

- (NSConfigOption*) initWithID: (const string&) IDIn withIntValue:(const int)val
{
    ID = [NSString fromStdString:IDIn];
    value = [[NSConfigValue alloc] initWithInt: val];
    return self;
}

- (NSConfigOption*) initWithID: (const string&) IDIn withStringValue:(const string&)val
{
    ID = [NSString fromStdString:IDIn];
    value = [[NSConfigValue alloc] initWithString: val];
    return self;
}

@end


/*----------------------------------------------------------------------------------------------------
    MARK: - NSOptionInformation
   ----------------------------------------------------------------------------------------------------*/

@implementation NSOptionInformation {
@private
    NSString*           ID;
    NSString*           description;
    NSString*           validValues;
    NSArray<NSString*>* validStrings;
}

- (NSOptionInformation*) initWithID:(NSString*)ID withDescription:(NSString*)description withValidValues:(NSString*)validValues
{
    self->ID          = ID;
    self->description = description;
    self->validValues = validValues;
    return self;
}

- (NSOptionInformation*) initWithID:(NSString*)ID withDescription:(NSString*)description withValidValues:(NSString*)validValues withValidStrings:(NSArray<NSString*>*)validStrings
{
    self = [[NSOptionInformation alloc] initWithID: ID withDescription: description withValidValues: validValues];
    self->validStrings = validStrings;
    return self;
}

- (NSString*)           getID           { return ID; }
- (NSString*)           getDescription  { return description; }
- (NSString*)           getValidValues  { return validValues; }
- (NSArray<NSString*>*) getValidStrings { return validStrings; }

@end
