#ifndef Configuration_hpp
#define Configuration_hpp

#include <iostream>
#include <fstream>  // for std::ifstream, std::ofstream
#include <array>    // for std::array
#include <vector>   // for std::vector
#include <optional> // for std::optional
#include <sstream>  // for std::stringstream

#include "Exceptions.hpp"

using std::cout;
using std::array;
using std::string;
using std::stringstream;
using std::vector;
using std::pair;

namespace fs = std::filesystem;

/*----------------------------------------------------------------------------------------------------
    MARK: - AbstractConfigValue & derived classes

        When adding support for a new option data type, update
            - The set of "using OptionalX" statements
            - The set of virtual getX() statements in BaseConfigOption and ConfigOption<T>
            - The set of template specialised ConfigValue::getAsString() functions
            - ConfigOptionsHandler::makeOptionFromStrings()
   ----------------------------------------------------------------------------------------------------*/

using OptionalBool   = std::optional<bool>;
using OptionalInt    = std::optional<int>;
using OptionalString = std::optional<string>;


// Abstract base class for storing a configuration value. Can store the value as either a bool, int, or string.
// The "get" functions return a std::optional of that type. It is up to the caller to verify that this contains
// a value. This base class is defined such that derived ConfigValue<T> objects can be stored in shared_ptrs and
// passed around without knowing at complie time what data type is stored in each object.
class BaseConfigValue
{
public:
    virtual OptionalBool   getBool()     const = 0;
    virtual OptionalInt    getInt()      const = 0;
    virtual OptionalString getString()   const = 0;
    virtual string         getAsString() const = 0;

    virtual ~BaseConfigValue() = default;
};


// Templated derived classes of BaseConfigValue
template <class T>
class ConfigValue : public BaseConfigValue
{
public:
    ConfigValue(const T& valIn) : value{ valIn } {}

    // These "get" functions must be explicitly defined because virtual functions can't be templated
    OptionalBool   getBool()     const override { return get<bool>(); }
    OptionalInt    getInt()      const override { return get<int>(); }
    OptionalString getString()   const override { return get<string>(); }
    string         getAsString() const override;

protected:
    // Templated functions, get<U>(), return a std::optional of type U
    // If T = U, the std::optional contains `value`; otherwise it is "empty" (default constructor)
    template <class U>
    std::optional<U> get() const
    {
        if constexpr(std::is_same_v<T,U>)
            return {value};
        return std::optional<U>{};
    }

private:
    T value;
};



/*----------------------------------------------------------------------------------------------------
    MARK: - RecognisedConfigOption + BaseConfigOption & derived classes

        When adding support for a new option, update
            - BaseConfigOption::recognisedConfigOptions (declaration and definition)

        When adding support for an option with a new set of "valid option values", update
            - ValidOptionValues
            - BaseConfigOption::hasValidValue()
   ----------------------------------------------------------------------------------------------------*/

// Enumerates the valid values a RecognisedConfigOption may have
enum class ValidOptionValues
{
    eBoolean,           // A boolean
    ePositiveInteger,   // A positive integer
    eString,            // A set of predefined strings
};


// Class for storing information about configuration options that the program recognises
class RecognisedConfigOption
{
public:
    RecognisedConfigOption(const string& idIn, const string& descriptionIn, const ValidOptionValues& validValuesIn) :
        id          { idIn },
        description { descriptionIn },
        validValues { validValuesIn }
    {}

    RecognisedConfigOption(const string& idIn, const string& descriptionIn, const ValidOptionValues& validValuesIn, const vector<string>& validStringsIn) :
        RecognisedConfigOption ( idIn, descriptionIn, validValuesIn )
    {
        if (validValues == ValidOptionValues::eString)
            validStrings = validStringsIn;
    }

    const string&            getID()           const { return id; }
    const string&            getDescription()  const { return description; }
    const ValidOptionValues& getValidValues()  const { return validValues; }
    const vector<string>     getValidStrings() const { return validStrings; }

private:
    string id;                         // Option-specific identifier
    string description;                // Human-readable description
    ValidOptionValues validValues;     // The valid values this option may have
    vector<string>    validStrings {}; // List of allowed values when validValues = ValidOptionValues::eString
};


using ConfigValuePtr = std::shared_ptr<BaseConfigValue>; // Using `shared_ptr` allows `ConfigValuePtr`s to be safely returned by functions


// Base class for storing a single configuration option. One of its derived classes is created
// for each option loaded from the configuration files for a given `VideoPreview` object.
class BaseConfigOption
{
public:
    BaseConfigOption(const string& id, const ConfigValuePtr value) : optionID{ id }, optionValue{ value }
    {
        determineValidity();
    }

    virtual std::shared_ptr<BaseConfigOption> clone() const = 0; // "virtual copy constructor"

    ConfigValuePtr getValue()            const { return optionValue; }
    string         getValueAsString()    const { return optionValue->getAsString(); }
    string         getID()               const { return optionID; }
    string         getConfigFileString() const { return getID() + " = " + getValueAsString(); } // Return a string of the form "id = val", for writing the configuration option to a file
    void           print()               const { cout << '\t' << getDescription() << ": " << getValueAsString() << '\n'; }
    bool           isValid()             const { return (hasValidID && hasValidValue); }

protected:
    // Returns an iterator to the element of recognisedConfigOptions with the same ID
    // If no such element exists, returns an iterator to recognisedConfigOptions.end()
    auto findRecognisedOptionWithSameID() const
    {
        auto IDmatches =  [&](RecognisedConfigOption recognisedOption) { return recognisedOption.getID() == optionID; };
        return std::find_if(recognisedConfigOptions.begin(), recognisedConfigOptions.end(), IDmatches);
    }

public:
    string  getDescription() const
    {
        auto recognisedOpt = findRecognisedOptionWithSameID();     // Iterator to the element of recognisedConfigOptions with the same ID
        if (recognisedOpt == recognisedConfigOptions.end())        // If optionID does not match any of the recognised options
            return "[[Unrecognised optionID has no description]]";
        return recognisedOpt->getDescription();
    }

    virtual ~BaseConfigOption() {};

protected:
    // Determines whether `optionID` is recognised, and if so, whether `optionValue` is valid
    // The results are written to the `hasValidID` and `hasValidValue` members
    // Determined by looking up `recognisedConfigOptions
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

    bool optionValueIsValidString(vector<string> validStrings) const // Assumes the ID has already been validated
    {
        auto valueExists = [&](const string& s) { return s == optionValue->getString(); };
        return std::find_if(validStrings.begin(), validStrings.end(), valueExists) != validStrings.end();
    }

protected:
    string optionID;            // The id / name of the options
    ConfigValuePtr optionValue; // The value of the option
    bool hasValidID    = false; // Default to having an unrecognised ID. Is changed in the constructor if needed
    bool hasValidValue = false; // Default to having an invalid value. Is changed inthe contructor if needed
    const static array<RecognisedConfigOption,3> recognisedConfigOptions;
};


using ConfigOptionPtr = std::shared_ptr<BaseConfigOption>; // Using `shared_ptr` allows `ConfigOptionPtr`s to be safely returned by functions


// Templated derived classes of BaseConfigOption
// T corresponds to the data type of the configuration options
template<class T>
class ConfigOption : public BaseConfigOption
{
public:
    ConfigOption(const string& idIn, const T& valIn) :
        BaseConfigOption{ idIn, makeConfigValuePtr(valIn) }
    {}

    ConfigOptionPtr clone() const override { return std::make_shared<ConfigOption<T> >(*this); } // "virtual copy constructor"

    void setValue(const T& valIn) { optionValue = makeConfigValuePtr(valIn); }
    
private:
    ConfigValuePtr makeConfigValuePtr(const T& valIn) { return std::make_shared< ConfigValue<T> >(valIn); }
};



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
    // In the case that no element in `options` corresponds to `optionID`, returns the null pointer.
    // It is up to the caller to verify if nullptr has been returned.
    ConfigOptionPtr getOption(const string& optionID) const
    {
        for (ConfigOptionPtr option : options)
            if (option->getID() == optionID)
                return option;
        return nullptr;
    }

    // Add a new configuration option to the `options` vector.
    // If the option already exists in `options`, the current value is removed first, to avoid conflicts
    void setOption(const BaseConfigOption& optionIn)
    {
        auto IDexists = [&](ConfigOptionPtr option) { return option->getID() == optionIn.getID(); };

        options.erase( std::remove_if(options.begin(), options.end(), IDexists), options.end() );
        options.push_back( optionIn.clone() );
    }

private:
    vector<ConfigOptionPtr> options;
};



/*----------------------------------------------------------------------------------------------------
    MARK: - ConfigFile + derived classes
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

    bool isInt(const string& str) const
    {
        int myInt;
        stringstream ss{ str };
        return static_cast<bool>(ss >> myInt);     // stringstream extraction operator performs casts if it can returns false otherwise

    }

protected:
    string filePath;
    ConfigOptionVector options;
    ConfigOptionVector invalidOptions {}; // Stores unrecognised config options and those with invlaid values
};


using ConfigFilePtr = std::shared_ptr<ConfigFile>;



/*----------------------------------------------------------------------------------------------------
    MARK: - ConfigOptionsHandler
   ----------------------------------------------------------------------------------------------------*/

// Container class for dealing with configuration options. Has three main purposes
//      1. Merging all the configuration files into a single set of options
//      2. Storing the current state of the configuration options
//          2a. Providing a public interface for changing configuration options
//      3. Writing options to configuration files
class ConfigOptionsHandler
{
public:
    ConfigOptionsHandler(const string& videoPath);

    vector<ConfigFilePtr>&     getConfigFiles()                            { return configFiles; }
    const ConfigOptionVector&  getOptions()                                { return configOptions; }
    const ConfigOptionVector&  getInvalidOptions()                         { return invalidConfigOptions; }
    void                       setOption(const BaseConfigOption& optionIn) { configOptions.setOption(optionIn); }

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
    // Merge the valid [invalid] ConfigOptionVectors stored in each ConfigFilePtr in the configFiles vector into
    // a single ConfigOptionVector, which overwrites configOptions [invalidConfigOptions]
    void mergeOptions();

private:
    vector<ConfigFilePtr> configFiles;
    ConfigOptionVector configOptions;
    ConfigOptionVector invalidConfigOptions {}; // Stores unrecognised config options and those with invlaid values
};


#endif /* Configuration_hpp */
