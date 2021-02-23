#include "Preview.hpp"

/*----------------------------------------------------------------------------------------------------
    MARK: - Functions
   ----------------------------------------------------------------------------------------------------*/

string secondsToTimeStamp(const double seconds)
{
    int iseconds = static_cast<int>(seconds);
    
    int h = iseconds / (60*60);
    int m = iseconds / 60;
    int s = iseconds % 60;
    int r = int(seconds*100 - (floor(seconds))*100); // First two decimal places of `seconds`
    
    auto intToString { [](int i){ return i<10 ? '0' + std::to_string(i) : std::to_string(i); } };

    string H = intToString(h);
    string M = intToString(m);
    string S = intToString(s);
    string R = intToString(r);
    
    return H + ':' + M + ':' + S + ':' + R;
}

double frameNumberToSeconds(const int frameNumber, const int fps)
{
    return static_cast<double>(frameNumber) / fps;
}


/*----------------------------------------------------------------------------------------------------
    MARK: - VideoPreview
   ----------------------------------------------------------------------------------------------------*/

void VideoPreview::updatePreview()
{
    cout << "Updating preview\n";
    printConfig();

    // Make a new set of frames if the number of frames has changed
    if ( configOptionHasBeenChanged("maximum_frames") || configOptionHasBeenChanged("maximum_percentage") || configOptionHasBeenChanged("minimum_sampling") || configOptionHasBeenChanged("frames_to_show") || !guiInfo.isPreviewUpToDate() )
        makeFrames();

    // Update `currentPreviewConfigOptions` (we explicitly don't want them to point to the same resource)
    currentPreviewConfigOptions.clear();
    for (ConfigOptionPtr opt : optionsHandler.getOptions())
        currentPreviewConfigOptions.push_back(std::make_shared<ConfigOption>(opt->getID(),opt->getValue()));
}

ConfigOptionPtr VideoPreview::getOption(const string& optionID)
{
    // Search for optionID in the video previews current set of config options
    // ConfigOptionVector.getOption() return nullptr if the option doesn't exist
    ConfigOptionPtr option = optionsHandler.getOptions().getOption(optionID);
    if (option)
        return option;
    
    // If the optionID wasn't found, search for it inthe recognised configuration options
    auto temp = ConfigOption::recognisedOptionInfo.find(optionID);

    // If optionID was found in recognisedOptionInfo, return a ConfigOptionPtr with the corresponding default value
    if (temp != ConfigOption::recognisedOptionInfo.end())
    {
        ConfigValuePtr  defaultValue = ConfigOption::recognisedOptionInfo.at(optionID).getDefaultValue();
        ConfigOptionPtr newOption    = std::make_shared<ConfigOption>(optionID, defaultValue);
        optionsHandler.setOption(newOption); // set with a smart pointer
        return newOption;
    }
    
    // If the optionID wasn't found in the recognised options, return nullptr
    return nullptr;
}

void VideoPreview::saveOptions(ConfigOptionVector options, const string& filePath)
{
    // There are two cases to deal with: either filePath corresponds to a preexisting
    // configuration file (with a corresponding ConfigFile in optionsHandler), or to an
    // arbitrary file. I think of the first case as "saving" the options, and the second
    // case as "exporting" the options.
    
    // Case 1: filePath corresponds to a preexisting configuration file
    // To deal with this possibility I search for a ConfigFile in optionsHandler with the same file path
    // If one is found, we can call the saveOptions() overload that accepts a ConfigFilePtr
    for (ConfigFilePtr file : optionsHandler.getConfigFiles())
        if (filePath == file->getFilePath())
        {
            try
            {
                saveOptions(options, file);
                return;
            }
            catch (const FileException& exception)
            {
                std::cerr << "Could not save option: " << exception.what();
            }
        }
        
    // Case 2: filePath does NOT correspond a preexisting configuration file
    // In this case we do not need to maintain any formatting and can simply write
    // the configuration string for each option to the file.
    std::cout << "Exporting configuration options to \"" << filePath << "\"\n";
    try
    {
        // The following lines disallow the user from exporting a configuration file to a preexisting file
        // I have commented them out because the GUI save panel asks the user to confirm that they will be
        // overwriting a file, so the responsibility is on them...
//        if (fs::exists(filePath))
//            throw FileException("cannot export to a file that already exists\n", filePath);

        std::ofstream outf{ filePath };

        if (!outf)
            throw FileException("cannot open file for exporting\n", filePath);

        // Invalid options are exported first, under the assumption that if they are recognised by a more recent version of
        // the program, they should be prioritised (and the parser prioritises options closer to the top of config files)
        for ( ConfigOptionPtr opt : optionsHandler.getInvalidOptions())
            outf << opt->getConfigString() << std::endl;

        // Blank line between invalid and valid options
        outf << std::endl;
        
        // Export valid options
        for ( ConfigOptionPtr opt : optionsHandler.getOptions())
            outf << opt->getConfigString() << std::endl;
    }
    catch (const FileException& exception)
    {
        std::cerr << exception.what();
    }
}

void VideoPreview::makeFrames()
{
    // 1. Determine the maximum number of frames allowed to be displayed
    int totalFrames   = video.getNumberOfFrames();                                     // The number of frames in the video
    
    int maxPercentage = getOption("maximum_percentage")->getValue()->getInt().value(); // The maximum percentage of frames to show
    int maxFramesFromPercentage = static_cast<int>(maxPercentage/100.0 * totalFrames);
    
    int minSampling   = getOption("minimum_sampling")->getValue()->getInt().value();   // The minimum sampling between frames
    int maxFramesFromSampling   = totalFrames / minSampling;
    
 
    int maximumFramesToShow {};
    
    if ( getOption("maximum_frames")->getValue()->getInt() )
    {
        int maxFramesExplicit = getOption("maximum_frames")->getValue()->getInt().value();     // The maximum number of frames to show
        maximumFramesToShow   = std::min(maxFramesExplicit, maxFramesFromPercentage);
        maximumFramesToShow   = std::min(maximumFramesToShow, maxFramesFromSampling);
    }
    else // maximum_frames value is "auto"
    {
        maximumFramesToShow = std::min(maxFramesFromPercentage, maxFramesFromSampling);
    }
    
    // 2. Determine the actual number of frames to display
    int NFrames;
    
    if (getOption("frames_to_show")->getValue()->getString().has_value()) // frames_to_show value is "auto"
    {
        NFrames = std::min(maximumFramesToShow, guiInfo.getRows()*guiInfo.getCols());
        guiInfo.previewHasBeenUpdated();
    }
    else
        NFrames = maximumFramesToShow * getOption("frames_to_show")->getValue()->getDouble().value();
    
    if (NFrames == 0)
        NFrames = 1;
    
    // 3. Make the new frames (only if the number of frames has changed)
    if (frames.size() == NFrames)
        return;
    
    frames.clear();
    
    double frameSampling = static_cast<double>(totalFrames)/NFrames;
    double frameNumber   = 0.0;
    while (frameNumber < totalFrames)
    {
        int frameNumberInt = static_cast<int>(round(frameNumber));
        if (frameNumberInt >= video.getNumberOfFrames())
            break;
            
        Mat currentFrameMat;
        video.setFrameNumber(frameNumberInt);
        video.getCurrentFrame(currentFrameMat);
        frames.emplace_back(currentFrameMat, static_cast<int>(round(frameNumber)), video.getFPS());
        frameNumber += frameSampling;
    }
}

bool VideoPreview::configOptionHasBeenChanged(const string& optionID)
{
    // When the program runs for the first time the configuration options have always, by definition, been "changed"
    static bool runningForFirstTime = true;
    if (runningForFirstTime)
    {
        runningForFirstTime = false;
        return true;
    }
    
    ConfigOptionPtr optionInternal{ optionsHandler.getOptions().getOption(optionID) };
    ConfigOptionPtr optionPreview { currentPreviewConfigOptions.getOption(optionID) };
    
    // If the option isn't defined in one of the vectors, it can only be unchanged if they are both equal to each other (i.e. nullptr)
    if (!optionInternal || !optionPreview)
        return optionInternal != optionPreview;

    // Knowing that neither option is a nullptr, we can safely compare the actual values stored in each option
    return optionInternal->getValueAsString() != optionPreview->getValueAsString();
}
