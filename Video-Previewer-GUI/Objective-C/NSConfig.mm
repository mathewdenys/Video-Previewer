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
    NSNumber* doubleVal;
    NSString* stringVal;
}

- (NSNumber*) getBool   { return boolVal;   }
- (NSNumber*) getInt    { return intVal;    }
- (NSNumber*) getDouble { return doubleVal; }
- (NSString*) getString { return stringVal; }

@end

// MARK: - NSConfigValue (cpp_compatibility)

@implementation NSConfigValue (cpp_compatibility)

- (NSConfigValue*) init:(const ConfigValuePtr&)valuePtr
{
    if (valuePtr->getBool().has_value())
        boolVal = [NSNumber numberWithBool: valuePtr->getBool().value()];
    
    if (valuePtr->getInt().has_value())
        intVal = [NSNumber numberWithInt:  valuePtr->getInt().value()];
    
    if (valuePtr->getDouble().has_value())
        doubleVal = [NSNumber numberWithDouble:  valuePtr->getDouble().value()];
    
    if (valuePtr->getString().has_value())
        stringVal = [NSString fromStdString:  valuePtr->getString().value()];
    
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

- (NSConfigOption*) init:(const ConfigOption&)option
{
    ID = [NSString fromStdString:option.getID()];
    ConfigValuePtr valueIn = option.getValue();
    value = [[NSConfigValue alloc] init: valueIn];
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
            
        case ValidOptionValue::ePositiveIntegerOrAuto:
            self->validValues = NSValidOptionValue::ePositiveIntegerOrAuto;
            break;
            
        case ValidOptionValue::ePositiveIntegerOrString:
            self->validValues = NSValidOptionValue::ePositiveIntegerOrString;
            break;
            
        case ValidOptionValue::ePercentage:
            self->validValues = NSValidOptionValue::ePercentage;
            break;
            
        case ValidOptionValue::eDecimal:
            self->validValues = NSValidOptionValue::eDecimal;
            break;
            
        case ValidOptionValue::eDecimalOrAuto:
            self->validValues = NSValidOptionValue::eDecimalOrAuto;
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
