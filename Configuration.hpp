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

    string  getDescription() const
    {
        for (RecognisedConfigOption recognisedOption : recognisedConfigOptions)
            if (recognisedOption.getID() == optionID)
                return recognisedOption.getDescription();
        return "[[Unrecognised optionID has no description]]"; // If the ID has been validated, this should never to reached. Kept in for debuging purposes
    }

    virtual ~BaseConfigOption() {};

protected:
    // Returns an iterator to the element of recognisedConfigOptions with the same ID
    // If no such element exists, returns an iterator to recognisedConfigOptions.end()
    auto findRecognisedOptionWithSameID() const
    {
        auto IDmatches =  [&](RecognisedConfigOption recognisedOption) { return recognisedOption.getID() == optionID; };
        return std::find_if(recognisedConfigOptions.begin(), recognisedConfigOptions.end(), IDmatches);
    }

    void determineValidity()
    {
        auto templateOption = findRecognisedOptionWithSameID();

        // Invalid ID
        if ( templateOption == recognisedConfigOptions.end() )
        {
            hasValidID = false;
            std::cerr << "\tInvalid option \"" << optionID << "\"\n";
            return;
        }

        hasValidID = true;

        // Invalid Value
        if (templateOption->getValidValues() == ValidOptionValues::eBoolean)
            hasValidValue = optionValueIsBool();

        if (templateOption->getValidValues() == ValidOptionValues::ePositiveInteger)
            hasValidValue = optionValueIsPositiveInteger();

        if (templateOption->getValidValues() == ValidOptionValues::eString)
            hasValidValue = optionValueIsValidString(templateOption->getValidStrings());

        if (!hasValidValue)
            std::cerr << "\tOption with invalid value: \"" << getID() << "\" cannot have the value \"" << optionValue->getAsString() << "\"\n";

    }

    bool optionValueIsBool() const { return getValue()->getBool().has_value(); }

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
    const static array<RecognisedConfigOption,3> recognisedConfigOptions; // Initialised out of class below
};


using ConfigOptionPtr = std::shared_ptr<BaseConfigOption>; // Using `shared_ptr` allows `ConfigOptionPtr`s to be safely returned by functions


// Templated derived classes of BaseConfigOption
// T corresponds to the data type of the configuration options
template<class T>
class ConfigOption : public BaseConfigOption
{
public:
    ConfigOption(const string& idIn, const T& valIn) :
        BaseConfigOption{ idIn, std::make_shared< ConfigValue<T> >(valIn) }
    {}

    ConfigOptionPtr clone() const override { return std::make_shared<ConfigOption<T> >(*this); } // "virtual copy constructor"

    void setValue(const T& valIn) { optionValue = std::make_shared< ConfigValue<T> >(valIn); }
};



/*----------------------------------------------------------------------------------------------------
    MARK: - ConfigOptionVector
   ----------------------------------------------------------------------------------------------------*/

// Container class for a vector of config_ptrs, with helper functions
class ConfigOptionVector
{
public:
    ConfigOptionVector() {}                                                           // Default constructor
    ConfigOptionVector(vector<ConfigOptionPtr> optionsIn) : options{ optionsIn } {}

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

// Base class corresponding to a single configuration file. Has two main purposes
//      1. Parsing the file into a ConfigOptionVector
//      2. Writing configuration options into the corresponding file
class ConfigFile
{
public:
    ConfigFile(const string& filePathIn) : filePath{ filePathIn }{ parseFile(); }

    string&             getFilePath()       { return filePath; }
    ConfigOptionVector& getOptions()        { return options; }
    ConfigOptionVector& getInvalidOptions() { return invalidOptions; }

    // Write an option to the file `filePath`, which is a preexisting configuration file
    // If the file already specifies the option [more than once], its value will be overwritten [and additional ones removed]
    void writeOptionToFile(ConfigOptionPtr option)
    {
        // Open the file for reading any preexisting content
        std::ifstream file{ filePath };
        if (!file)
            throw FileException("could not open file\n", filePath);

        // Open a temporary file for writing to
        string tempFilePath{ filePath + "temp" };
        std::ofstream tempFile{ tempFilePath };
        if (!tempFile)
            throw FileException("could not open temporary file\n", filePath);

        // Copy content from the preexisting file to the temporary file
        // If the preexisting file already specifies the given option, it is replaced
        string line;
        bool optionReplaced = false;
        while (std::getline(file, line))
        {
            stringstream ss{ line };
            ss >> std::ws;     // Remove leading white space
            if ( ss.rdbuf()->in_avail() == 0 ||     // Copy blank lines unchanged to temp file
                 ss.peek() == '#' ||                 // Copy comment lines unchanged to temp file
                 parseLine(ss).first != option->getID()                 // Copy "other" configuration options unchanged to temp file
                 )
            {
                tempFile << line << std::endl;
                continue;
            }

            // The first time that the given option is found in the file, the new value is written to the temp file
            // If the same option is specified again later in the file it is ignored
            if (!optionReplaced)
            {
                tempFile << option->getConfigFileString() << std::endl;
                optionReplaced = true;
            }
        }

        // Move contents of tempFilePath to filePath and delete tempFilePath
        fs::remove(filePath);
        fs::rename(tempFilePath, filePath);
    }

protected:
    // Parse the file `filePath` and write the parsed options to the `options` vector
    void parseFile()
    {
        try
        {
            cout << "Parsing \"" << filePath << "\"\n";
            std::ifstream file{ filePath };
            if (!file)
                throw FileException("could not open file for parsing\n", filePath);

            string line;
            while (std::getline(file, line))
            {
                stringstream ss{ line };
                ss >> std::ws;     // remove leading white space

                // Ignore blank lines and comment lines
                if (ss.rdbuf()->in_avail() == 0 || ss.peek() == '#')
                    continue;

                // Parse the current line into a ConfigOption
                ConfigOptionPtr newOption = makeOptionFromStrings(parseLine(ss));

                // Ignore lines with duplicate options (prioritise options defined higher in the configuration file)
                if ( options.getOption(newOption->getID()) ) // nullptr is returned by getID() if that optionID doesn't exist in options
                    return;

                // If the option is invalid (unrecognised ID or invalid value), add to the `invalidOptions` vector
                if ( !newOption->isValid() )
                {
                    invalidOptions.push_back( newOption );
                    continue;
                }

                // Add the valid option to the `options` vector
                options.push_back( newOption );
            }
        }
        catch (const FileException& exception)
        {
            std::cerr << exception.what();
        }

    }

    using idValPair = pair<string,string>;

    // Parse a single line of the configuration file and return a std::pair containing strings representing the
    // option's ID and value. Each line is assumed to be formatted as `id = val`, i.e. blank lines and comment
    // lines are not handled.
    idValPair parseLine(stringstream& ss)
    {
        string id;
        string val;

        char c;
        bool reachedEqualsSign = false;
        while (ss.get(c))
        {
            if (c == '#')     // ignore comments
                break;
            if (c == '=')     // switch from writing to `id` to `val` when of RHS of equals sign
                reachedEqualsSign = true;
            else if (!reachedEqualsSign)
                id.push_back(c);
            else
                val.push_back(c);
            ss >> std::ws;     // always remove any following white space
        }

        return idValPair{ id, val };
    }

    // Return a `ConfigOptionPtr` from an `idValPair`
    ConfigOptionPtr makeOptionFromStrings(const idValPair& inputPair)
    {
        string id  = inputPair.first;
        string val = inputPair.second;

        if (val == "true" || val == "false")
            return std::make_shared< ConfigOption<bool> >(id, stringToBool(val));

        if (isInt(val))
            return std::make_shared< ConfigOption<int> >(id, stringToInt(val));

        return std::make_shared< ConfigOption<string> >(id, val);
    }

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



class GlobalConfigFile : public ConfigFile
{
public:
    GlobalConfigFile() : ConfigFile("/etc/videopreviewconfig") {}
};


class UserConfigFile : public ConfigFile
{
public:
    UserConfigFile() : ConfigFile( string(std::getenv("HOME")) + "/.config/videopreview" ) {}
};


class LocalConfigFile : public ConfigFile
{
public:
    LocalConfigFile(const string& filePathIn) : ConfigFile(filePathIn) {}
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
    ConfigOptionsHandler(const string& videoPath)
    {
        // Remove the name of the video file from videoPath, to isolate the directory it is in
        string localDir = videoPath.substr(0,videoPath.find_last_of("\\/"));
        string localConfigFilePath;

        // Scan through all directories between that containing the video and the user home
        //  directory (or the root directory if the user home directory isn't in the hierarchy)
        while ( localDir.length() > 0 && localDir != std::getenv("HOME") )
        {
            localConfigFilePath = localDir + "/.videopreviewconfig";
            if (fs::exists(localConfigFilePath))
                configFiles.push_back( std::make_shared<LocalConfigFile>(localConfigFilePath) );         // Load local config files
            localDir = localDir.substr(0,localDir.find_last_of("\\/"));
        }

        configFiles.push_back( std::make_shared<UserConfigFile>() );                                     // Load user config file
        configFiles.push_back( std::make_shared<GlobalConfigFile>() );                                   // Load global config file

        mergeOptions();
    }

    const ConfigOptionVector&  getOptions()                                { return configOptions; }
    const ConfigOptionVector&  getInvalidOptions()                         { return invalidConfigOptions; }
    void                       setOption(const BaseConfigOption& optionIn) { configOptions.setOption(optionIn); }

    void saveOption(ConfigOptionPtr option, const string& filePath)
    {
        // If filePath corresponds to any of the files in configFiles, use the corresponding ConfigFile's writeOptionToFile() member function
        for (ConfigFilePtr file : configFiles)
            if (file->getFilePath() == filePath)
            {
                file->writeOptionToFile(option);
                return;
            }

        std::cerr << "Could not save option to configuration file \"" << filePath << "\" as it is not a recognised configuration file\n";
    }

    void print() const
    {
        for (ConfigOptionPtr option : configOptions)
            option->print();
    }

private:
    // Merge the valid [invalid] ConfigOptionVectors stored in each ConfigFilePtr in the configFiles vector into
    // a single ConfigOptionVector, which overwrites configOptions [invalidConfigOptions]
    void mergeOptions()
    {
        configOptions.clear();

        // The configFiles vector is ordered from highest priority to lowest priority, so we scan through it in order.
        // For each file we add any configuration options that haven't been imported yet. Any others can be ignored because
        // the value that has already been imported is from a higher priority configuration file
        for ( ConfigFilePtr& file : configFiles)
        {
            // Merge valid options
            for ( ConfigOptionPtr& opt : file->getOptions() )
                if ( string id{ opt->getID() }; !configOptions.getOption(id) )
                    configOptions.push_back(opt);

            // Merge invalid options
            for ( ConfigOptionPtr& opt : file->getInvalidOptions() )
                if ( string id{ opt->getID() }; !invalidConfigOptions.getOption(id) )
                    invalidConfigOptions.push_back(opt);
        }
    }

private:
    vector<ConfigFilePtr> configFiles;
    ConfigOptionVector configOptions;
    ConfigOptionVector invalidConfigOptions {}; // Stores unrecognised config options and those with invlaid values
};


#endif /* Configuration_hpp */
