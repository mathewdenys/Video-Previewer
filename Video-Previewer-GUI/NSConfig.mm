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
    NSValidOptionValue  validValues;
    NSArray<NSString*>* validStrings;
}

- (NSString*)           getID           { return ID; }
- (NSString*)           getDescription  { return description; }
- (NSValidOptionValue)  getValidValues  { return validValues; }
- (NSArray<NSString*>*) getValidStrings { return validStrings; }

@end

//    MARK: - NSOptionInformation (cpp_compatibility)

@implementation NSOptionInformation (cpp_compatibility)

- (NSOptionInformation*) fromOptionInformation:(const OptionInformation&)optInfo withID: (const string&)ID
{
    self->ID          = [NSString fromStdString:ID];
    self->description = [NSString fromStdString:optInfo.getDescription()];
    
    ValidOptionValue  v = optInfo.getValidValues();
    switch (v)
    {
        case ValidOptionValue::eBoolean:
            self->validValues = NSValidOptionValue::eBoolean;
            break;
            
        case ValidOptionValue::ePositiveInteger:
            self->validValues = NSValidOptionValue::ePositiveInteger;
            break;
            
        case ValidOptionValue::ePositiveIntegerOrString:
            self->validValues = NSValidOptionValue::ePositiveIntegerOrString;
            break;
            
        case ValidOptionValue::ePercentage:
            self->validValues = NSValidOptionValue::ePercentage;
            break;
            
        default:
            self->validValues = NSValidOptionValue::eString;
            break;
    }
    
    NSMutableArray* strings_ns = [NSMutableArray new];
    if (v == ValidOptionValue::eString || v == ValidOptionValue::ePositiveIntegerOrString)
    {
        vector<string> strings_std { optInfo.getValidStrings() };
        for (string s : strings_std)
        {
            [strings_ns addObject: [NSString fromStdString:s]];
        }
    }
    self->validStrings = strings_ns;
    
    return self;
}

@end
