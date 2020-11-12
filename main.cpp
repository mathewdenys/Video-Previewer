#include <iostream>
#include <fstream>
#include <sstream>
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

class ConfigParser
{
private:
    std::string configFilePath;
    std::map<std::string, std::string> configPairs;

    // ConfigParser::lineParser() parses a single line of the configuration file
    // Returns a std::pair where the key is the name of the configuration option, and the val is the corresponding value
    // Assumes each line is formatted as `LHS = RHS`
    // For now the spaces are mandatory. Eventually I will handle e.g. `LHS=RHS`, and comment lines
    std::pair<std::string, std::string> lineParser(std::string& strIn)
    {
        std::string key;
        std::string val;

        std::stringstream ss{ strIn };
        ss >> key; // LHS of equals sign
        ss >> val; // The equals sign (will be overritten)
        ss >> val; // RHS of equals sign
        std::pair<std::string, std::string> pair{ key, val };
        return pair;
    }

public:
    ConfigParser(std::string pathIn) : configFilePath{ pathIn }
    {
        std::ifstream file{ configFilePath };
        if (!file)
            std::cerr << configFilePath << " could not be opened\n";

        std::map<std::string, std::string> configPairsIn;

        while (file)
        {
            std::string strInput;
            std::getline(file, strInput);
            if (strInput.length() != 0)     // Ignore blank lines
                configPairsIn.insert(lineParser(strInput));
        }

        configPairs = configPairsIn;
    }

    void print()
    {
        for ( auto el : configPairs )
            std::cout << el.first << "\n\t" << el.second << std::endl;
    }
};

int main( int argc, char** argv ) // takes one input argument: the name of the input video file
{
    ConfigParser parser("media/.videopreviewconfig");
    parser.print();
    return 0;
}
