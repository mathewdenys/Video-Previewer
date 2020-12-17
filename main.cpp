#include <iostream>
#include <fstream>
#include <sstream>
#include <memory>
#include <vector>
#include <map>
#include <utility>    // for std::pair
#include <cstdlib>    // for std::getenv
#include <filesystem> // for std::filesystem::create_directories, remove, rename, is_empty, etc. [requires C++17]
#include <optional>   // for std::optional

#if defined(__has_warning)
#if __has_warning("-Wreserved-id-macro")
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdocumentation"
#endif
#endif

#include <opencv2/core/mat.hpp>  // for basic OpenCV structures (Mat, Scalar)
#include <opencv2/imgcodecs.hpp> // for reading and writing
#include <opencv2/videoio.hpp>

#if defined(__has_warning)
#if __has_warning("-Wdocumentation")
#pragma GCC diagnostic pop
#endif
#endif


using std::cout;
using std::string;
using std::stringstream;
using std::array;
using std::vector;
using std::pair;
using cv::Mat;

namespace fs = std::filesystem;

/*----------------------------------------------------------------------------------------------------
    MARK: - Exception Classes
   ----------------------------------------------------------------------------------------------------*/

class FileException : public std::exception
{
public:
    FileException(string errorDescription, string fileIn) : file{ fileIn }, message{ "Error when accessing \"" + fileIn + "\": " + errorDescription } {};
    const char* what() const noexcept override { return message.c_str(); }

protected:
    string message;
    string file;
};


class InvalidOptionException : public std::exception
{
public:
    InvalidOptionException(string errorDescription) : message{ "Invalid option: " + errorDescription } {};
    const char* what() const noexcept override { return message.c_str(); }

private:
    string message;
};



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
class AbstractConfigValue
{
public:
    virtual OptionalBool   getBool()     const = 0;
    virtual OptionalInt    getInt()      const = 0;
    virtual OptionalString getString()   const = 0;
    virtual string         getAsString() const = 0;

    virtual ~AbstractConfigValue() = default;
};


// Templated derived classes of AbstractConfigValue
template <class T>
class ConfigValue : public AbstractConfigValue
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

// Template specialisation of getAsString() functions
template<> string ConfigValue<bool>  ::getAsString() const { return (getBool().value() ? "true" : "false"); }
template<> string ConfigValue<int>   ::getAsString() const { return std::to_string(getInt().value()); }
template<> string ConfigValue<string>::getAsString() const { return getString().value(); }



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


using ConfigValuePtr = std::shared_ptr<AbstractConfigValue>; // Using `shared_ptr` allows `ConfigValuePtr`s to be safely returned by functions


// Base class for storing a single configuration option. One of its derived classes is created
// for each option loaded from the configuration files for a given `VideoPreview` object.
class BaseConfigOption
{
public:
    BaseConfigOption(const string& id, const ConfigValuePtr value) : optionID{ id }, optionValue{ value }
    {
        if (!hasValidID())
            throw InvalidOptionException{"unrecognised ID \"" + id + "\"\n"};

        if (!hasValidValue())
            throw InvalidOptionException('\"' + getID() + "\" cannot have the value \"" + value->getAsString() + "\"\n");
    }

    virtual std::shared_ptr<BaseConfigOption> clone() const = 0; // "virtual copy constructor"

    ConfigValuePtr getValue()            const { return optionValue; }
    string         getValueAsString()    const { return optionValue->getAsString(); }
    string         getID()               const { return optionID; }
    string         getConfigFileString() const { return getID() + " = " + getValueAsString(); } // Return a string of the form "id = val", for writing the configuration option to a file
    void           print()               const { cout << '\t' << getDescription() << ": " << getValueAsString() << '\n'; }

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
        auto IDmatches
        {
            [this](RecognisedConfigOption recognisedOption)
            {
                return recognisedOption.getID() == optionID;
            }
        };

        return std::find_if(recognisedConfigOptions.begin(), recognisedConfigOptions.end(), IDmatches);
    }

private:
    bool hasValidID() const { return findRecognisedOptionWithSameID() != recognisedConfigOptions.end(); }

    bool hasValidValue() const
    {
        auto templateOption = findRecognisedOptionWithSameID();

        if (templateOption == recognisedConfigOptions.end()) // Invalid ID
            throw InvalidOptionException{"unrecognised ID \"" + getID() + "\"\n"};

        if (templateOption->getValidValues() == ValidOptionValues::eBoolean)
            return optionValueIsBool();

        if (templateOption->getValidValues() == ValidOptionValues::ePositiveInteger)
            return optionValueIsPositiveInteger();

        if (templateOption->getValidValues() == ValidOptionValues::eString)
            return optionValueIsValidString(templateOption->getValidStrings());

        return false; // This should never be reached
    }

    bool optionValueIsBool() const { return getValue()->getBool().has_value(); }

    bool optionValueIsPositiveInteger() const
    {
        OptionalInt ovalue = getValue()->getInt();
        if ( ovalue.has_value() && ovalue.value() > 0 )
            return true;
        return false;
    }

    bool optionValueIsValidString(vector<string> validStrings) const // Assumes the ID has already been validated
    {
        auto valueExists
        {
            [this](string validValue)
            {
                return validValue == optionValue->getString();
            }
        };

        return std::find_if(validStrings.begin(), validStrings.end(), valueExists) != validStrings.end();
    }

protected:
    string optionID;
    ConfigValuePtr optionValue;
    const static array<RecognisedConfigOption,3> recognisedConfigOptions; // Initialised out of class below
};

// An array that contains every RecognisedConfigOption that the program "understands"
const array<RecognisedConfigOption,3> BaseConfigOption::recognisedConfigOptions {
    RecognisedConfigOption("number_of_frames", "Number of frames to show",                 ValidOptionValues::ePositiveInteger        ),
    RecognisedConfigOption("show_frame_info",  "Show individual frame information",        ValidOptionValues::eBoolean                ),
    RecognisedConfigOption("action_on_hover",  "Behaviour when mouse hovers over a frame", ValidOptionValues::eString, {"none","play"}) // TODO: add "slideshow","scrub" as validStrings when I support them
};



// Templated derived classes of BaseConfigOption
// T corresponds to the data type of the configuration options
template<class T>
class ConfigOption : public BaseConfigOption
{
public:
    ConfigOption(const string& idIn, const T& valIn) :
        BaseConfigOption{ idIn, std::make_shared< ConfigValue<T> >(valIn) }
    {}

    std::shared_ptr<BaseConfigOption> clone() const override { return std::make_shared<ConfigOption<T> >(*this); } // "virtual copy constructor"

    void setValue(const T& valIn) { optionValue = std::make_shared< ConfigValue<T> >(valIn); }
};



/*----------------------------------------------------------------------------------------------------
    MARK: - ConfigOptionVector
   ----------------------------------------------------------------------------------------------------*/

using ConfigOptionPtr = std::shared_ptr<BaseConfigOption>; // Using `shared_ptr` allows `ConfigOptionPtr`s to be safely returned by functions

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
        auto IDexists
        {
            [&optionIn](ConfigOptionPtr option)
            {
                return option->getID() == optionIn.getID();
            }
        };

        options.erase( std::remove_if(options.begin(), options.end(), IDexists), options.end() );
        options.push_back( optionIn.clone() );
    }

private:
    vector<ConfigOptionPtr> options;
};



/*----------------------------------------------------------------------------------------------------
    MARK: - ConfigOptionsHandler
   ----------------------------------------------------------------------------------------------------*/

// Enum class that enumerates the different configuration files
enum class ConfigFileLocation
{
    eLocal,
    eUser,
    eGlobal,
};


// Container class for dealing with configuration options. Has three main purposes
//      1. Reading in options from configuration files
//          1a. Merging all the cnfiguration files into a single set of options
//          1b. Validating the format of the configuration options for use elsewhere
//      2. Storing the current state of the configuration options
//          2a. Providing a public interface for changing configuration options
//      3. Writing options to configuration files
class ConfigOptionsHandler
{
public:
    ConfigOptionsHandler(const string& configFilePathIn) : localConfigFilePath{ configFilePathIn } { configOptions = readAndMergeOptions(); }

    string                     getFilePath() const { return localConfigFilePath; }
    const ConfigOptionVector&  getOptions()        { return configOptions; }

    void                       setOption(const BaseConfigOption& optionIn) { configOptions.setOption(optionIn); }

    void saveOption(ConfigOptionPtr option, const ConfigFileLocation& configFileLocation)
    {
        switch (configFileLocation)
        {
        case ConfigFileLocation::eGlobal:
            throw FileException("cannot write to global configuration file\n", globalConfigFilePath);
            break;
        case ConfigFileLocation::eUser:
            writeOptionToFile(option, userConfigFilePath);
            break;
        case ConfigFileLocation::eLocal:
            writeOptionToFile(option, localConfigFilePath);
            break;
        }
    }

    void print() const
    {
        for (ConfigOptionPtr option : configOptions)
            option->print();
    }

private:
    // Parse each of the configuration files and merge them into a single vector of `ConfigOptionPtr`s
    // For now I naively prioritise the local configuration file, then user options, then global options
    ConfigOptionVector readAndMergeOptions()
    {
        ConfigOptionVector optionsLocal  = parseFile(localConfigFilePath);
        ConfigOptionVector optionsUser   = parseFile(userConfigFilePath);
        ConfigOptionVector optionsGlobal = parseFile(globalConfigFilePath);

        ConfigOptionVector optionsMerged{ optionsLocal };

        for (ConfigOptionPtr userOption : optionsUser) // Add any "user" options that aren't specified in the "local" options
        {
            string id{ userOption->getID() };
            if (optionsLocal.getOption(id) == nullptr)
                optionsMerged.push_back(optionsUser.getOption(id));
        }

        for (ConfigOptionPtr globalOption : optionsGlobal) // Add any "global" options that aren't specified in either the "local" or "user" options
        {
            string id{ globalOption->getID() };
            if (optionsLocal.getOption(id) == nullptr && optionsUser.getOption(id) == nullptr)
                optionsMerged.push_back(optionsGlobal.getOption(id));
        }

        return optionsMerged;
    }

    // Parse a single configuration file and return a vector of `ConfigOptionPtr`s
    ConfigOptionVector parseFile(const string& filePath)
    {
        ConfigOptionVector optionsParsed {};

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
                ss >> std::ws; // remove leading white space

                // Ignore blank lines and comment lines
                if (ss.rdbuf()->in_avail() == 0 || ss.peek() == '#')
                    continue;

                try
                {
                    ConfigOptionPtr newOption = makeOptionFromStrings(parseLine(ss));

                    // Ignore lines with duplicate options
                    if (optionsParsed.getOption(newOption->getID()) == nullptr) // nullptr is returned by getID() if that optionID doesn't exist in optionsParsed
                        optionsParsed.push_back( newOption );
                }
                catch (const InvalidOptionException& exception)
                {
                    std::cerr << exception.what();
                }
            }
        }
        catch (const FileException& exception)
        {
            std::cerr << exception.what();
        }

        return optionsParsed;
    }

    using id_val_pair = pair<string,string>;

    // Parse a single line of the configuration file and return a std::pair containing strings representing the
    // option's ID and value. Each line is assumed to be formatted as `id = val`, i.e. blank lines and comment
    // lines are not handled.
    id_val_pair parseLine(stringstream& ss)
    {
        string id;
        string val;

        char c;
        bool reachedEqualsSign = false;
        while (ss.get(c))
        {
            if (c == '#') // ignore comments
                break;
            if (c == '=') // switch from writing to `id` to `val` when of RHS of equals sign
                reachedEqualsSign = true;
            else if (!reachedEqualsSign)
                id.push_back(c);
            else
                val.push_back(c);
            ss >> std::ws; // always remove any following white space
        }

        return id_val_pair{ id, val };
    }

    // Write the configuration option stored in the `ConfigOptionPtr` `option` to the file `filePath`, which is can be
    // a new file, but is intended to be a preexisting configuration file. If the file already specifies a value
    // for the option in question it will be overwritten. If it includes more than one specification of the option,
    // the first will be overwritten and additonal ones will be removed.
    void writeOptionToFile(ConfigOptionPtr option, const string& filePath)
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
            ss >> std::ws; // Remove leading white space

            if ( ss.rdbuf()->in_avail() == 0 ||          // Copy blank lines unchanged to temp file
                 ss.peek() == '#' ||                     // Copy comment lines unchanged to temp file
                 parseLine(ss).first != option->getID()  // Copy "other" configuration options unchanged to temp file
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

    // Return a `ConfigOptionPtr` from an `id_val_pair`
    ConfigOptionPtr makeOptionFromStrings(const id_val_pair& inputPair)
    {
        string id  = inputPair.first;
        string val = inputPair.second;

        if (val == "true" || val == "false")
            return std::make_shared< ConfigOption<bool> >   (id, stringToBool(val));

        if (isInt(val))
            return std::make_shared< ConfigOption<int> >    (id, stringToInt(val));

        return std::make_shared< ConfigOption<string> > (id, val);
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
        if(!(ss >> myInt)) // stringstream extraction operator performs casts if it can returns false otherwise
            return false;
        return true;
    }

private:
    string localConfigFilePath;                                                          // Not known at compile time; initialised in the constructor
    string homeDirectory       { std::getenv("HOME") };                                  // $HOME environment variable, for accessing config file in the users home directory
    string userConfigFilePath  { homeDirectory + "/.config/videopreview" };
    string globalConfigFilePath{ "/etc/videopreviewconfig" };
    ConfigOptionVector configOptions;
};



/*----------------------------------------------------------------------------------------------------
    MARK: - Frame
   ----------------------------------------------------------------------------------------------------*/

// Data and functions relavant to a single frame of a video
class Frame
{
public:
    Frame(const Mat& dataIn, const int frameNumberIn) : data{ dataIn }, frameNumber{ frameNumberIn } {}

    int getFrameNumber() const { return frameNumber; }
    Mat getData()        const { return data; }

    // Export a bitmap (.bmp) of the frame.
    // The file will be saved in the directeory determined by `exportPath`.
    // Naming of the individual images is taken care of internally.
    void exportBitmap(string& exportPath)
    {
        string fileName = exportPath + "frame" + std::to_string(getFrameNumber()+1) + ".bmp"; // Add 1 to account for zero indexing
        cout << '\t' << fileName << '\n';
        cv::imwrite(fileName, getData());
    }

private:
    Mat data;
    int frameNumber;
};



/*----------------------------------------------------------------------------------------------------
    MARK: - Video
   ----------------------------------------------------------------------------------------------------*/

// Data and functions relevant to a single video file.
// Essentially a wrapper class for a cv::VideoCapture object
class Video
{
public:
    Video(const string& path) : vc{ path }
    {
        if (!vc.isOpened())
            throw FileException("file either could not be opened or is not an accepted format\n", path);
    }

    int  getFrameNumber()                 const { return vc.get(cv::CAP_PROP_POS_FRAMES); }
    int  numberOfFrames()                 const { return vc.get(cv::CAP_PROP_FRAME_COUNT); }
    void setFrameNumber(const int num)          { vc.set(cv::CAP_PROP_POS_FRAMES, num); }
    void writeCurrentFrame(Mat& frameOut)       { vc.read(frameOut); } // Overwrite `frameOut` with a `Mat` corresponding to the currently selected frame

    // Exports an MJPG to exportPath consisting of frames frameBegin to frameEnd-1. Used for exporting preview videos
    void exportVideo(const string& exportPath, const int frameBegin, const int frameEnd)
    {
        string fileName = exportPath + "frame" + std::to_string(frameBegin+1) + "-" + std::to_string(frameEnd) + ".avi"; // Add 1 to account for zero indexing
        cv::VideoWriter vw(fileName, cv::VideoWriter::fourcc('M','J','P','G'), getFPS(), getFrameSize());
        setFrameNumber(frameBegin);

        cout << '\t' << fileName << '\n';

        int frameNumber = frameBegin;
        while(frameNumber < frameEnd)
        {
            Mat frame;
            vc >> frame;
            if (frame.empty())
                break;
            vw.write(frame);
            ++frameNumber;
        }
    }

private:
    double   getFPS()       const { return vc.get(cv::CAP_PROP_FPS); }
    cv::Size getFrameSize() const { return cv::Size(vc.get(cv::CAP_PROP_FRAME_WIDTH),vc.get(cv::CAP_PROP_FRAME_HEIGHT)); }

private:
    cv::VideoCapture vc;
};



/*----------------------------------------------------------------------------------------------------
    MARK: - VideoPreview
   ----------------------------------------------------------------------------------------------------*/

// The main class associated with previewing a single video. `VideoPreview` has three core components:
//      1. `video`:          a `Video` object.            Deals with the core video file which is being previewed
//      2. `frames`:         a vector of `Frame` objects. Deals with the individual frames which are shown in the preview
//      3. `optionsHandler`: a `ConfigOptionsHandler`.    Deals with any options supplied by configuration files
class VideoPreview
{
public:
    VideoPreview(const string& videoPathIn) :
        videoPath{ videoPathIn },
        video{ videoPathIn },
        optionsHandler{ determineConfigPath() }
    {
        determineExportPath();
        determineConfigPath();
        updatePreview();
    }

    // Everything that needs to be run in order to update the actual video preview that the user sees
    // To be run on start-up and whenever configuration options are changed
    void updatePreview()
    {
        cout << "Updating preview\n";
        printConfig();

        // Update the preview
        if (configOptionHasBeenChanged("number_of_frames"))
        {
            makeFrames();
            exportFrames();

            // By default, if the "action_on_hover" option doesn't exist, don't export any preview videos
            // Further, if the "action_on_hover" option has the value "none", there is no need to export any preview videos
            if ( ConfigOptionPtr actionOnHover = getOption("action_on_hover"); actionOnHover && actionOnHover->getValue()->getString() != "none" )
                exportPreviewVideos();
        }

        currentPreviewConfigOptions = optionsHandler.getOptions();
    }

    ConfigOptionPtr getOption(const string& optionID)
    {
        return optionsHandler.getOptions().getOption(optionID);
    }

    void setOption(const BaseConfigOption& optionIn)
    {
        try
        {
            cout << "Setting configuration option \"" << optionIn.getID() << "\" to value \"" << optionIn.getValueAsString() << "\"\n";
            optionsHandler.setOption(optionIn);
        }
        catch (const FileException& exception)
        {
            std::cerr << exception.what();
            return;
        }
        updatePreview();
    }

    // Save a single current configuration option to a configuration file associated with this video
    // Keeps the formatting of the current config file, but overwirtes the option if it has been changed
    void saveOption(ConfigOptionPtr option, const ConfigFileLocation& configFileLocation)
    {
        try
        {
            optionsHandler.saveOption(option, configFileLocation);
        }
        catch (const FileException& exception)
        {
            std::cerr << "Could not save option: " << exception.what();
        }
    }

    // Save all the current configuration options to a configuration file associated with this video
    // Keeps the formatting of the current config file, but overwirtes any options that have been changed
    void saveOptions(const ConfigFileLocation& configFileLocation)
    {
        for (ConfigOptionPtr opt : optionsHandler.getOptions())
            saveOption(opt, configFileLocation);
    }
    
    // Export the current configuration options to an arbitrary file
    // The file cannot exist already
    void exportOptions(const string& configFileLocation)
    {
        std::cout << "Exporting configuration options to \"" << configFileLocation << "\"\n";
        try
        {
            if (fs::exists(configFileLocation))
                throw FileException("cannot export to a file that already exists\n", configFileLocation);
            
            std::ofstream outf{ configFileLocation };
            
            if (!outf)
                throw FileException("cannot open file for exporting\n", configFileLocation);
            
            for ( ConfigOptionPtr opt : optionsHandler.getOptions())
                outf << opt->getConfigFileString() << std::endl;
        }
        catch (const FileException& exception)
        {
            std::cerr << exception.what();
        }
    }

    void printConfig() const
    {
        cout << "Current configuration options:\n";
        optionsHandler.print();
    }

    ~VideoPreview()
    {
        fs::remove_all(exportPath.erase(exportPath.length())); // Delete the temporary directory assigned to this file (remove trailing slash from exportPath)
        if (fs::is_empty("media/.videopreview"))               // Delete .videopreview directory if it is empty (i.e. no other file is being previewed)
            fs::remove("media/.videopreview");
    }

private:
    // Parse `videopath` in order to determine the directory to which temporary files should be stored
    // This is saved to `exportPath`, and also returned from the function
    // Modified from https://stackoverflow.com/a/8520815
    string& determineExportPath()
    {
        string directoryPath;
        string fileName;

        // Extract the directory path and file name from videoPath
        // These are separated by the last slash in videoPath
        const size_t lastSlashIndex = videoPath.find_last_of("\\/"); // finds the last character that matches either \ or /
        if (string::npos != lastSlashIndex)
        {
            directoryPath = videoPath.substr(0,lastSlashIndex+1);
            fileName       = videoPath.substr(lastSlashIndex+1);
        }

        exportPath = directoryPath + ".videopreview/" + fileName + "/";

        return exportPath;
    }

    // Parse `videoPath` in order to determine the directory to which temporary files should be stored
    // This is saved to `configPath`, and also returned from the function (for use in the `optionsHandler` constructor)
    // Modified from https://stackoverflow.com/a/8520815
    string& determineConfigPath()
    {
        // Extract the directory path from videoPath
        // These are separated by the last slash in videoPath
        const size_t lastSlashIndex = videoPath.find_last_of("\\/"); // finds the last character that matches either \ or /
        if (string::npos != lastSlashIndex)
            configPath = videoPath.substr(0,lastSlashIndex+1);

        configPath += ".videopreviewconfig";

        return configPath;
    }

    // Read in appropriate configuration options and write over the `frames` vector
    void makeFrames()
    {
        int totalFrames = video.numberOfFrames();
        int NFrames{ optionsHandler.getOptions().getOption("number_of_frames")->getValue()->getInt().value() };
        int frameSampling = totalFrames/NFrames + 1;

        frames.clear();
        int i  = 0;
        for (int frameNumber = 0; frameNumber < totalFrames; frameNumber += frameSampling)
        {
            Mat currentFrameMat;
            video.setFrameNumber(frameNumber);
            video.writeCurrentFrame(currentFrameMat);
            frames.emplace_back(currentFrameMat, frameNumber);
            i++;
        }
    }

    // Exports all frames in the `frames` vector as bitmaps
    void exportFrames()
    {
        fs::create_directories(exportPath); // Make the export directory (and intermediate direcories) if it doesn't exist
        cout << "Exporting frame bitmaps\n";
        for (Frame& frame : frames)
            frame.exportBitmap(exportPath);
    }

    // Exports a "preview video" for each frame in the `frames` vector
    void exportPreviewVideos()
    {
        fs::create_directories(exportPath); // Make the export directory (and intermediate direcories) if it doesn't exist
        vector<int> frameNumbers;
        frameNumbers.reserve(frames.size()+1);

        for (Frame& frame : frames)
            frameNumbers.push_back(frame.getFrameNumber());
        frameNumbers.push_back(video.numberOfFrames());

        cout << "Exporting video previews\n";
        int index = 0;
        while ( index < frameNumbers.size()-1 )
        {
            video.exportVideo(exportPath, frameNumbers[index], frameNumbers[index+1]);
            ++index;
        }
    }

    // Determine if a given configuration option has been changed since the last time the preview was updated
    // Achieved by comparing the relevalnt `ConfigOptionPtr`s in `currentPreviewConfigOptions` and `optionsHandler`
    bool configOptionHasBeenChanged(const string& optionID)
    {
        // If the `ConfigOptionPtr` in `currentPreviewConfigOptions` is the same as the one stored internally in optionsHandler, then
        // the option cannot have been changed. However, if they are not the same then we can assume that the option has been
        // changed since the last time the preview was updated. Even if the optionID does not exist in either case, getOption()
        // will return nullptr, and this comparison still works
        return !( optionsHandler.getOptions().getOption(optionID) == currentPreviewConfigOptions.getOption(optionID) );
    }

private:
    string videoPath;                               // path to the video file
    string exportPath;                              // path the the directory for exporting temporary files to
    string configPath;                              // path to the local configuration file
    Video video;
    ConfigOptionsHandler optionsHandler;
    ConfigOptionVector currentPreviewConfigOptions; // The configuration options corresponding to the current preview (even if internal options have been changed)
    vector<Frame>        frames;                    // Vector of each Frame in the preview
};



/*----------------------------------------------------------------------------------------------------
    MARK: - main()
   ----------------------------------------------------------------------------------------------------*/

// Accepts one input argument: the name of the input video file
int main( int argc, char** argv )
{
    try
    {
        if (argc < 2)
            throw std::invalid_argument("Not enough arguments: expected a file path\n");

        if (argc > 2)
            std::cerr << "Ignoring additional arguments.\n";

        VideoPreview vidprev(argv[1]); // argv[1] is the input video file path
        ConfigOption<int> updatedOption{"number_of_frames",2};
        vidprev.setOption(updatedOption);
        vidprev.saveOption(vidprev.getOption("number_of_frames"), ConfigFileLocation::eLocal);
    }
    catch (const std::exception& exception)
    {
        std::cerr << exception.what();
        return 1;
    }

    return 0;
}
