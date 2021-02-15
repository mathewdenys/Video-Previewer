#ifndef Configuration_hpp
#define Configuration_hpp

#include <iostream>
#include <fstream>       // for std::ifstream, std::ofstream
#include <array>         // for std::array
#include <vector>        // for std::vector
#include <unordered_map> // for std::unordered_map
#include <optional>      // for std::optional
#include <sstream>       // for std::stringstream

#include "Exceptions.hpp"

using std::cout;
using std::array;
using std::string;
using std::wstring;
using std::stringstream;
using std::vector;
using std::pair;

namespace fs = std::filesystem;

/*----------------------------------------------------------------------------------------------------
     When adding support for a new option, ...
        - Add an entry to `ConfigOption::recognisedOptionInfo` (declaration and definition)
        - Add the required implementation to the C++ files
        - Add the required implementation to the Swift files

 
     When adding support for an option with a new set of "valid option values", ...
        - Add a corresponding entry to the `ValidOptionValue` enum
        - Add a corresponding entry to the `NSValidOptionValue` enum
        - Add a case to ConfigOption::determineValidity()
            - This may involve writing additional functions to call
        - Add a case to NSOptionInformation initializer
        - Add an entry to ConfigRowView for displaying the configuration option
 
 
     When adding support for an option with a new underlying data type, ...
        - Add a new "using OptionalX   = std::optional<X>" statement (at start of ConfigValues section)
 
        - Define a corresponding BaseConfigValue::getX() method
        - Define a corresponding ConfigValueX class
 
        - Define a corresponding ConfigOption constructor
        - Define a corresponding ConfigOption::setValue() method
        - Define a corresponding ConfigOptionsHandler::setOption() method
 
        - Add an entry to ConfigFile::MakeOptionsFromStrings()
 
        - Define a corresponding VideoPreview::setOption() method
 
        - Add a corresponding NSConfigValue::XVal variable
        - Add an entry to NSConfigValue::init() method
        - Define a corresponding NSConfigValue::getX() method
 
        - Define a corresponding NSVideoPreview::setOptionValue:withX() method
 
        - Add inputX and bindX variables to ConfigRowView
            - Add corresponding entries in the .onAppear{}

 ----------------------------------------------------------------------------------------------------*/

/*----------------------------------------------------------------------------------------------------
    MARK: - ConfigValues
   ----------------------------------------------------------------------------------------------------*/

using OptionalBool   = std::optional<bool>;
using OptionalInt    = std::optional<int>;
using OptionalDouble  = std::optional<double>;
using OptionalString = std::optional<string>;


// Abstract base class for storing a configuration value. Can store the value as either a bool, int, or string.
// The "get" functions return a std::optional of that type. It is up to the caller to verify that this contains
// a value. This base class is defined such that derived ConfigValueX objects can be stored in shared_ptrs and
// passed around without knowing at complie time what data type is stored in each object.
class BaseConfigValue
{
public:
    virtual OptionalBool   getBool()     const { return OptionalBool{};   }
    virtual OptionalInt    getInt()      const { return OptionalInt{};    }
    virtual OptionalDouble getDouble()   const { return OptionalDouble{}; }
    virtual OptionalString getString()   const { return OptionalString{}; }
    virtual string         getAsString() const = 0;

    virtual ~BaseConfigValue() = default;
};


using ConfigValuePtr = std::shared_ptr<BaseConfigValue>; // Using `shared_ptr` allows `ConfigValuePtr`s to be safely returned by functions


// Derived classes of BaseConfigValue
class ConfigValueBool : public BaseConfigValue
{
public:
    ConfigValueBool(const bool& valIn) : value{ valIn } {}
    
    OptionalBool getBool()     const override { return value; }
    string       getAsString() const override { return (getBool().value() ? "true" : "false"); }
  
private:
    bool value {};
};


class ConfigValueInt : public BaseConfigValue
{
public:
    ConfigValueInt(const int& valIn) : value{ valIn } {}
    
    OptionalInt getInt()      const override { return value; }
    string      getAsString() const override { return std::to_string(value); }
    
private:
    int value {};
};


class ConfigValueDouble : public BaseConfigValue
{
public:
    ConfigValueDouble(const double& valIn) : value{ valIn } {}
    
    OptionalDouble getDouble()   const override { return value; }
    string         getAsString() const override { return std::to_string(value); }
    
private:
    double value {};
};


class ConfigValueString : public BaseConfigValue
{
public:
    ConfigValueString(const string& valIn) : value{ valIn } {}
    
    OptionalString getString()   const override { return value; }
    string         getAsString() const override { return value; }
    
private:
    string value {};
};


/*----------------------------------------------------------------------------------------------------
    MARK: - ValidOptionValue
   ----------------------------------------------------------------------------------------------------*/

// Enumerates the valid values a ConfigOption may have
enum class ValidOptionValue
{
    eBoolean,                 // A boolean
    ePositiveInteger,         // A positive integer
    ePositiveIntegerOrString, // Either a positive integer or a string
    ePercentage,              // A percentage (int between 0 and 100)
    eDecimal,                 // A number between 0 and 1 (inclusive)
    eString,                  // A set of predefined strings
};


/*----------------------------------------------------------------------------------------------------
    MARK: - OptionInformation
   ----------------------------------------------------------------------------------------------------*/

// Class for storing information about configuration options that the program recognises
class OptionInformation
{
public:
    // Constructor without validStrings
    OptionInformation(const string& descriptionIn, const ValidOptionValue& validValuesIn, const ConfigValuePtr& defaultValueIn) :
        description  { descriptionIn },
        validValues  { validValuesIn },
        defaultValue { defaultValueIn }
    {}

    // Constructor with validStrings
    OptionInformation(const string& descriptionIn, const ValidOptionValue& validValuesIn, const vector<string>& validStringsIn, const ConfigValuePtr& defaultValueIn) :
        OptionInformation ( descriptionIn, validValuesIn, defaultValueIn )
    {
        if (validValues == ValidOptionValue::eString || validValues == ValidOptionValue::ePositiveIntegerOrString)
            validStrings = validStringsIn;
    }

    const string&           getDescription()  const { return description; }
    const ValidOptionValue& getValidValues()  const { return validValues; }
    const vector<string>    getValidStrings() const { return validStrings; }
    const ConfigValuePtr    getDefaultValue() const { return defaultValue; }

private:
    string           description  {}; // Human-readable description
    ValidOptionValue validValues  {}; // The valid values this option may have
    vector<string>   validStrings {}; // List of allowed values when validValues = ValidOptionValue::eString
    ConfigValuePtr   defaultValue {}; // A default value to supply if needed when the option isn't supplied by a config file
};

/*----------------------------------------------------------------------------------------------------
    MARK: - ConfigOption
   ----------------------------------------------------------------------------------------------------*/

// Base class for storing a single configuration option. A ConfigOption object is instantiated for
// each option loaded from the configuration files for a given `VideoPreview` object. The optionValue
// is stored as a ConfigValuePtr, which means that the underlying data type of the value is not fixed
// (it can be changed via the setValue() method), which allows for options to have valid values of
// multiple different data types.
class ConfigOption
{
public:
    ConfigOption(const string& id, const ConfigValuePtr value): optionID{ id }, optionValue{ value }
    {
        determineValidity();
    }
    
    // Constructors that accept option values of specific data types
    ConfigOption(const string& id, const bool   value) : ConfigOption( id, std::make_shared<ConfigValueBool>(value)   ) {}
    ConfigOption(const string& id, const int    value) : ConfigOption( id, std::make_shared<ConfigValueInt>(value)    ) {}
    ConfigOption(const string& id, const double value) : ConfigOption( id, std::make_shared<ConfigValueDouble>(value) ) {}
    ConfigOption(const string& id, const string value) : ConfigOption( id, std::make_shared<ConfigValueString>(value) ) {}

    ConfigValuePtr getValue()         const { return optionValue; }
    string         getValueAsString() const { return optionValue->getAsString(); }
    string         getID()            const { return optionID; }
    string         getConfigString()  const { return getID() + " = " + getValueAsString(); } // Return a string of the form "id = val", for writing the configuration option to a file
    void           print()            const { cout << '\t' << getID() << ": " << getValueAsString() << '\n'; }
    
    bool           isValid()          const { return (hasValidID && hasValidValue); }
    
    void setValue(const bool value)
    {
        ConfigValuePtr oldValue { optionValue };
        optionValue = std::make_shared<ConfigValueBool>(value);
        determineValidity();
        if (!hasValidValue)
            optionValue = oldValue;
    }
    
    void setValue(const int value)
    {
        ConfigValuePtr oldValue { optionValue };
        optionValue = std::make_shared<ConfigValueInt>(value);
        determineValidity();
        if (!hasValidValue)
            optionValue = oldValue;
    }
    
    void setValue(const double value)
    {
        ConfigValuePtr oldValue { optionValue };
        optionValue = std::make_shared<ConfigValueDouble>(value);
        determineValidity();
        if (!hasValidValue)
            optionValue = oldValue;
    }
    
    void setValue(const string value)
    {
        ConfigValuePtr oldValue { optionValue };
        optionValue = std::make_shared<ConfigValueString>(value);
        determineValidity();
        if (!hasValidValue)
            optionValue = oldValue;
    }
    
    string  getDescription() const
    {
        try
        {
            return recognisedOptionInfo.at(optionID).getDescription();
        }
        catch (std::out_of_range exception)
        {
            return "[[Unrecognised optionID has no description]]";
        }
    }
    
private:
    // Determines whether `optionID` is recognised, and if so, whether `optionValue` is valid
    // The results are written to the `hasValidID` and `hasValidValue` members
    // Determined by looking up `recognisedOptionInfo`
    void determineValidity();

    bool optionValueIsBool() const
    {
        return getValue()->getBool().has_value();
    }

    bool optionValueIsPositiveInteger() const
    {
        OptionalInt ovalue = getValue()->getInt();
        return ovalue.has_value() && ovalue.value() > 0;
    }
    
    bool optionValueIsPercentage() const
    {
        OptionalInt ovalue = getValue()->getInt();
        return ovalue.has_value() && ovalue.value() >= 0 && ovalue.value() <= 100;
    }
    
    bool optionValueIsBetweenZeroAndOne() const
    {
        OptionalDouble ovalue = getValue()->getDouble();
        return ovalue.has_value() && ovalue.value() >= 0.0 && ovalue.value() <= 1.0;
    }

    bool optionValueIsValidString(vector<string> validStrings) const // Assumes the ID has already been validated
    {
        auto valueExists = [&](const string& s) { return s == optionValue->getString(); };
        return std::find_if(validStrings.begin(), validStrings.end(), valueExists) != validStrings.end();
    }

private:
    string         optionID      {};      // The id / name of the option
    ConfigValuePtr optionValue   {};      // The value of the option
    bool           hasValidID    = false; // Default to having an unrecognised ID. Is changed in the constructor if needed
    bool           hasValidValue = false; // Default to having an invalid value. Is changed in the contructor if needed
    
public:
    using OptionInformationMap = std::unordered_map<string, OptionInformation>;    
    const static OptionInformationMap recognisedOptionInfo; // A map from each optionID that the program recognisesto an associated NSOptionInformation object
};


using ConfigOptionPtr = std::shared_ptr<ConfigOption>; // Using `shared_ptr` allows `ConfigOptionPtr`s to be safely returned by functions



/*----------------------------------------------------------------------------------------------------
    MARK: - ConfigOptionVector
   ----------------------------------------------------------------------------------------------------*/

// Container class for a vector of config_ptrs, with helper functions
class ConfigOptionVector
{
public:
    ConfigOptionVector() {}                                                          // Default constructor
    ConfigOptionVector(vector<ConfigOptionPtr> optionsIn) : options{ optionsIn } {}  // Construct from vector of ConfigOptionPtrs
    ConfigOptionVector(ConfigOptionPtr optionIn) : options{ optionIn } {}            // Construct from a single ConfigOptionPtr

    using iterator       = vector<ConfigOptionPtr>::iterator;
    using const_iterator = vector<ConfigOptionPtr>::const_iterator;

    // The following funcions allow ConfigOptionVector to act appropriately in range-based iterators
    iterator       begin()       { return options.begin(); }
    iterator       end()         { return options.end();   }
    const_iterator begin() const { return options.begin(); }
    const_iterator end()   const { return options.end();   }

    // The following functions provide a similar public interface as a vector (while limiting direct access to `options`)
    void           erase(iterator i)                 { options.erase(i); }
    void           erase(iterator i1, iterator i2)   { options.erase(i1, i2); }
    void           push_back(ConfigOptionPtr option) { options.push_back(option); }
    void           clear()                           { options.clear(); }
    long           size() const                      { return options.size(); }

    // Return a `ConfigOptionPtr` to the element in `options` corresponding to `optionID`.
    // In the case that no element in `options` corresponds to `optionID`, returns nullptr.
    // It is up to the caller to check if nullptr has been returned.
    ConfigOptionPtr getOption(const string& optionID) const
    {
        // Search for optionID in the options vector
        auto IDmatches = [&](ConfigOptionPtr option) { return option->getID() == optionID; };
        auto optionItr = std::find_if(options.begin(), options.end(), IDmatches);
        
        // If optionID was found in options, return the corresponding element
        if (optionItr != options.end())
            return *optionItr;
        
        return nullptr;
    }

private:
    vector<ConfigOptionPtr> options {};
};



/*----------------------------------------------------------------------------------------------------
    MARK: - ConfigFile
   ----------------------------------------------------------------------------------------------------*/

// Base class corresponding to a single configuration file
class ConfigFile
{
public:
    ConfigFile(const string& filePathIn) : filePath{ filePathIn }{ parseFile(); }

    string&             getFilePath()       { return filePath; }
    ConfigOptionVector& getOptions()        { return options; }
    ConfigOptionVector& getInvalidOptions() { return invalidOptions; }

    using idValPair = pair<string,string>;

    // Parse a single line of the configuration file and return a std::pair containing strings representing the
    // option's ID and value. Each line is assumed to be formatted as `id = val`, i.e. blank lines and comment
    // lines are not handled.
    static idValPair parseLine(stringstream& ss);

protected:
    // Parse the file `filePath` and write the parsed options to the `options` vector
    void parseFile();

    // Return a `ConfigOptionPtr` from an `idValPair`
    ConfigOptionPtr makeOptionFromStrings(const idValPair& inputPair);

    bool stringToBool(const string& str) const
    {
        return (str == "true");
    }

    int stringToInt(const string& str) const
    {
        int myInt;
        stringstream ss{ str };
        ss >> myInt;
        return myInt;
    }
    
    double stringToDouble(const string& str) const
    {
        double myDouble;
        stringstream ss{ str };
        ss >> myDouble;
        return myDouble;
    }

    bool isInt(const string& str) const
    {
        // Return false if str contains any characters that identify it as a floating point
        // number. This is necessary because stringstream extraction will cast floating point
        // numbers to ints, but we explicitly want to check if str corresponds to an int but
        // NOT a floating point number.
        std::size_t floatIdentifierIndex = str.find_first_of(".eEpPfFlL");
        if (floatIdentifierIndex != std::string::npos)
            return false;
            
        int myInt;
        stringstream ss{ str };
        return static_cast<bool>(ss >> myInt);     // stringstream extraction operator performs casts if it can returns false otherwise

    }
    
    bool isDouble(const string& str) const
    {
        double myDouble;
        stringstream ss{ str };
        return static_cast<bool>(ss >> myDouble);     // stringstream extraction operator performs casts if it can returns false otherwise

    }

protected:
    string             filePath {};
    ConfigOptionVector options {};
    ConfigOptionVector invalidOptions {}; // Stores unrecognised config options and those with invalid values
};


using ConfigFilePtr = std::shared_ptr<ConfigFile>;



/*----------------------------------------------------------------------------------------------------
    MARK: - ConfigOptionsHandler
   ----------------------------------------------------------------------------------------------------*/

// Container class for dealing with configuration options. Has three main purposes
//      1. Merging all the configuration files into a single set of options
//      2. Storing the current state of the configuration options
//      3. Writing options to configuration files
class ConfigOptionsHandler
{
public:
    ConfigOptionsHandler() {};                     // Default constructor
    ConfigOptionsHandler(const string& videoPath); // Contructor that loads the configuration options

    vector<ConfigFilePtr>&     getConfigFiles()                        { return configFiles; }
    const ConfigOptionVector&  getOptions()                            { return configOptions; }
    const ConfigOptionVector&  getInvalidOptions()                     { return invalidConfigOptions; }
    
    void                       setOption(const ConfigOptionPtr& option);
    void                       setOption(const string& optionID, bool val);
    void                       setOption(const string& optionID, int val);
    void                       setOption(const string& optionID, double val);
    void                       setOption(const string& optionID, string val);

    // Save a set of current configuration options to a preexisting configuration file
    // The first time that the given option is found in the file, the up-to-date value is overwritten
    // If the same option is specified again later in the file it is left unchanged
    // Any new options that are unspecified in the file are appended to the end
    void saveOptions(ConfigOptionVector options, const ConfigFilePtr file);
    
    void saveAllOptions(const ConfigFilePtr file)                          { saveOptions(configOptions, file); }
    
    void print() const
    {
        for (ConfigOptionPtr option : configOptions)
            option->print();
    }

private:
    // Load each relevant configuration file, and push a corresponding ConfigFilePtr to configFiles
    void loadOptions(const string& videoPath);
    
    // Merge the valid [invalid] ConfigOptionVectors stored in each ConfigFilePtr in the configFiles vector into
    // a single ConfigOptionVector, which overwrites configOptions [invalidConfigOptions]
    void mergeOptions();

private:
    vector<ConfigFilePtr> configFiles {};
    ConfigOptionVector    configOptions {};
    ConfigOptionVector    invalidConfigOptions {}; // Stores unrecognised config options and those with invlaid values
};


#endif /* Configuration_hpp */
