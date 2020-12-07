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
class ConfigValue
{
public:
    // const functions allow `ConfigValue` objects (and derived classes) to be returned by const pointer
    virtual pair<bool,bool>   getBool()   const { return {false, false}; }
    virtual pair<bool,int>    getInt()    const { return {false, 0}; }
    virtual pair<bool,string> getString() const { return {false, ""}; }
    friend std::ostream& operator<<(std::ostream& os, ConfigValue& acv);
};

std::ostream& operator<<(std::ostream& os, ConfigValue& acv)
{
    if( acv.getBool().first )
        os << acv.getBool().second;
    else if( acv.getInt().first )
        os << acv.getInt().second;
    else if( acv.getString().first )
        os << acv.getString().second;
    return os;
}

class BoolConfigValue : public ConfigValue
{
public:
    BoolConfigValue(bool valIn) : value{ valIn } {}
    pair<bool,bool> getBool() const override { return {true, value}; }
private:
    bool value;
};

class IntConfigValue : public ConfigValue
{
public:
    IntConfigValue(int valIn) : value{ valIn } {}
    pair<bool,int> getInt() const override { return {true, value}; }
private:
    int value;
};

class StringConfigValue : public ConfigValue
{
public:
    StringConfigValue(string valIn) : value{ valIn } {}
    pair<bool,string> getString() const override { return {true, value}; }
private:
    string value;
};


// Abstract base class for storing a single configuration option. One of the the derived `ConfigOption<T>`
// classes is created for each option loaded from the configuration files for a given `VideoPreview` object.
class AbstractConfigOption
{
public:
    AbstractConfigOption(const string& id) : optionID{ id } {}
    virtual const ConfigValue* getValue() = 0; // const so that the returned pointer cannot be changed -> encapsulation
    string  getID()   { return optionID; }
    string  getName() { return nameMap.at(optionID); } // TODO: implement error checking (i.e. does optionID exist)
    void    print()
    {
        if ( getValue()->getBool().first )
            std::cout << getName() << ": " << getValue()->getBool().second << '\n';
        else if ( getValue()->getInt().first )
            std::cout << getName() << ": " << getValue()->getInt().second << '\n';
        else if ( getValue()->getString().first )
            std::cout << getName() << ": " << getValue()->getString().second << '\n';
    }
    virtual ~AbstractConfigOption() {};

    using NameMap = std::map<string,string>;

private:
    string optionID;
    const static NameMap nameMap;
};

// A map between `optionID` strings and a human-readable string explaining the corresponding option. Each
// `AbstractConfigOption` class has an `optionID`, which uniquely identifies which configuration option it
// corresponds to. However, when we want to print a list of the configuration options, we need a human-readable
// version of this. `AbstractConfigOption::nameMap` provides this mapping.
const AbstractConfigOption::NameMap AbstractConfigOption::nameMap = {
    {"number_of_frames", "Number of frames to show"},
    {"show_frame_info",  "Show indiviual frame information"},
    // Add further entries here as new configuration options are introduced
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
    virtual const ConfigValue* getValue() override { return optionValue; }
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
    virtual const ConfigValue* getValue() override { return optionValue; }
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
    virtual const ConfigValue* getValue() override { return optionValue; }
    virtual ~StringConfigOption() override { delete optionValue; }

private:
    StringConfigValue* optionValue;
};



using config_ptr = std::shared_ptr<AbstractConfigOption>; // Using `shared_ptr` allows `config_ptr`s to be safely returned by functions

// Parses a single configuration file and stores the various configuration options internally as a vector of pointers to ConfigOption classes
class ConfigFileParser
{
public:
    ConfigFileParser(const string& pathIn) : configFilePath{ pathIn }
    {
        parseFile();
    }

    void parseFile()
    {
        std::ifstream file{ configFilePath };
        if (!file)
        {
            std::cerr << configFilePath << " could not be opened\n";
            return; // leave `options` vector empty
        }

        options.clear();

        // TODO: Consider resersving memory for `options`. This could be related to the number of lines in the config file, although not all lines...
        // TODO: will necessarily correspond to a configuration option. Alternatively, there are probably never going to be a "large" number of...
        // TODO: config options, so this may not be too necessary

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

    // Return a `config_ptr` to the `ConfigOption<T>` in `options` corresponding to `optionID`.
    // In the case that no element in `options` corresponds to `optionID`, returns the null pointer.
    // It is up to the caller to verify if nullptr has been returned.
    config_ptr getOption(string optionID)
    {
        for ( auto& option : options)
        {
            if (option->getID() == optionID) // TODO: Implement error handling in the case that the option doesn't exist (or is it enough to return nullptr?)
                return option;
        }
        return nullptr;
    }

    void print()
    {
        for ( auto& option : options )
            option->print();
    }

private:
    string configFilePath;
    vector<config_ptr> options;

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
    // Returns a std::pair where the key is the name of the configuration option, and the val is the corresponding value
    // Assumes each line is formatted as `key = val`; all white space is ignored; does not handle comment lines
    config_ptr lineParser(std::stringstream& ss)
    {
        string key;
        string val;

        char c;
        bool reachedEqualsSign = false;
        while (ss.get(c))
        {
            if (c == '#') // ignore comments
                break;
            if (c == '=') // switch from writing to `key` to `val` when of RHS of equals sign
                reachedEqualsSign = true;
            else if (!reachedEqualsSign)
                key.push_back(c);
            else
                val.push_back(c);
            ss >> std::ws; // always remove any following white space
        }

        if (val == "true" || val == "false")
            return std::make_shared<BoolConfigOption>   (key, stringToBool(val));
        if (isInt(val))
            return std::make_shared<IntConfigOption>    (key, stringToInt(val));

        return std::make_shared<StringConfigOption> (key, val);
    }
};


// Container class for holding configuration options. Has three main purposes
//      1. Holding `ConfigFileParser` objects for each configuration file (local, user, global)
//      2. Combining the multiple configuration files into a single set of configuration options
//      3. Checking the validity of the options (i.e. are the options ids recognised?) and their data types
class ConfigOptionsContainer
{
public:
    ConfigOptionsContainer() :
        optionsLocal { "media/.videopreviewconfig" }, // TODO: don't hard code
        optionsUser  { homeDirectory + "/.videopreviewconfig" },
        optionsGlobal{ "/etc/videopreviewconfig" }
    {}


private:
    string homeDirectory{ std::getenv("HOME") }; // $HOME environment variable, for accessing config file in the users home directory
    ConfigFileParser optionsLocal;
    ConfigFileParser optionsUser;
    ConfigFileParser optionsGlobal;
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
        string fileName = exportPath + "/frame" + std::to_string(getFrameNumber()+1) + ".bmp"; // Add 1 to account for zero indexing
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
            std::cout << "Could not open video: " << path << '\n';
    }
    void setFrameNumber(int num) { vc.set(cv::CAP_PROP_POS_FRAMES, num); }
    int  getFrameNumber()        { return vc.get(cv::CAP_PROP_POS_FRAMES); }
    int  numberOfFrames()        { return vc.get(cv::CAP_PROP_FRAME_COUNT); }
    void writeCurrentFrame(Mat& frameOut) { vc.read(frameOut); } // Overwrite `frameOut` with a `Mat` corresponding to the currently selected frame

private:
    cv::VideoCapture vc;
};

// The main class associated with previewing a single video. `VideoPreview` has three core components:
//      1. `video`:   a `Video` object.            Deals with the core video file which is being previewed
//      2. `frames`:  a vector of `Frame` objects. Deals with the individual frames which are shown in the preview
//      3. `options`: a `ConfigFileParser`.        Deals with any options supplied by configuration files
class VideoPreview
{
public:
    VideoPreview(const string& videoPathIn, const string& configPathIn)
        : videoPath{ videoPathIn }, configPath{ configPathIn }, video{ videoPathIn }, options{ configPathIn }
    {
        makeFrames();
    }

    // Reads in appropriate configuration options and writes over the `frames` vector
    void makeFrames()
    {
        int totalFrames = video.numberOfFrames();
        int NFrames{ options.getOption("number_of_frames")->getValue()->getInt().second }; // TODO: proper error checking that this in an integer-type option
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
        // TODO: parse videoPath and create a specific directory (e.g. the file "sunrise.mp4" gets the directory ".videopreview/sunrise/")
        // TODO: Make the exportPath a member of VideoPreview objects
        system("mkdir media/.videopreview");
        string exportPath = "media/.videopreview";
        for (auto& frame : frames)
            frame->exportBitmap(exportPath);
    }

    void printConfig() { options.print(); }

private:
    string videoPath;
    string configPath;
    Video video;
    ConfigFileParser options;
    vector<std::unique_ptr<Frame> > frames;
};

int main( int argc, char** argv ) // takes one input argument: the name of the input video file
{
    string videoPath{ "media/sunrise.mp4" };
    string configPath{ "media/.videopreviewconfig" };

    VideoPreview vidprev(videoPath, configPath);
    vidprev.printConfig();
    vidprev.exportFrames();

    return 0;
}
