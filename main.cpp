#include <iostream>
#include <fstream>
#include <sstream>
#include <memory>
#include <vector>
#include <map>

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

// Abstract base class for storing a single configuration option
class AbstractConfigOption
{
private:
    string optionName;

public:
    AbstractConfigOption(const string& nameIn) : optionName{ nameIn } {}
    string getName() { return optionName; }
    virtual void print() = 0;
    virtual ~AbstractConfigOption() {}
};

// Templated class for specific implementations of AbstractConfigOption
// e.g. ConfigOption<bool> corresponds to a configuration option of data type bool
template <class T>
class ConfigOption : public AbstractConfigOption
{
private:
    T optionValue;

public:
    ConfigOption(const string& nameIn, const T valIn) : AbstractConfigOption{ nameIn }, optionValue{ valIn } {}
    T getValue() { return optionValue; }
    virtual void print() { std::cout << getName() << ": " << getValue() << '\n'; }
    virtual ~ConfigOption() {};
};

// Enumerates the data types that a configuration option may be
enum class OptionType
{
    undefined = -1,
    boolean, // 0
    integer, // 1
    string,  // 2
};

class ConfigParser
{
private:
    string configFilePath;
    std::vector<std::unique_ptr<AbstractConfigOption> > options;

    // ConfigParser::lineParser() parses a single line of the configuration file
    // Returns a std::pair where the key is the name of the configuration option, and the val is the corresponding value
    // Assumes each line is formatted as `LHS = RHS`
    // For now the spaces are mandatory. Eventually I will handle e.g. `LHS=RHS`, and comment lines
    std::unique_ptr<AbstractConfigOption> lineParser(const string& strIn)
    {
        string key;
        string val;

        std::stringstream ss{ strIn };
        ss >> key; // LHS of equals sign
        ss >> val; // The equals sign (will be overritten)
        ss >> val; // RHS of equals sign

        if (optionTypeIdentifier(val) == OptionType::boolean)
            return std::make_unique<ConfigOption<bool> >(ConfigOption<bool>(key, stringToBool(val)));

        else if (optionTypeIdentifier(val) == OptionType::integer)
            return std::make_unique<ConfigOption<int> >(ConfigOption<int>(key, stringToInt(val)));

        return std::make_unique<ConfigOption<string> >(ConfigOption<string>(key, val)); // default to string
    }

    // test if the string `testString` corresponds to an integer
    // uses the std::stringstream extraction operator, which performs casts if it can
    bool isInt(const string& testString)
    {
        int myInt;
        std::stringstream testStringStream{ testString };
        if(!(testStringStream >> myInt))
            return false;
        return true;
    }

    bool stringToBool(const string& str)
    {
        if (str == "true")
            return true;
        return false;
    }

    int stringToInt(const string& str)
    {
        int myInt;
        std::stringstream ss{ str };
        ss >> myInt;
        return myInt;
    }

    OptionType optionTypeIdentifier(const string& val)
    {
        if (val == "true" || val == "false")
            return OptionType::boolean;
        else if (isInt(val))
            return OptionType::integer;
        return OptionType::string; // Assume to be a string by default (do better checking for validity here)
    }

public:
    ConfigParser(const std::string& pathIn) : configFilePath{ pathIn }
    {
        std::ifstream file{ configFilePath };
        if (!file)
            std::cerr << configFilePath << " could not be opened\n";

        options.reserve(2); // dummy value for now

        while (file)
        {
            std::string strInput;
            std::getline(file, strInput);
            if (strInput.length() != 0)     // Ignore blank lines
                options.push_back( lineParser(strInput) );
        }
    }
    
    //std::vector<std::unique_ptr<ConfigOption>> getOptions() { return options; }

    void print()
    {
        for ( auto& el : options )
            el->print();
    }
};

class VideoPreview
{
private:
    cv::VideoCapture video;
    std::vector<cv::Mat>      frames;
    std::vector<std::unique_ptr<AbstractConfigOption> > options;

public:
    VideoPreview(const string& videoPathIn, const string& configPathIn)
    {
        // import the video file
        video = cv::VideoCapture(videoPathIn);
        if (!video.isOpened())
            std::cout << "Could not open video: " << videoPathIn << '\n';

        // load the configuration file and make `options`
        options.reserve(2); // temporary value for now
        ConfigParser parser(configPathIn);
        parser.print();

        // create the frames
        // ...

    }
};





















int main( int argc, char** argv ) // takes one input argument: the name of the input video file
{
    std::string videoPath{ "media/sunrise.mp4" };
    std::string configPath{ "media/.videopreviewconfig" };
    
    VideoPreview vid(videoPath, configPath);
    
    /*ConfigOption o1{ "optionOne" };
    std::cout << o1.getName() << std::endl;
    ConfigOption o2{ "optionTwo" };
    std::cout << o2.getName() << std::endl;
    ConfigOptionBool o3{ "optionBool", true };
    std::cout << o3.getName() << std::endl;*/
    
    
    return 0;
}
