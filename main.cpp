#include <iostream>
#include <fstream>
#include <sstream>
#include <memory>
#include <vector>
#include <utility>    // for std::pair
#include <map>
#include <sys/stat.h> // for mkdir
#include <cstdlib>    // for std::getenv

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


using std::string;
using std::vector;
using std::pair;
using cv::Mat;


// Base class for storing a configuration value. Can store the value as either a bool, int, or string (and
// this can be expanded as needed). ConfigValue itself should not be used, but rather its derived classes.
// The "get" functions return a pair in which the first element holds a boolean which indicates if that given
// data type is being used, and the second element holds the value itself. it is up to the caller to verify
// that the data type is what they were expecting.
class AbstractConfigValue
{
public:
    // const functions allow `ConfigValue` objects (and derived classes) to be returned by const pointer
    virtual pair<bool,bool>   getBool()   const { return {false, false}; }
    virtual pair<bool,int>    getInt()    const { return {false, 0}; }
    virtual pair<bool,string> getString() const { return {false, ""}; }

protected:
    AbstractConfigValue() = default; // Declaring the constructor as protected to mark ConfigValue as "abstract"
};


// Specific derived classes of AbstractConfigValue. Each class corresponds to a separate data type to which the
// configuration option is stored as
class BoolConfigValue : public AbstractConfigValue
{
public:
    BoolConfigValue(bool valIn) : value{ valIn } {}
    pair<bool,bool> getBool() const override { return {true, value}; }
private:
    bool value;
};

class IntConfigValue : public AbstractConfigValue
{
public:
    IntConfigValue(int valIn) : value{ valIn } {}
    pair<bool,int> getInt() const override { return {true, value}; }
private:
    int value;
};

class StringConfigValue : public AbstractConfigValue
{
public:
    StringConfigValue(string valIn) : value{ valIn } {}
    pair<bool,string> getString() const override { return {true, value}; }
private:
    string value;
};



// Abstract base class for storing a single configuration option. One of the the derived `ConfigOptionX`
// classes is created for each option loaded from the configuration files for a given `VideoPreview` object.
class AbstractConfigOption
{
public:
    AbstractConfigOption(const string& id) : optionID{ id } {}
    virtual const AbstractConfigValue* getValue() = 0; // const so that the returned pointer cannot be changed -> encapsulation
    string  getID()   { return optionID; }
    string  getName() { return nameMap.at(optionID); }

    void print()
    {
        if ( getValue()->getBool().first )
            std::cout << getName() << ": " << getValue()->getBool().second << '\n';
        else if ( getValue()->getInt().first )
            std::cout << getName() << ": " << getValue()->getInt().second << '\n';
        else if ( getValue()->getString().first )
            std::cout << getName() << ": " << getValue()->getString().second << '\n';
    }

    bool validID()
    {
        bool valid = false;
        for (auto el : nameMap)
            if (el.first == optionID)
                valid = true;
        return valid;
    }

    bool validDataType()
    {
        if ( getID() == "number_of_frames" )
            return optionValueIsPositiveInteger();
        if ( getID() == "show_frame_info" )
            return optionValueIsBool();
        // Add further entries here as new configuration options are introduced
        // Be usre to also add an entry to AbstractConfigOption::nameMap
        return false; // covers case of invalid ID TODO: should probably replace with error checking
    }

    virtual ~AbstractConfigOption() {};

    using NameMap = std::map<string,string>;

private:
    string optionID;
    const static NameMap nameMap;

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

// A map between `optionID` strings and a human-readable string explaining the corresponding option. Each
// `AbstractConfigOption` class has an `optionID`, which uniquely identifies which configuration option it
// corresponds to. However, when we want to print a list of the configuration options, we need a human-readable
// version of this. `AbstractConfigOption::nameMap` provides this mapping.
// The `first` elements also provide a look up of all the valid option IDs that the program recognises.
const AbstractConfigOption::NameMap AbstractConfigOption::nameMap = {
    {"number_of_frames", "Number of frames to show"},
    {"show_frame_info",  "Show indiviual frame information"},
    // Add further entries here as new configuration options are introduced
    // Be sure to also add an entry to validateDataType()
};


// Specific derived classes of AbstractConfigOption. Each class corresponds to a separate data type to which the
// configuration option is stored as. // TODO: revist class templating here
class BoolConfigOption : public AbstractConfigOption
{
public:
    BoolConfigOption(const string& nameIn, const bool valIn) :
        AbstractConfigOption{ nameIn },
        optionValue{ new BoolConfigValue{ valIn } } {}

    void setValue(const bool valIn)
    {
        delete optionValue;
        optionValue = new BoolConfigValue{ valIn };
    }
    virtual const AbstractConfigValue* getValue() override { return optionValue; }
    virtual ~BoolConfigOption() override { delete optionValue;}

private:
    BoolConfigValue* optionValue;
};

class IntConfigOption : public AbstractConfigOption
{
public:
    IntConfigOption(const string& nameIn, const int valIn) :
        AbstractConfigOption{ nameIn },
        optionValue{ new IntConfigValue{ valIn } } {}

    void setValue(const int valIn)
    {
        delete optionValue;
        optionValue = new IntConfigValue{ valIn };

    }
    virtual const AbstractConfigValue* getValue() override { return optionValue; }
    virtual ~IntConfigOption() override { delete optionValue; }

private:
    IntConfigValue* optionValue;
};

class StringConfigOption : public AbstractConfigOption
{
public:
    StringConfigOption(const string& nameIn, const string valIn) :
        AbstractConfigOption{ nameIn },
        optionValue{ new StringConfigValue{ valIn } } {}

    void setValue(const string valIn)
    {
        delete optionValue;
        optionValue = new StringConfigValue{ valIn };
    }
    virtual const AbstractConfigValue* getValue() override { return optionValue; }
    virtual ~StringConfigOption() override { delete optionValue; }

private:
    StringConfigValue* optionValue;
};



using config_ptr = std::shared_ptr<AbstractConfigOption>; // Using `shared_ptr` allows `config_ptr`s to be safely returned by functions

// Container class for a std::vector of config_ptrs, with helper functions
class ConfigOptionsVector
{
public:
    ConfigOptionsVector(vector<config_ptr> optionsIn ) : options{ optionsIn } {}
    ConfigOptionsVector() {}

    using iterator = vector<config_ptr>::iterator;
    using const_iterator = vector<config_ptr>::const_iterator;

    // The following funcions allow ConfigOptionsVector to act appropriately in range-based iterators
    iterator begin(){ return options.begin(); }
    iterator end()  { return options.end();   }
    const_iterator begin() const { return options.begin(); }
    const_iterator end()   const { return options.end();   }

    // The following functions provide a similar public interface as a std::vector (while limiting direct access to `options`)
    void erase(iterator i) { options.erase(i); }
    void erase(iterator i1, iterator i2) { options.erase(i1, i2); }
    void push_back(config_ptr option)  { options.push_back(option); }
    void clear() { options.clear(); }

    // Return a `config_ptr` to the element in `options` corresponding to `optionID`.
    // In the case that no element in `options` corresponds to `optionID`, returns the null pointer.
    // It is up to the caller to verify if nullptr has been returned.
    config_ptr getOption(const string optionID) const
    {
        for ( auto& option : options)
            if (option->getID() == optionID)
                return option;
        return nullptr;
    }

private:
    vector<config_ptr> options;
};



// Parses a single configuration file and stores the various configuration options internally as a vector of `config_ptr`s.
// Has three main purposes:
//      1. Parse a configuration file to obtain a set of ConfigOptions
//      2. Validate that the ConfigOptions a) correspond to a valid optionID, and b) have a valid data type
//      3. Store the valid `ConfigOptions` in a `ConfigOptionsVector`
class ConfigFileParser
{
public:
    ConfigFileParser(const string& pathIn) : configFilePath{ pathIn }
    {
        parseFile();
        validateOptions();
    }

    // Return a const reference to the `options` vector
    const ConfigOptionsVector& getOptions()
    {
        return options;
    }

    string getFilePath() { return configFilePath; }

private:
    string configFilePath;
    ConfigOptionsVector options;

    bool stringToBool(const string& str)
    {
        return (str == "true"); // assumes the only inputs are "true" or "false"
    }

    int stringToInt(const string& str)
    {
        int myInt;
        std::stringstream ss{ str };
        ss >> myInt;
        return myInt;
    }

    bool isInt(const string& str)
    {
        int myInt;
        std::stringstream ss{ str };
        if(!(ss >> myInt)) // std::stringstream extraction operator performs casts if it can returns false otherwise
            return false;
        return true;
    }

    // Parses a single line of the configuration file and returns a pointer to a ConfigOption
    // Assumes each line is formatted as `id = val`; all white space is ignored; does not handle comment lines
    config_ptr lineParser(std::stringstream& ss)
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

        // TODO: bundle up this code for reuse
        if (val == "true" || val == "false")
            return std::make_shared<BoolConfigOption>   (id, stringToBool(val));
        if (isInt(val))
            return std::make_shared<IntConfigOption>    (id, stringToInt(val));

        return std::make_shared<StringConfigOption> (id, val);
    }

    // Parses an entire file and adds the resulting `config_ptr`s to the `options` vector
    void parseFile()
    {
        std::ifstream file{ configFilePath };
        if (!file)
        {
            std::cerr << configFilePath << " could not be opened\n";
            return; // leave `options` vector empty
        }

        options.clear();

        while (file)
        {
            string strInput;
            std::getline(file, strInput);
            std::stringstream ss{ strInput };
            ss >> std::ws; // remove leading white space
            if (ss.rdbuf()->in_avail() !=0 && ss.peek() != '#') // Ignore blank lines and comment lines
                options.push_back( lineParser(ss) );
        }
    }

    // Validate the option IDs and data types for each option stored in the `options` vector
    void validateOptions()
    {
        auto isValidID
        {
            [this](config_ptr option) // capture `this` for getFilePath()
            {
                if (!option->validID())
                {
                    std::cerr << "Ignoring unrecognized option \"" << option->getID() << "\" in configuration file \"" << getFilePath() << "\"\n";
                    return true;
                }
                return false;
            }
        };

        auto isValidDataType
        {
            [this](config_ptr option) // capture `this` for getFilePath()
            {
                if (!option->validDataType())
                {
                    std::cerr << "Ignoring option with invalid value \"" << option->getID() << "\" in configuration file \"" << getFilePath() << "\"\n";     // TODO: output the invalid value, and why it is invalid
                    return true;
                }
                return false;
            }
        };

        options.erase( std::remove_if(options.begin(), options.end(), isValidID),       options.end() );
        options.erase( std::remove_if(options.begin(), options.end(), isValidDataType), options.end() );
    }
};


// Container class for holding configuration options. Has two main purposes
//      1. Holding `ConfigFileParser` objects for each configuration file (local, user, global)
//      2. Combining the multiple configuration files into a single set of configuration options
class ConfigOptionsContainer
{
public:
    ConfigOptionsContainer(string configFilePath) :
        parserLocal { configFilePath },
        parserUser  { homeDirectory + "/.videopreviewconfig" },
        parserGlobal{ "/etc/videopreviewconfig" }
    {
        mergeOptions();
    }

    // Return a const reference to the `options` vector
    const ConfigOptionsVector& getOptions()
    {
        return options;
    }

    void print()
    {
        for ( auto& option : options )
            option->print();
    }


private:
    string homeDirectory{ std::getenv("HOME") }; // $HOME environment variable, for accessing config file in the users home directory
    ConfigFileParser parserLocal;
    ConfigFileParser parserUser;
    ConfigFileParser parserGlobal;
    ConfigOptionsVector options;

    // Merge the options vectors from each parser into a single vector
    // For now I naively prioritise any option in the local configuration file, then the user options, then global options
    // TODO: use more "complicated" inheritance priorities for the configuration options
    void mergeOptions()
    {
        options = parserLocal.getOptions();
        for (auto userOption : parserUser.getOptions()) // Add any "user" options that aren't specified in the "local" options
        {
            string id{ userOption->getID() };
            if (parserLocal.getOptions().getOption(id) == nullptr)
                options.push_back(parserUser.getOptions().getOption(id));
        }
        for (auto globalOption : parserGlobal.getOptions()) // Add any "global" options that aren't specified in either the "local" or "user" options
        {
            string id{ globalOption->getID() };
            if (parserLocal.getOptions().getOption(id) == nullptr && parserUser.getOptions().getOption(id) == nullptr)
                options.push_back(parserGlobal.getOptions().getOption(id));
        }
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

        std::cout << '\t' << fileName << '\n';

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
//      1. `video`:   a `Video` object.            Deals with the core video file which is being previewed
//      2. `frames`:  a vector of `Frame` objects. Deals with the individual frames which are shown in the preview
//      3. `options`: a `ConfigOptionsContainer`.  Deals with any options supplied by configuration files
class VideoPreview
{
public:
    VideoPreview(const string& videoPathIn)
        : videoPath{ videoPathIn }, video{ videoPathIn }, options{ determineConfigPath() }
    {
        makeFrames();
        determineExportPath();
        determineConfigPath();
    }

    // Reads in appropriate configuration options and writes over the `frames` vector
    void makeFrames()
    {
        int totalFrames = video.numberOfFrames();
        int NFrames{ options.getOptions().getOption("number_of_frames")->getValue()->getInt().second }; // TODO: proper error checking that this in an integer-type option
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

    // Parse `videopath` in order to determine the directory to which temporary files should be stored
    // Modified from https://stackoverflow.com/a/8520815
    string& determineExportPath()
    {
        string directoryPath;
        string fileName;

        // Extract the directory path and file name from videoPath
        // These are separated by the last slash in videoPath
        const size_t lastSlashIndex = videoPath.find_last_of("\\/"); // finds the last character that matches either \ or /
        if (std::string::npos != lastSlashIndex)
        {
            directoryPath = videoPath.substr(0,lastSlashIndex+1);
            fileName       = videoPath.substr(lastSlashIndex+1);
        }

        // Remove extension from fileName
        const size_t periodIndex = fileName.rfind('.');
        if (std::string::npos != periodIndex)
            fileName.erase(periodIndex);

        exportPath = directoryPath + ".videopreview/" + fileName + "/";

        return exportPath;
    }

    // Parse `videopath` in order to determine the directory to which temporary files should be stored
    // Returns exportPath, for use in the `options` constructor
    // Modified from https://stackoverflow.com/a/8520815
    string& determineConfigPath()
    {
        // Extract the directory path from videoPath
        // These are separated by the last slash in videoPath
        const size_t lastSlashIndex = videoPath.find_last_of("\\/"); // finds the last character that matches either \ or /
        if (std::string::npos != lastSlashIndex)
            configPath = videoPath.substr(0,lastSlashIndex+1);

        configPath += ".videopreviewconfig";

        return configPath;
    }

    // Exports all frames in the `frames` vector as bitmaps
    void exportFrames()
    {
        system(("mkdir -p " + exportPath).c_str());
        for (auto& frame : frames)
            frame->exportBitmap(exportPath);
    }

    // Exports a "preview video" for each frame in the `frames` vector
    void exportPreviewVideos()
    {
        system(("mkdir -p " + exportPath).c_str());
        vector<int> frameNumbers;
        frameNumbers.reserve(frames.size()+1);

        for (auto& frame : frames)
            frameNumbers.push_back(frame->getFrameNumber());
        frameNumbers.push_back(video.numberOfFrames());

        std::cout << "exporting videos\n";
        int index = 0;
        while ( index < frameNumbers.size()-1 )
        {
            video.exportVideo(exportPath, frameNumbers[index], frameNumbers[index+1]);
            ++index;
        }

    }

    void printConfig() { options.print(); }

    //TODO: Make a destructor that clears up the temporary directory
    //TODO: OR is it actually desired to leave the files there, for faster preview in the future (maybe make this an option)?

private:
    string videoPath;  // path to the video file
    string exportPath; // path the the directory for exporting temporary files to
    string configPath; // path to the configuration file
    Video video;
    ConfigOptionsContainer options;
    vector<std::unique_ptr<Frame> > frames;
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
        vidprev.printConfig();
        vidprev.exportFrames();
        vidprev.exportPreviewVideos();
    }
    catch (std::exception& exception)
    {
        std::cerr << exception.what();
        return 1;
    }

    return 0;
}
