#include "Preview.hpp"

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
    if (configOptionHasBeenChanged("number_of_frames"))
    {
        makeFrames();

        // By default, if the "action_on_hover" option doesn't exist, don't export any preview videos
        // Further, if the "action_on_hover" option has the value "none", there is no need to export any preview videos
        if ( ConfigOptionPtr actionOnHover = getOption("action_on_hover"); actionOnHover && actionOnHover->getValue()->getString() != "none" )
            exportPreviewVideos();
    }

    currentPreviewConfigOptions = optionsHandler.getOptions();

}

void VideoPreview::setOption(const ConfigOption& optionIn)
{
    try
    {
        cout << "Setting configuration option \"" << optionIn.getID() << "\" to value \"" << optionIn.getValueAsString() << "\"\n";
        optionsHandler.setOption(optionIn);
    }
    catch (const FileException& exception)
    {
        std::cerr << exception.what();
        return;
    }
    updatePreview();
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
    // In this case
    std::cout << "Exporting configuration options to \"" << filePath << "\"\n";
    try
    {
        if (fs::exists(filePath))
            throw FileException("cannot export to a file that already exists\n", filePath);

        std::ofstream outf{ filePath };

        if (!outf)
            throw FileException("cannot open file for exporting\n", filePath);

        // Invalid options are exported first, under the assumption that if they are recognised by a more recent version of
        // the program, they should be prioritised (and the parser prioritises options closer to the top of config files)
        for ( ConfigOptionPtr opt : optionsHandler.getInvalidOptions())
            outf << opt->getConfigFileString() << std::endl;

        // Blank line between invalid and valid options
        outf << std::endl;
        
        // Export valid options
        for ( ConfigOptionPtr opt : optionsHandler.getOptions())
            outf << opt->getConfigFileString() << std::endl;
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
    int totalFrames = video.numberOfFrames();
    int NFrames{ optionsHandler.getOptions().getOption("number_of_frames")->getValue()->getInt().value() };
    int frameSampling = totalFrames/NFrames;

    frames.clear();
    int i  = 0;
    for (int frameNumber = 0; frameNumber < totalFrames; frameNumber += frameSampling)
    {
        if (i == NFrames) // In some cases the frame sampling will be such that one extra frame is selected, so we ignore this final frame
            break;
        Mat currentFrameMat;
        video.setFrameNumber(frameNumber);
        video.writeCurrentFrame(currentFrameMat);
        frames.emplace_back(currentFrameMat, frameNumber);
        i++;
    }
}

void VideoPreview::exportPreviewVideos()
{
    fs::create_directories(exportDir); // Make the export directory (and intermediate direcories) if it doesn't exist
    vector<int> frameNumbers;
    frameNumbers.reserve(frames.size()+1);

    for (Frame& frame : frames)
        frameNumbers.push_back(frame.getFrameNumber());
    frameNumbers.push_back(video.numberOfFrames());

    cout << "Exporting video previews\n";
    int index = 0;
    while ( index < frameNumbers.size()-1 )
    {
        video.exportVideo(exportDir, frameNumbers[index], frameNumbers[index+1]);
        ++index;
    }
}
