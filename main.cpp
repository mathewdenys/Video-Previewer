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

enum class OptionType
{
    undefined = -1,
    boolean, // 0
    integer, // 1
    string,  // 2
};

class ConfigOption
{
private:
    std::string optionName;

public:
    ConfigOption(const std::string& nameIn) : optionName{ nameIn } {}
    std::string getName() { return optionName; }
    virtual void print()
    {
        std::cout << getName() << ": Undefined option with no value\n";
    }
};

class ConfigOptionBool : public ConfigOption
{
private:
    bool value;

public:
    ConfigOptionBool(const std::string& nameIn, const bool valIn)
        : ConfigOption{ nameIn }, value{ valIn } {}
    bool getValue() { return value; }
    virtual void print()
    {
        std::cout << getName() << ": Boolean option with value " << getValue() << '\n';
    }
};

class ConfigOptionInt : public ConfigOption
{
private:
    int value;

public:
    ConfigOptionInt(const std::string& nameIn, const int valIn)
        : ConfigOption{ nameIn }, value{ valIn } {}
    int getValue() { return value; }
    virtual void print()
    {
        std::cout << getName() << ": Integer option with value " << getValue() << '\n';
    }
};

class ConfigOptionString : public ConfigOption
{
private:
    std::string value;

public:
    ConfigOptionString(const std::string& nameIn, const std::string& valIn)
        : ConfigOption{ nameIn }, value{ valIn } {}
    std::string getValue() { return value; }
    void print()
    {
        std::cout << getName() << ": String option with value " << getValue() << '\n';
    }
};












class ConfigParser
{
private:
    std::string configFilePath;
    std::vector<std::unique_ptr<ConfigOption>> options;

    // ConfigParser::lineParser() parses a single line of the configuration file
    // Returns a std::pair where the key is the name of the configuration option, and the val is the corresponding value
    // Assumes each line is formatted as `LHS = RHS`
    // For now the spaces are mandatory. Eventually I will handle e.g. `LHS=RHS`, and comment lines
    std::unique_ptr<ConfigOption> lineParser(const std::string& strIn)
    {
        std::string key;
        std::string val;

        std::stringstream ss{ strIn };
        ss >> key; // LHS of equals sign
        ss >> val; // The equals sign (will be overritten)
        ss >> val; // RHS of equals sign
        
        if (optionTypeIdentifier(val) == OptionType::boolean)
            return std::make_unique<ConfigOptionBool>(ConfigOptionBool(key, stringToBool(val)));
        
        else if (optionTypeIdentifier(val) == OptionType::integer)
            return std::make_unique<ConfigOptionInt>(ConfigOptionInt(key, stringToInt(val)));
        
        return std::make_unique<ConfigOptionString>(ConfigOptionString(key, val)); // default to string
    }
    
    // test if the string `testString` corresponds to an integer
    // uses the std::stringstream extraction operator, which performs casts if it can
    bool isInt(const std::string& testString)
    {
        int myInt;
        std::stringstream testStringStream{ testString };
        if(!(testStringStream >> myInt))
            return false;
        return true;
    }
    
    bool stringToBool(const std::string& str)
    {
        if (str == "true")
            return true;
        return false;
    }
    
    int stringToInt(const std::string& str)
    {
        int myInt;
        std::stringstream ss{ str };
        ss >> myInt;
        return myInt;
    }
    
    OptionType optionTypeIdentifier(const std::string& val)
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
    cv::VideoCapture          video;
    std::vector<cv::Mat>      frames;
    std::vector<std::unique_ptr<ConfigOption>> options;
    
public:
    VideoPreview(const std::string& videoPathIn, const std::string& configPathIn)
    {
        // import the video file
        video = cv::VideoCapture(videoPathIn);
        if (!video.isOpened())
            std::cout  << "Could not open video: " << videoPathIn << '\n';
        
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
