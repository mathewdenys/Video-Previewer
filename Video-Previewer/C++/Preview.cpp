#include "Preview.hpp"

/*----------------------------------------------------------------------------------------------------
    MARK: - Global functions
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

// Convert a frame number to a number of seconds (requires knowledge of the fps of the video)
double frameNumberToSeconds(const int frameNumber, const int fps)
{
    return static_cast<double>(frameNumber) / fps;
}


/*----------------------------------------------------------------------------------------------------
    MARK: - Video
   ----------------------------------------------------------------------------------------------------*/

void Video::exportVideo(const string& exportPath, const int frameBegin, const int frameEnd)
{
    string fileName = exportPath + "frame" + std::to_string(frameBegin+1) + "-" + std::to_string(frameEnd) + ".avi"; // Add 1 to account for zero indexing
    cv::VideoWriter vw(fileName, cv::VideoWriter::fourcc('M','J','P','G'), getFPS(), getDimensions());
    setFrameNumber(frameBegin);

    cout << '\t' << fileName << '\n';

    int frameNumber = frameBegin;
    while(frameNumber < frameEnd)
    {
        Mat frame;
        vc >> frame;
        if (frame.empty())
            break;
        vw.write(frame);
        ++frameNumber;
    }
}


/*----------------------------------------------------------------------------------------------------
    MARK: - VideoPreview
   ----------------------------------------------------------------------------------------------------*/

void VideoPreview::updatePreview()
{
    cout << "Updating preview\n";
    printConfig();

    // Update the preview
    if ( configOptionHasBeenChanged("maximum_frames") ||
         configOptionHasBeenChanged("maximum_percentage") ||
         configOptionHasBeenChanged("minimum_sampling") ||
         configOptionHasBeenChanged("frames_to_show") ||
         !guiInfo.isPreviewUpToDate()
        )
    {
        makeFrames();
    }

    // Update `currentPreviewConfigOptions` (we explicitly don't want them to point to the same resource)
    currentPreviewConfigOptions.clear();
    for (ConfigOptionPtr opt : optionsHandler.getOptions())
        currentPreviewConfigOptions.push_back(std::make_shared<ConfigOption>(opt->getID(),opt->getValue()));

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

string& VideoPreview::determineExportPath()
{
    string directoryPath;
    string fileName;

    // Extract the directory path and file name from videoPath
    // These are separated by the last slash in videoPath
    const size_t lastSlashIndex = videoPath.find_last_of("\\/"); // finds the last character that matches either \ or /
    if (string::npos != lastSlashIndex)
    {
        directoryPath = videoPath.substr(0,lastSlashIndex+1);
        fileName       = videoPath.substr(lastSlashIndex+1);
    }

    exportDir = directoryPath + ".videopreview/" + fileName + "/";

    return exportDir;
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
        video.writeCurrentFrame(currentFrameMat);
        frames.emplace_back(currentFrameMat, static_cast<int>(round(frameNumber)), video.getFPS());
        frameNumber += frameSampling;
    }
}
