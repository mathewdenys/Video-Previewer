#include "Configuration.hpp"

/*----------------------------------------------------------------------------------------------------
    MARK: - ConfigOption
   ----------------------------------------------------------------------------------------------------*/

// A map from each optionID that the program recognisesto an associated OptionInformation object
// The order here determines the order the configuration options are displayed in the GUI
const std::unordered_map<string,ConfigOption::OptionInformation> ConfigOption::recognisedOptionInfo {
    {"number_of_frames", OptionInformation("Number of frames to show (the maximum frames actually shown is the number of frames in the video)",
                                           ValidOptionValue::ePositiveInteger)},
    {"maximum_frames",   OptionInformation("The maximum percentage of frames to show in the preview",
                                           ValidOptionValue::ePercentage)},
    {"show_frame_info",  OptionInformation("Whether to overlay information on each frame in the preview",
                                           ValidOptionValue::eBoolean)},
    {"action_on_hover",  OptionInformation("Behaviour when mouse hovers over a frame",
                                           ValidOptionValue::eString,
                                           {"none","play"})}, // TODO: add "slideshow","scrub" as validStrings when I support them
};


void ConfigOption::determineValidity()
{
    try
    {
        // If the ID is invalid, the following throws an std::out_of_range exception
        OptionInformation info = recognisedOptionInfo.at(optionID);
        
        hasValidID = true;

        // Invalid Value
        if (info.getValidValues() == ValidOptionValue::eBoolean)
            hasValidValue = optionValueIsBool();

        if (info.getValidValues() == ValidOptionValue::ePositiveInteger)
            hasValidValue = optionValueIsPositiveInteger();
        
        if (info.getValidValues() == ValidOptionValue::ePercentage)
            hasValidValue = optionValueIsPercentage();

        if (info.getValidValues() == ValidOptionValue::eString)
            hasValidValue = optionValueIsValidString(info.getValidStrings());

        if (!hasValidValue)
            std::cerr << "\tOption with invalid value: \"" << getID() << "\" cannot have the value \"" << optionValue->getAsString() << "\"\n";
    }
    catch (std::out_of_range exception)
    {
        hasValidID = false;
        std::cerr << "\tInvalid option \"" << optionID << "\"\n";
        return;
    }
}


/*----------------------------------------------------------------------------------------------------
    MARK: - ConfigFile + derived classes
   ----------------------------------------------------------------------------------------------------*/

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
        return std::make_shared<ConfigOption>(id, stringToBool(val));

    if (isInt(val))
        return std::make_shared<ConfigOption>(id, stringToInt(val));

    return std::make_shared<ConfigOption>(id, val);
}



/*----------------------------------------------------------------------------------------------------
    MARK: - ConfigOptionsHandler
   ----------------------------------------------------------------------------------------------------*/

ConfigOptionsHandler::ConfigOptionsHandler(const string& videoPath)
{
    loadOptions(videoPath);
    mergeOptions();
}

void ConfigOptionsHandler::saveOptions(ConfigOptionVector optionsToSave, const ConfigFilePtr file)
// Note: options is explicitly passed by value as its elements get deleted
{
    string filePath = file->getFilePath();
    std::cout << "Saving configuration options to \"" << filePath << "\"\n";
    
    // Open the file for reading any preexisting content
    std::ifstream ifs{ filePath };
    if (!file)
        throw FileException("could not open file\n", filePath);
    
    // Open a temporary file for writing to
    string tempFilePath{ filePath + ".temp" };
    std::ofstream ofs{ tempFilePath };
    if (!ofs)
        throw FileException("could not open temporary file\n", tempFilePath);
    
    // Copy each line from the preexisting file to the temporary, while
    // updating the first instance of any options that have changed.
    string line;
    while (std::getline(ifs, line))
    {
        // Do not modify the line if all the updated options have been saved already,
        if (optionsToSave.size() == 0)
        {
            ofs << line << std::endl;
            continue;
        }
        
        // Get the ID of the option specified on the given line
        // Returns empty string for comments and blank lines
        stringstream ss { line };
        string       id { ConfigFile::parseLine(ss).first };
        
        // Search for a matching option ID in the vector of options to save
        auto         IDmatches        = [&](ConfigOptionPtr option) { return option->getID() == id; };
        auto         updatedOptionItr = std::find_if(optionsToSave.begin(), optionsToSave.end(), IDmatches);
        
        // Do not modify the line if the id of the option on the current line doesn't match any of the options to save
        if (updatedOptionItr == optionsToSave.end())
        {
            ofs << line << std::endl;
            continue;
        }
        
        // Modify the line with the current value of the option
        std::cout << "\tSaving \"" << (*updatedOptionItr)->getID() << "\"\n";
        ofs << (*updatedOptionItr)->getConfigFileString() << std::endl;
        
        // Once an option has been saved, remove the corresponding ConfigOptionPtr from optionsToSave
        // This is because only the first instance of an option is modified in the configuration file
        optionsToSave.erase(updatedOptionItr);
    }
    
    // Append any options that weren't already defined in the file to the end of the temporary file
    for (ConfigOptionPtr& option : optionsToSave)
    {
        ofs << option->getConfigFileString() << std::endl;
        std::cout << "\tSaving \"" << option->getID() << "\"\n";
    }

    // Move contents of tempFilePath to filePath and delete tempFilePath
    fs::remove(filePath);
    fs::rename(tempFilePath, filePath);
}

void ConfigOptionsHandler::loadOptions(const string& videoPath)
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
