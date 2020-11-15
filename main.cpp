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

#include <opencv2/core/mat.hpp>  // for basic OpenCV structures (cv::Mat, Scalar)
#include <opencv2/imgcodecs.hpp> // for reading and writing
#include <opencv2/videoio.hpp>

#if defined(__has_warning)
#if __has_warning("-Wdocumentation")
#pragma GCC diagnostic pop
#endif
#endif

using std::string;
using std::vector;

// Abstract base class for storing a single configuration option
class AbstractConfigOption
{
private:
    string optionID;
    const static std::map<string,string> nameMap;

public:
    AbstractConfigOption(const string& id) : optionID{ id } {}
    string getID()   { return optionID; }
    string getName() { return nameMap.at(optionID); } // to do: do error checking
    void   print()   { std::cout << getName() << ": " << getValue() << '\n'; }
    virtual int  getValue() = 0;
    virtual ~AbstractConfigOption() {}
};

// A map between the optionIDs (as used in the configuration file) and the optionNames (as used when printing)
const std::map<string,string> AbstractConfigOption::nameMap = {
    {"number_of_frames", "Number of frames to show"},
    {"show_frame_info",  "Show indiviual frame information"}
};

// Templated class for specific implementations of AbstractConfigOption
// e.g. ConfigOption<bool> corresponds to a configuration option of data type bool
template <class T>
class ConfigOption : public AbstractConfigOption
{
private:
    T optionValue;

public:
    ConfigOption(const string& nameIn, const T valIn) : AbstractConfigOption{ nameIn }, optionValue{ valIn } { }
    void setValue(T valIn) { optionValue = valIn; }
    int  getValue(); // defined using template specification below
    virtual ~ConfigOption() {};
};

template<>
int ConfigOption<bool>::getValue() { return int(optionValue); }

template<>
int ConfigOption<int>::getValue()  { return optionValue; }

template<>
int ConfigOption<string>::getValue()
{
    // todo implement enum look up
    return -1; // dummy value for now
}

// Enumerates the data types that a configuration option may be
enum class OptionType
{
    undefined = -1,
    boolean, // 0
    integer, // 1
    string,  // 2
};

// Parses a single configuration file and stores the various configuration options internally as a vector of pointers to ConfigOption classes
class ConfigParser
{
private:
    string configFilePath;
    vector<std::shared_ptr<AbstractConfigOption> > options;

    bool isInt(const string& testString)
    {
        int myInt;
        std::stringstream testStringStream{ testString };
        if(!(testStringStream >> myInt)) // std::stringstream extraction operator performs casts if it can
            return false;
        return true;
    }

    // Determines the data type of the option value stored in the string `str`
    // Assumed to be a string by default if nothing else matches
    OptionType optionTypeIdentifier(const string& str)
    {
        if (str == "true" || str == "false")
            return OptionType::boolean;
        else if (isInt(str))
            return OptionType::integer;
        return OptionType::string;
    }

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

    // Parses a single line of the configuration file and returns a pointer to a ConfigOption
    // Returns a std::pair where the key is the name of the configuration option, and the val is the corresponding value
    // Assumes each line is formatted as `LHS = RHS`
    // For now the spaces are mandatory. Eventually I will handle e.g. `LHS=RHS`, and comment lines
    std::shared_ptr<AbstractConfigOption> lineParser(const string& strIn)
    {
        string key;
        string val;

        std::stringstream ss{ strIn };
        ss >> key; // LHS of equals sign
        ss >> val; // The equals sign (will be overritten)
        ss >> val; // RHS of equals sign

        switch(optionTypeIdentifier(val)) { // defaults to string when option type is undefined or string
        case OptionType::boolean:
            return std::make_shared<ConfigOption<bool> >   (key, stringToBool(val));
        case OptionType::integer:
            return std::make_shared<ConfigOption<int> >    (key, stringToInt(val));
        default:
            return std::make_shared<ConfigOption<string> > (key, val);
        }
    }

public:
    ConfigParser(const string& pathIn) : configFilePath{ pathIn }
    {
        std::ifstream file{ configFilePath };
        if (!file)
            std::cerr << configFilePath << " could not be opened\n";

        options.reserve(2); // Dummy value for now

        while (file)
        {
            string strInput;
            std::getline(file, strInput);
            if (strInput.length() != 0) // Ignore blank lines
                options.push_back( lineParser(strInput) );
        }
    }

    std::shared_ptr<AbstractConfigOption> getOption(string optionName) // Think about memory management involved in returning this pointer!!!
    {
        for ( auto el : options)
        {
            if (el->getName() == optionName) // todo implement error handling in the case that the option doesn't exist
                return el;
        }
        return options[0]; // This case should ever be reached. BAD. Ihave put it here to satisfy the compiler. ADDRESS!
    }

    void print()
    {
        for ( auto el : options )
            el->print();
    }
};

class Frame
{
private:
    cv::Mat data;
    int frameNumber;

public:
    Frame(cv::Mat& dataIn, int frameNumberIn)
        : data{ dataIn }, frameNumber{ frameNumberIn } {}
    int getFrameNumber() { return frameNumber; }
    cv::Mat getData() { return data; }

};

// Wrapper class for a cv::VideoCapture object, with convenient get / set functions
class Video
{
private:
    cv::VideoCapture vc;

public:
    Video(const string& path) : vc{ path }
    {
        if (!vc.isOpened())
            std::cout << "Could not open video: " << path << '\n';
    }
    void setFrameNumber(int num) { vc.set(cv::CAP_PROP_POS_FRAMES, num); }
    int  getFrameNumber()        { return vc.get(cv::CAP_PROP_POS_FRAMES); }
    int  numberOfFrames()        { return vc.get(cv::CAP_PROP_FRAME_COUNT); }
    void writeCurrentFrame(cv::Mat& frameOut) { vc.read(frameOut); }
};

class VideoPreview
{
private:
    string videoPath;
    string configPath;
    Video video;
    ConfigParser options;
    vector<std::unique_ptr<Frame> > frames;

public:
    VideoPreview(const string& videoPathIn, const string& configPathIn)
        : videoPath{ videoPathIn }, configPath{ configPathIn }, video{ videoPathIn }, options{ configPathIn }
    {
        makeFrames();
    }

    void makeFrames()
    {
        int totalFrames = video.numberOfFrames();
        int NFrames{ options.getOption("number_of_frames")->getValue() };
        int frameSampling = totalFrames/NFrames + 1;

        frames.clear();
        int i  = 0;
        for (int frameNumber = 0; frameNumber < totalFrames; frameNumber += frameSampling)
        {
            cv::Mat currentFrameMat;
            video.setFrameNumber(frameNumber);
            video.writeCurrentFrame(currentFrameMat);
            frames.push_back(std::make_unique<Frame>(currentFrameMat, frameNumber));
            i++;
        }
    }

    void exportFrames()
    {
        // todo parse videoPath and create a specific directory (e.g. the file "sunrise.mp4" gets the directory ".videopreview/sunrise/"
        system("mkdir media/.videopreview");

        for (auto& frame : frames)
        {
            string filename = "media/.videopreview/frame" + std::to_string(frame->getFrameNumber()+1) +".bmp";
            cv::imwrite(filename, frame->getData());
        }
    }

    void printConfig() { options.print(); }
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
