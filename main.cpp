#include <iostream>
#include <fstream>
#include <sstream>
#include <memory>
#include <vector>
#include <map>
#include <utility>    // for std::pair
#include <cstdlib>    // for std::getenv
#include <filesystem> // for std::filesystem::create_directories, remove, rename, is_empty, etc. [requires C++17]

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


// Abstract base class for storing a configuration value. Can store the value as either a bool, int, or string
// The "get" functions return a pair in which the first element holds a boolean which indicates if that given
// data type is being used, and the second element holds the value itself. It is up to the caller to verify
// that the data type is what they were expecting.
class AbstractConfigValue
{
public:
    // const functions allow `AbstractConfigValue` objects to be returned by const pointer
    virtual pair<bool,bool>   getBool()   const = 0;
    virtual pair<bool,int>    getInt()    const = 0;
    virtual pair<bool,string> getString() const = 0;
    virtual ~AbstractConfigValue() = default;
};


template <class T>
class ConfigValue : public AbstractConfigValue
{
public:
    ConfigValue(T valIn) : value{ valIn } {}
    pair<bool,bool>   getBool()   const;
    pair<bool,int>    getInt()    const;
    pair<bool,string> getString() const;

private:
    T value;
};

// Partial template specialization
template<class T> pair<bool,bool> ConfigValue<T>::getBool()    const { return {false, false}; }
template<>        pair<bool,bool> ConfigValue<bool>::getBool() const { return {true,  value}; }

template<class T> pair<bool,int> ConfigValue<T>::getInt()   const { return {false, 0}; }
template<>        pair<bool,int> ConfigValue<int>::getInt() const { return {true,  value}; }

template<class T> pair<bool,string> ConfigValue<T>::getString()      const { return {false, ""}; }
template<>        pair<bool,string> ConfigValue<string>::getString() const { return {true,  value}; }


// Enum class that enumerates the valid data types that a RecognisedConfigOption may have
enum class DataType
{
    BOOLEAN,
    POSITIVE_INTEGER,
};


// Class for storing information about configuration options that the program recognises
class RecognisedConfigOption
{
public:
    RecognisedConfigOption(string idIn, string descriptionIn, DataType dataTypeIn) :
        id          { idIn },
        description { descriptionIn },
        dataType    { dataTypeIn }
    {}

    string&   getID()          { return id; }
    string&   getDescription() { return description; }
    DataType& getDataType()    { return dataType; }

private:
    string id;
    string description;   // Human-readable description
    DataType dataType;
};

using config_value_ptr = std::shared_ptr<AbstractConfigValue>; // Using `shared_ptr` allows `config_value_ptr`s to be safely returned by functions



// Abstract base class for storing a single configuration option. One of its derived classes is created
// for each option loaded from the configuration files for a given `VideoPreview` object.
class AbstractConfigOption
{
public:
    AbstractConfigOption(const string& id) : optionID{ id } {}
    //virtual const AbstractConfigValue* getValue() = 0; // const so that the returned pointer cannot be changed -> encapsulation
    virtual const config_value_ptr getValue() = 0; // const so that the returned pointer cannot be changed -> encapsulation
    virtual string getValueAsString() = 0;

    string  getID()
    {
        return optionID;
    }

    string  getName()
    {
        for (auto el : recognisedConfigOptions)
            if (el.getID() == optionID)
                return el.getDescription();
        return "[[Unrecognised optionID has no description]]"; // If the ID has been validated, this should never to reached. Kept in for debuging purposes
    }

    // Retrun a string of the form "id = val", for writing the configuration option to a file
    string configFileString()
    {
        return getID() + " = " + getValueAsString();
    }

    void print()
    {
        cout << '\t' << getName() << ": " << getValueAsString() << '\n';
    }

    bool validID()
    {
        for (auto el : recognisedConfigOptions)
            if (el.getID() == optionID)
                return true;
        return false;
    }

    bool validDataType()
    {
        for (auto el : recognisedConfigOptions)
            if (el.getID() == optionID)
            {
                if (el.getDataType() == DataType::BOOLEAN)
                    return optionValueIsBool();
                if (el.getDataType() == DataType::POSITIVE_INTEGER)
                    return optionValueIsPositiveInteger();
            }
        return false; // If the ID has been validated, this should never to reached.
    }

    virtual ~AbstractConfigOption() {};

private:
    string optionID;
    const static array<RecognisedConfigOption,2> recognisedConfigOptions; // Initialised out of class

    bool optionValueIsBool()
    {
        return getValue()->getBool().first;
    }

    bool optionValueIsPositiveInteger()
    {
        pair<bool,int> ovalue = getValue()->getInt();
        if ( ovalue.first && ovalue.second > 0 )
            return true;
        return false;
    }
};

// An array that contains every RecognisedConfigOption that the program "understands"
//      Add further entries here as new configuration options are introduced
//      The size argument in the declariation of recognisedConfigOptions will need to be updated
//      Additional entries may need to be added to the DataType enum class. In this case a function should
//      be added to AbstrictConfigOption() to validate this data type (like optionValueIsBool()), and a
//      corresponding if statement to validDataType()
const array<RecognisedConfigOption,2> AbstractConfigOption::recognisedConfigOptions {
    RecognisedConfigOption("number_of_frames", "Number of frames to show",          DataType::POSITIVE_INTEGER),
    RecognisedConfigOption("show_frame_info",  "Show individual frame information", DataType::BOOLEAN),
};



// Specific derived classes of AbstractConfigOption. Each class corresponds to a separate data type to which the
// configuration option is stored as.
template<class T>
class ConfigOption : public AbstractConfigOption
{
public:
    ConfigOption(const string& nameIn, const T valIn) :
        AbstractConfigOption{ nameIn },
        optionValue{ std::make_shared< ConfigValue<T> >(valIn) }
    {}

    void setValue(const T valIn) { optionValue = std::make_shared< ConfigValue<T> >(valIn); }
    const config_value_ptr getValue() override { return optionValue; }
    string getValueAsString() override;

private:
    config_value_ptr optionValue;
};

template<> string ConfigOption<bool>::getValueAsString()   { return (optionValue->getBool().second ? "true" : "false"); }
template<> string ConfigOption<int>::getValueAsString()    { return std::to_string(optionValue->getInt().second); }
template<> string ConfigOption<string>::getValueAsString() { return optionValue->getString().second; }



using config_option_ptr = std::shared_ptr<AbstractConfigOption>; // Using `shared_ptr` allows `config_option_ptr`s to be safely returned by functions

// Container class for a vector of config_ptrs, with helper functions
class ConfigOptionsVector
{
public:
    ConfigOptionsVector() {} // Default constructor
    ConfigOptionsVector(vector<config_option_ptr> optionsIn ) : options{ optionsIn } {}

    using iterator       = vector<config_option_ptr>::iterator;
    using const_iterator = vector<config_option_ptr>::const_iterator;

    // The following funcions allow ConfigOptionsVector to act appropriately in range-based iterators
    iterator begin(){ return options.begin(); }
    iterator end()  { return options.end();   }
    const_iterator begin() const { return options.begin(); }
    const_iterator end()   const { return options.end();   }

    // The following functions provide a similar public interface as a vector (while limiting direct access to `options`)
    void erase(iterator i) { options.erase(i); }
    void erase(iterator i1, iterator i2) { options.erase(i1, i2); }
    void push_back(config_option_ptr option)  { options.push_back(option); }
    void clear() { options.clear(); }

    // Return a `config_option_ptr` to the element in `options` corresponding to `optionID`.
    // In the case that no element in `options` corresponds to `optionID`, returns the null pointer.
    // It is up to the caller to verify if nullptr has been returned.
    config_option_ptr getOption(const string optionID) const
    {
        for ( auto& option : options)
            if (option->getID() == optionID)
                return option;
        return nullptr;
    }

    // Add a new configuration option to the `options` vector.
    // If the option already exists in `options`, the current value is removed first, to avoid conflicts
    void setOption(AbstractConfigOption& optionIn)
    {
        if (!optionIn.validID())
            throw std::runtime_error("Could not set option due to invalid ID \"" + optionIn.getID() + "\".\n");

        if (!optionIn.validDataType())
        {
            string value = optionIn.getValueAsString();
            throw std::runtime_error("Could not set option due to invalid value: \"" + optionIn.getID() + "\" cannot have the value \"" + value + "\".\n");
        }

        auto IDexists
        {
            [&optionIn](config_option_ptr option)
            {
                return option->getID() == optionIn.getID();
            }
        };

        options.erase( std::remove_if(options.begin(), options.end(), IDexists), options.end() );

        if (optionIn.getValue()->getBool().first )
            options.push_back( std::make_shared< ConfigOption<bool> >(optionIn.getID(), optionIn.getValue()->getBool().second));

        if (optionIn.getValue()->getInt().first )
            options.push_back( std::make_shared< ConfigOption<int> >(optionIn.getID(), optionIn.getValue()->getInt().second));

        if (optionIn.getValue()->getString().first )
            options.push_back( std::make_shared< ConfigOption<string> >(optionIn.getID(), optionIn.getValue()->getString().second));

    }

private:
    vector<config_option_ptr> options;
};



// Enum class that enumerates the different configuration files
enum class ConfigFileLocation
{
    LOCAL,
    USER,
    GLOBAL,
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
    ConfigOptionsHandler(string configFilePathIn) :
        localConfigFilePath{ configFilePathIn }
    {
        configOptions = readAndMergeOptions();
    }

    string getFilePath()
    {
        return localConfigFilePath;
    }

    const ConfigOptionsVector&  getOptions()
    {
        return configOptions;
    }

    void setOption(AbstractConfigOption& optionIn)
    {
        configOptions.setOption(optionIn);
    }

    void saveOption(config_option_ptr option, const ConfigFileLocation& configFileLocation)
    {
        if (!option->validID() || !option->validDataType())
            throw std::runtime_error("Invalid option");

        switch (configFileLocation) {
        case ConfigFileLocation::GLOBAL:
            throw std::runtime_error("Cannot write to global configuration file\n");
            break;
        case ConfigFileLocation::USER:
            writeOptionToFile(option, userConfigFilePath);
            break;
        case ConfigFileLocation::LOCAL:
            writeOptionToFile(option, localConfigFilePath);
            break;
        }
    }

    void print()
    {
        for ( auto& option : configOptions )
            option->print();
    }

private:
    string homeDirectory{ std::getenv("HOME") }; // $HOME environment variable, for accessing config file in the users home directory
    string localConfigFilePath; // Not known at compile time; initialised in the constructor
    string userConfigFilePath{ homeDirectory + "/.config/videopreview" };
    string globalConfigFilePath{ "/etc/videopreviewconfig" };
    ConfigOptionsVector configOptions;

    // Parse each of the configuration files and merge them into a single vector of `config_option_ptr`s
    // For now I naively prioritise the local configuration file, then user options, then global options
    // TODO: use more "complicated" inheritance priorities for the configuration options
    ConfigOptionsVector readAndMergeOptions()
    {
        ConfigOptionsVector optionsLocal  = parseAndValidateFile(localConfigFilePath);
        ConfigOptionsVector optionsUser   = parseAndValidateFile(userConfigFilePath);
        ConfigOptionsVector optionsGlobal = parseAndValidateFile(globalConfigFilePath);

        ConfigOptionsVector optionsMerged{ optionsLocal };

        for (auto userOption : optionsUser) // Add any "user" options that aren't specified in the "local" options
        {
            string id{ userOption->getID() };
            if (optionsLocal.getOption(id) == nullptr)
                optionsMerged.push_back(optionsUser.getOption(id));
        }

        for (auto globalOption : optionsGlobal) // Add any "global" options that aren't specified in either the "local" or "user" options
        {
            string id{ globalOption->getID() };
            if (optionsLocal.getOption(id) == nullptr && optionsUser.getOption(id) == nullptr)
                optionsMerged.push_back(optionsGlobal.getOption(id));
        }

        return optionsMerged;
    }

    ConfigOptionsVector parseAndValidateFile(const string& filePath)
    {
        ConfigOptionsVector optionsParsed;
        try
        {
            optionsParsed = parseFile(filePath);
        }
        catch (std::runtime_error& exception)
        {
            std::cerr << "Could not parse file \"" + filePath + "\" : " << exception.what();
        }
        removeInvalidOptions(optionsParsed);
        return optionsParsed;
    }

    // Parse a single configuration file and return a vector of `config_option_ptr`s
    ConfigOptionsVector parseFile(const string& filePath)
    {

        cout << "Parsing \"" << filePath << "\"\n";
        std::ifstream file{ filePath };
        if (!file)
            throw std::runtime_error("File \"" + filePath + "\" could not be opened.\n");

        ConfigOptionsVector optionsParsed;

        string line;
        while (std::getline(file, line))
        {
            stringstream ss{ line };
            ss >> std::ws; // remove leading white space

            // Ignore blank lines and comment lines
            if (ss.rdbuf()->in_avail() == 0 || ss.peek() == '#')
                continue;

            config_option_ptr newOption = makeOptionFromStrings(parseLine(ss));

            // Ignore lines with duplicate options
            if (optionsParsed.getOption(newOption->getID()) == nullptr) // nullptr is returned by getID() if that optionID doesn't exist in optionsParsed
                optionsParsed.push_back( newOption );
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

    // Write the configuration option stored in the `config_option_ptr` `option` to the file `filePath`, which is can be
    // a new file, but is intended to be a preexisting configuration file. If the file already specifies a value
    // for the option in question it will be overwritten. If it includes more than one specification of the option,
    // the first will be overwritten and additonal ones will be removed.
    void writeOptionToFile(config_option_ptr option, const string& filePath)
    {
        // Open the file for reading any preexisting content
        std::ifstream file{ filePath };
        if (!file)
            throw std::runtime_error("File \"" + filePath + "\" could not be opened.\n");

        // Open a temporary file for writing to
        string tempFilePath{ filePath + "temp" };
        std::ofstream tempFile{ tempFilePath };
        if (!tempFile)
            throw std::runtime_error("Temporary file \"" + filePath + "\" could not be opened.\n");

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
                tempFile << option->configFileString() << std::endl;
                optionReplaced = true;
            }
        }

        // Move contents of tempFilePath to filePath and delete tempFilePath
        fs::remove(filePath);
        fs::rename(tempFilePath, filePath);
    }

    // Return a `config_option_ptr` from an `id_val_pair`
    config_option_ptr makeOptionFromStrings(id_val_pair inputPair)
    {
        string id  = inputPair.first;
        string val = inputPair.second;

        if (val == "true" || val == "false")
            return std::make_shared< ConfigOption<bool> >   (id, stringToBool(val));

        if (isInt(val))
            return std::make_shared< ConfigOption<int> >    (id, stringToInt(val));

        return std::make_shared< ConfigOption<string> > (id, val);
    }

    // Remove invalid options from a given vector of `config_option_ptr`s
    // An invalid option is one which either
    //      a) has an unrecognised `optionID`, or
    //      b) has a `value` with an invalid value of of invalid data type for the given `optionID`
    void removeInvalidOptions(ConfigOptionsVector& options)
    {
        auto isValidID
        {
            [this](config_option_ptr option) // capture `this` for getFilePath()
            {
                if (!option->validID())
                {
                    std::cerr << "Ignoring unrecognized option \"" << option->getID() << "\"\n";
                    return true;
                }
                return false;
            }
        };

        auto isValidDataType
        {
            [this](config_option_ptr option) // capture `this` for getFilePath()
            {
                if (!option->validDataType())
                {
                    std::cerr << "Ignoring option with invalid value \"" << option->getID() << "\"\n";
                    return true;
                }
                return false;
            }
        };

        options.erase( std::remove_if(options.begin(), options.end(), isValidID),       options.end() );
        options.erase( std::remove_if(options.begin(), options.end(), isValidDataType), options.end() );
    }

    bool stringToBool(const string& str)
    {
        return (str == "true"); // assumes the only inputs are "true" or "false"
    }

    int stringToInt(const string& str)
    {
        int myInt;
        stringstream ss{ str };
        ss >> myInt;
        return myInt;
    }

    bool isInt(const string& str)
    {
        int myInt;
        stringstream ss{ str };
        if(!(ss >> myInt)) // stringstream extraction operator performs casts if it can returns false otherwise
            return false;
        return true;
    }
};



// Data and functions relavant to a single frame of a video
class Frame
{
public:
    Frame(Mat& dataIn, int frameNumberIn) : data{ dataIn }, frameNumber{ frameNumberIn } {}
    int getFrameNumber() { return frameNumber; }
    Mat getData()        { return data; }

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



// Data and functions relevant to a single video file.
// Essentially a wrapper class for a cv::VideoCapture object
class Video
{
public:
    Video(const string& path) : vc{ path }
    {
        if (!vc.isOpened())
            throw std::invalid_argument("File " + path + " either could not be opened or is not a valid video file. Aborting.\n");
    }
    void setFrameNumber(int num) { vc.set(cv::CAP_PROP_POS_FRAMES, num); }
    int  getFrameNumber()        { return vc.get(cv::CAP_PROP_POS_FRAMES); }
    int  numberOfFrames()        { return vc.get(cv::CAP_PROP_FRAME_COUNT); }
    void writeCurrentFrame(Mat& frameOut) { vc.read(frameOut); } // Overwrite `frameOut` with a `Mat` corresponding to the currently selected frame

    // Exports an MJPG to exportPath consisting of frames frameBegin to frameEnd-1. Used for exporting preview videos
    void exportVideo(string exportPath, int frameBegin, int frameEnd)
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
    cv::VideoCapture vc;

    double getFPS() { return vc.get(cv::CAP_PROP_FPS); }

    cv::Size getFrameSize()
    {
        int width  = vc.get(cv::CAP_PROP_FRAME_WIDTH);
        int height = vc.get(cv::CAP_PROP_FRAME_HEIGHT);
        return cv::Size(width,height);
    }
};



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
        if (hasConfigOptionBeenChanged("number_of_frames"))
        {
            makeFrames();
            exportFrames();
            exportPreviewVideos();
        }

        currentPreviewConfigOptions = optionsHandler.getOptions();
    }

    config_option_ptr getOption(const string& optionID)
    {
        return optionsHandler.getOptions().getOption(optionID);
    }

    void setOption(AbstractConfigOption& optionIn)
    {
        try
        {
            cout << "Setting configuration option \"" << optionIn.getID() << "\" to value \"" << optionIn.getValueAsString() << '\n';
            optionsHandler.setOption(optionIn);
        }
        catch ( std::runtime_error& exception )
        {
            std::cerr << exception.what();
            return;
        }
        updatePreview();
    }

    void saveOption(config_option_ptr option, const ConfigFileLocation& configFileLocation)
    {
        try
        {
            optionsHandler.saveOption(option, configFileLocation);
        }
        catch (std::runtime_error& exception)
        {
            std::cerr << "Could not save option: " << exception.what();
        }
    }

    void printConfig()
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
    string videoPath;  // path to the video file
    string exportPath; // path the the directory for exporting temporary files to
    string configPath; // path to the local configuration file
    Video video;
    ConfigOptionsHandler optionsHandler;
    ConfigOptionsVector currentPreviewConfigOptions;
    vector<std::unique_ptr<Frame> > frames;

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
        int NFrames{ optionsHandler.getOptions().getOption("number_of_frames")->getValue()->getInt().second };
        int frameSampling = totalFrames/NFrames + 1;

        frames.clear();
        int i  = 0;
        for (int frameNumber = 0; frameNumber < totalFrames; frameNumber += frameSampling)
        {
            Mat currentFrameMat;
            video.setFrameNumber(frameNumber);
            video.writeCurrentFrame(currentFrameMat);
            frames.push_back(std::make_unique<Frame>(currentFrameMat, frameNumber));
            i++;
        }
    }

    // Exports all frames in the `frames` vector as bitmaps
    void exportFrames()
    {
        fs::create_directories(exportPath); // Make the export directory (and intermediate direcories) if it doesn't exist
        cout << "Exporting frame bitmaps\n";
        for (auto& frame : frames)
            frame->exportBitmap(exportPath);
    }

    // Exports a "preview video" for each frame in the `frames` vector
    void exportPreviewVideos()
    {
        fs::create_directories(exportPath); // Make the export directory (and intermediate direcories) if it doesn't exist
        vector<int> frameNumbers;
        frameNumbers.reserve(frames.size()+1);

        for (auto& frame : frames)
            frameNumbers.push_back(frame->getFrameNumber());
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
    // Achieved by comparing the relevalnt `config_option_ptr`s in `currentPreviewConfigOptions` and `optionsHandler`
    bool hasConfigOptionBeenChanged(string optionID)
    {
        // If the `config_option_ptr` in `currentPreviewConfigOptions` is the same as the one stored internally in optionsHandler, then
        // the option cannot have been changed. However, if they are not the same then we can assume that the option has been
        // changed since the last time the preview was updated. Even if the optionID does not exist in either case, getOption()
        // will return nullptr, and this comparison still works
        return !( optionsHandler.getOptions().getOption(optionID) == currentPreviewConfigOptions.getOption(optionID) );
    }
};


// Accepts one input argument: the name of the input video file
int main( int argc, char** argv )
{
    try
    {
        if (argc < 2)
            throw std::invalid_argument("Not enough arguments: expected a file path. Aborting.\n");

        if (argc > 2)
            std::cerr << "Ignoring additional arguments.\n";

        VideoPreview vidprev(argv[1]); // argv[1] is the input video file path
        ConfigOption<int> updatedOption{"number_of_frames",2};
        vidprev.setOption(updatedOption);
        vidprev.saveOption(vidprev.getOption("number_of_frames"), ConfigFileLocation::LOCAL);
    }
    catch (std::exception& exception)
    {
        std::cerr << exception.what();
        return 1;
    }

    return 0;
}
