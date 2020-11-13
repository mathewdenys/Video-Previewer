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

// Parses a single configuration file and stores the various configuration options internally as a vector of pointers to ConfigOption classes
class ConfigParser
{
private:
    string configFilePath;
    std::vector<std::unique_ptr<AbstractConfigOption> > options;

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
    std::unique_ptr<AbstractConfigOption> lineParser(const string& strIn)
    {
        string key;
        string val;

        std::stringstream ss{ strIn };
        ss >> key; // LHS of equals sign
        ss >> val; // The equals sign (will be overritten)
        ss >> val; // RHS of equals sign

        switch(optionTypeIdentifier(val)) { // defaults to string when option type is undefined or string
        case OptionType::boolean:
            return std::make_unique<ConfigOption<bool> >   (key, stringToBool(val));
        case OptionType::integer:
            return std::make_unique<ConfigOption<int> >    (key, stringToInt(val));
        default:
            return std::make_unique<ConfigOption<string> > (key, val);
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
