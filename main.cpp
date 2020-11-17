#include <iostream>
#include <fstream>
#include <sstream>
#include <memory>
#include <vector>
#include <map>
#include <sys/stat.h> // for mkdir

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
using cv::Mat;

// Abstract base class for storing a single configuration option. One of the the derived `ConfigOption<T>`
// classes is created for each option loaded from the configuration files for a given `VideoPreview` object.
class AbstractConfigOption
{
public:
    AbstractConfigOption(const string& id) : optionID{ id } {}
    virtual int  getValue() = 0;
    string       getID()   { return optionID; }
    string       getName() { return nameMap.at(optionID); } // TODO: implement error checking (i.e. does optionID exist)
    void         print()   { std::cout << getName() << ": " << getValue() << '\n'; }

private:
    string optionID;
    const static std::map<string,string> nameMap;
};

// A map between `optionID` strings and a human-readable string explaining the corresponding option. Each
// `AbstractConfigOption` class has an `optionID`, which uniquely identifies which configuration option it
// corresponds to. However, when we want to print a list of the configuration options, we need a human-readable
// version of this. `AbstractConfigOption::nameMap` provides this mapping.
const std::map<string,string> AbstractConfigOption::nameMap = {
    {"number_of_frames", "Number of frames to show"},
    {"show_frame_info",  "Show indiviual frame information"},
    // Add further entries here as new configuration options are introduced
};

// Templated class for specific implementations of AbstractConfigOption
//      e.g. ConfigOption<bool> corresponds to a configuration option of data type bool
// Each class has an `optionValue` of templated type `T`. The member function `getValue()` returns this value as
// an int (or an enum). By making the return type consistent, `getValue()` could be made a virtual function.
template <class T>
class ConfigOption : public AbstractConfigOption
{
public:
    ConfigOption(const string& nameIn, const T valIn) : AbstractConfigOption{ nameIn }, optionValue{ valIn } { }
    void setValue(T valIn) { optionValue = valIn; }
    int  getValue(); // Defined using template specification below

private:
    T optionValue;
};

template<>
int ConfigOption<bool>::getValue() { return int(optionValue); }

template<>
int ConfigOption<int>::getValue()  { return optionValue; }

template<>
int ConfigOption<string>::getValue()
{
    // TODO: implement enum look up once I have a "string-type" confiuration option
    return -1; // Dummy value for now
}

using config_ptr = std::shared_ptr<AbstractConfigOption>; // Using `shared_ptr` allows `config_ptr`s to be safely returned by functions

// Parses a single configuration file and stores the various configuration options internally as a vector of pointers to ConfigOption classes
class ConfigParser
{
public:
    ConfigParser(const string& pathIn) : configFilePath{ pathIn }
    {
        // TODO: Break this code out into a function(s), which the constructor calls
        // TODO: Implement code that allows for more than one configuration file

        std::ifstream file{ configFilePath };
        if (!file)
            std::cerr << configFilePath << " could not be opened\n";

        // TODO: Consider resersving memory for `options`. This could be related to the number of lines in the config file, although not all lines...
        // TODO: will necessarily correspond to a configuration option. Alternatively, there are probably never going to be a "large" number of...
        // TODO: config options, so this may not be too necessary

        while (file)
        {
            string strInput;
            std::getline(file, strInput);
            if (strInput.length() != 0) // Ignore blank lines
                options.push_back( lineParser(strInput) );
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
    // Assumes each line is formatted as `LHS = RHS` (for now the spaces are mandatory)
    config_ptr lineParser(const string& strIn)
    {
        string key;
        string val;

        // TODO: Make this much more sophisticated. Whitespace should not matter. Comment lines should be ignored etc.
        std::stringstream ss{ strIn };
        ss >> key; // LHS of equals sign
        ss >> val; // The equals sign (will be overritten)
        ss >> val; // RHS of equals sign

        if (val == "true" || val == "false")
            return std::make_shared<ConfigOption<bool> > (key, stringToBool(val));
        if (isInt(val))
            return std::make_shared<ConfigOption<int> >  (key, stringToInt(val));

        return std::make_shared<ConfigOption<string> > (key, val);
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
//      3. `options`: a `ConfigParser`.            Deals with any options supplied by configuration files
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
        int NFrames{ options.getOption("number_of_frames")->getValue() };
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
    ConfigParser options;
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
