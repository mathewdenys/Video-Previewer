#include "Configuration.hpp"

/*----------------------------------------------------------------------------------------------------
    MARK: - AbstractConfigValue & derived classes
   ----------------------------------------------------------------------------------------------------*/

// Template specialisation of ConfigValue<T>::getAsString() functions
template<> string ConfigValue<bool>  ::getAsString() const { return (getBool().value() ? "true" : "false"); }
template<> string ConfigValue<int>   ::getAsString() const { return std::to_string(getInt().value()); }
template<> string ConfigValue<string>::getAsString() const { return getString().value(); }



/*----------------------------------------------------------------------------------------------------
    MARK: - RecognisedConfigOption + BaseConfigOption & derived classes
   ----------------------------------------------------------------------------------------------------*/

// An array that contains every RecognisedConfigOption that the program "understands"
const array<RecognisedConfigOption,3> BaseConfigOption::recognisedConfigOptions {
    RecognisedConfigOption("number_of_frames", "Number of frames to show",                 ValidOptionValues::ePositiveInteger        ),
    RecognisedConfigOption("show_frame_info",  "Show individual frame information",        ValidOptionValues::eBoolean                ),
    RecognisedConfigOption("action_on_hover",  "Behaviour when mouse hovers over a frame", ValidOptionValues::eString, {"none","play"}) // TODO: add "slideshow","scrub" as validStrings when I support them
};


void BaseConfigOption::determineValidity()
{
    auto templateOption = findRecognisedOptionWithSameID();

    // Invalid ID
    if ( templateOption == recognisedConfigOptions.end() )
    {
        hasValidID = false;
        std::cerr << "\tInvalid option \"" << optionID << "\"\n";
        return;
    }

    hasValidID = true;

    // Invalid Value
    if (templateOption->getValidValues() == ValidOptionValues::eBoolean)
        hasValidValue = optionValueIsBool();

    if (templateOption->getValidValues() == ValidOptionValues::ePositiveInteger)
        hasValidValue = optionValueIsPositiveInteger();

    if (templateOption->getValidValues() == ValidOptionValues::eString)
        hasValidValue = optionValueIsValidString(templateOption->getValidStrings());

    if (!hasValidValue)
        std::cerr << "\tOption with invalid value: \"" << getID() << "\" cannot have the value \"" << optionValue->getAsString() << "\"\n";

}


/*----------------------------------------------------------------------------------------------------
    MARK: - ConfigFile + derived classes
   ----------------------------------------------------------------------------------------------------*/

void ConfigFile::writeOptionToFile(ConfigOptionPtr option)
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
        ss >> std::ws;     // Remove leading white space
        if ( ss.rdbuf()->in_avail() == 0 ||     // Copy blank lines unchanged to temp file
             ss.peek() == '#' ||                 // Copy comment lines unchanged to temp file
             parseLine(ss).first != option->getID()                 // Copy "other" configuration options unchanged to temp file
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

void ConfigFile::parseFile()
{
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
            ss >> std::ws;     // remove leading white space

            // Ignore blank lines and comment lines
            if (ss.rdbuf()->in_avail() == 0 || ss.peek() == '#')
                continue;

            // Parse the current line into a ConfigOption
            ConfigOptionPtr newOption = makeOptionFromStrings(parseLine(ss));

            // Ignore lines with duplicate options (prioritise options defined higher in the configuration file)
            if ( options.getOption(newOption->getID()) ) // nullptr is returned by getID() if that optionID doesn't exist in options
                return;

            // If the option is invalid (unrecognised ID or invalid value), add to the `invalidOptions` vector
            if ( !newOption->isValid() )
            {
                invalidOptions.push_back( newOption );
                continue;
            }

            // Add the valid option to the `options` vector
            options.push_back( newOption );
        }
    }
    catch (const FileException& exception)
    {
        std::cerr << exception.what();
    }

}

using idValPair = pair<string,string>;

idValPair ConfigFile::parseLine(stringstream& ss)
{
    string id;
    string val;

    char c;
    bool reachedEqualsSign = false;
    while (ss.get(c))
    {
        if (c == '#')     // ignore comments
            break;
        if (c == '=')     // switch from writing to `id` to `val` when of RHS of equals sign
            reachedEqualsSign = true;
        else if (!reachedEqualsSign)
            id.push_back(c);
        else
            val.push_back(c);
        ss >> std::ws;     // always remove any following white space
    }

    return idValPair{ id, val };
}

ConfigOptionPtr ConfigFile::makeOptionFromStrings(const idValPair& inputPair)
{
    string id  = inputPair.first;
    string val = inputPair.second;

    if (val == "true" || val == "false")
        return std::make_shared< ConfigOption<bool> >(id, stringToBool(val));

    if (isInt(val))
        return std::make_shared< ConfigOption<int> >(id, stringToInt(val));

    return std::make_shared< ConfigOption<string> >(id, val);
}



/*----------------------------------------------------------------------------------------------------
    MARK: - ConfigOptionsHandler
   ----------------------------------------------------------------------------------------------------*/

ConfigOptionsHandler::ConfigOptionsHandler(const string& videoPath)
{
    // Remove the name of the video file from videoPath, to isolate the directory it is in
    string localDir = videoPath.substr(0,videoPath.find_last_of("\\/"));
    string localConfigFilePath;

    // Scan through all directories between that containing the video and the user home
    //  directory (or the root directory if the user home directory isn't in the hierarchy)
    while ( localDir.length() > 0 && localDir != std::getenv("HOME") )
    {
        localConfigFilePath = localDir + "/.videopreviewconfig";
        if (fs::exists(localConfigFilePath))
            configFiles.push_back( std::make_shared<ConfigFile>(localConfigFilePath) );                           // Load local config files
        localDir = localDir.substr(0,localDir.find_last_of("\\/"));
    }

    configFiles.push_back( std::make_shared<ConfigFile>(string(std::getenv("HOME")) + "/.config/videopreview") ); // Load user config file
    configFiles.push_back( std::make_shared<ConfigFile>("/etc/videopreviewconfig") );                             // Load global config file

    mergeOptions();
}

void ConfigOptionsHandler::saveOption(ConfigOptionPtr option, const string& filePath)
{
    // If filePath corresponds to any of the files in configFiles, use the corresponding ConfigFile's writeOptionToFile() member function
    for (ConfigFilePtr file : configFiles)
        if (file->getFilePath() == filePath)
        {
            file->writeOptionToFile(option);
            return;
        }

    std::cerr << "Could not save option to configuration file \"" << filePath << "\" as it is not a recognised configuration file\n";
}

void ConfigOptionsHandler::mergeOptions()
{
    configOptions.clear();

    // The configFiles vector is ordered from highest priority to lowest priority, so we scan through it in order.
    // For each file we add any configuration options that haven't been imported yet. Any others can be ignored because
    // the value that has already been imported is from a higher priority configuration file
    for ( ConfigFilePtr& file : configFiles)
    {
        // Merge valid options
        for ( ConfigOptionPtr& opt : file->getOptions() )
            if ( string id{ opt->getID() }; !configOptions.getOption(id) )
                configOptions.push_back(opt);

        // Merge invalid options
        for ( ConfigOptionPtr& opt : file->getInvalidOptions() )
            if ( string id{ opt->getID() }; !invalidConfigOptions.getOption(id) )
                invalidConfigOptions.push_back(opt);
    }
}
