#ifndef Preview_hpp
#define Preview_hpp

#if defined(__has_warning)
#if __has_warning("-Wreserved-id-macro")
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdocumentation"
#endif
#endif

#include <opencv2/core/mat.hpp>  // for basic OpenCV structures (Mat, Scalar)
#include <opencv2/imgcodecs.hpp> // for reading and writing
#include <opencv2/videoio.hpp>

#if defined(__has_warning)
#if __has_warning("-Wdocumentation")
#pragma GCC diagnostic pop
#endif
#endif

#include "Configuration.hpp"

using cv::Mat;

/*----------------------------------------------------------------------------------------------------
    MARK: - Frame
   ----------------------------------------------------------------------------------------------------*/

// Data and functions relavant to a single frame of a video
class Frame
{
public:
    Frame(const Mat& dataIn, const int frameNumberIn) : data{ dataIn }, frameNumber{ frameNumberIn } {}

    int getFrameNumber() const { return frameNumber; }
    Mat getData()        const { return data; }

    // Export a bitmap (.bmp) of the frame.
    // The file will be saved in the directeory determined by `exportDir`.
    // Naming of the individual images is taken care of internally.
    void exportBitmap(string& exportPath)
    {
        string fileName = exportPath + "frame" + std::to_string(getFrameNumber()+1) + ".bmp"; // Add 1 to account for zero indexing
        cout << '\t' << fileName << '\n';
        cv::imwrite(fileName, getData());
    }

private:
    Mat data;
    int frameNumber;
};



/*----------------------------------------------------------------------------------------------------
    MARK: - Video
   ----------------------------------------------------------------------------------------------------*/

// Data and functions relevant to a single video file.
// Essentially a wrapper class for a cv::VideoCapture object
class Video
{
public:
    Video(const string& path) : vc{ path }
    {
        if (!vc.isOpened())
            throw FileException("file either could not be opened or is not an accepted format\n", path);
    }

    int  getFrameNumber()                 const { return vc.get(cv::CAP_PROP_POS_FRAMES); }
    int  numberOfFrames()                 const { return vc.get(cv::CAP_PROP_FRAME_COUNT); }
    void setFrameNumber(const int num)          { vc.set(cv::CAP_PROP_POS_FRAMES, num); }
    void writeCurrentFrame(Mat& frameOut)       { vc.read(frameOut); }// Overwrite `frameOut` with a `Mat` corresponding to the currently selected frame

    // Exports an MJPG to exportDir consisting of frames frameBegin to frameEnd-1. Used for exporting preview videos
    void exportVideo(const string& exportPath, const int frameBegin, const int frameEnd)
    {
        string fileName = exportPath + "frame" + std::to_string(frameBegin+1) + "-" + std::to_string(frameEnd) + ".avi"; // Add 1 to account for zero indexing
        cv::VideoWriter vw(fileName, cv::VideoWriter::fourcc('M','J','P','G'), getFPS(), getFrameSize());
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

private:
    double   getFPS()       const { return vc.get(cv::CAP_PROP_FPS); }
    cv::Size getFrameSize() const { return cv::Size(vc.get(cv::CAP_PROP_FRAME_WIDTH),vc.get(cv::CAP_PROP_FRAME_HEIGHT)); }

private:
    cv::VideoCapture vc;
};



/*----------------------------------------------------------------------------------------------------
    MARK: - VideoPreview
   ----------------------------------------------------------------------------------------------------*/

// The main class associated with previewing a single video. `VideoPreview` has three core components:
//      1. `video`:          a `Video` object.            Deals with the core video file which is being previewed
//      2. `frames`:         a vector of `Frame` objects. Deals with the individual frames which are shown in the preview
//      3. `optionsHandler`: a `ConfigOptionsHandler`.    Deals with any options supplied by configuration files
class VideoPreview
{
public:
    VideoPreview(const string& videoPathIn) :
        videoPath{ videoPathIn },
        video{ videoPathIn },
        optionsHandler{ videoPathIn }
    {
        determineExportPath();
        updatePreview();
    }

    // Everything that needs to be run in order to update the actual video preview that the user sees
    // To be run on start-up and whenever configuration options are changed
    void updatePreview()
    {
        cout << "Updating preview\n";
        printConfig();

        // Update the preview
        if (configOptionHasBeenChanged("number_of_frames"))
        {
            makeFrames();
            exportFrames();

            // By default, if the "action_on_hover" option doesn't exist, don't export any preview videos
            // Further, if the "action_on_hover" option has the value "none", there is no need to export any preview videos
            if ( ConfigOptionPtr actionOnHover = getOption("action_on_hover"); actionOnHover && actionOnHover->getValue()->getString() != "none" )
                exportPreviewVideos();
        }

        currentPreviewConfigOptions = optionsHandler.getOptions();

    }

    ConfigOptionPtr getOption(const string& optionID)
    {
        return optionsHandler.getOptions().getOption(optionID);
    }

    void setOption(const BaseConfigOption& optionIn)
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

    // Save a single current configuration option to a configuration file associated with this video
    // Keeps the formatting of the current config file, but overwirtes the option if it has been changed
    void saveOption(ConfigOptionPtr option, const string& filePath)
    {
        std::cout << "Writing configuration option \"" << option->getID() << "\" to file \"" << filePath << "\"\n";
        try
        {
            optionsHandler.saveOption(option, filePath);
        }
        catch (const FileException& exception)
        {
            std::cerr << "Could not save option: " << exception.what();
        }
    }

    // Save all the current configuration options to a configuration file associated with this video
    // Keeps the formatting of the current config file, but overwirtes any options that have been changed
    void saveOptions(const string& filePath)
    {
        for (ConfigOptionPtr opt : optionsHandler.getOptions())
            saveOption(opt, filePath);
    }

    // Export the current configuration options to an arbitrary file
    // The file cannot exist already
    void exportOptions(const string& configFileLocation)
    {
        std::cout << "Exporting configuration options to \"" << configFileLocation << "\"\n";
        try
        {
            if (fs::exists(configFileLocation))
                throw FileException("cannot export to a file that already exists\n", configFileLocation);

            std::ofstream outf{ configFileLocation };

            if (!outf)
                throw FileException("cannot open file for exporting\n", configFileLocation);

            // Invalid options are export first, under the assumption that if they are recognised by a more recent version of
            // the program, they should be prioritised (and the parser prioritises options closer to the top of config files)
            for ( ConfigOptionPtr opt : optionsHandler.getInvalidOptions())
                outf << opt->getConfigFileString() << std::endl;

            // Export valid options
            for ( ConfigOptionPtr opt : optionsHandler.getOptions())
                outf << opt->getConfigFileString() << std::endl;
        }
        catch (const FileException& exception)
        {
            std::cerr << exception.what();
        }
    }

    void printConfig() const
    {
        cout << "Current configuration options:\n";
        optionsHandler.print();
    }

    ~VideoPreview()
    {
        fs::remove_all(exportDir.erase(exportDir.length())); // Delete the temporary directory assigned to this file (remove trailing slash from exportDir)
        if (fs::is_empty("media/.videopreview")) // Delete .videopreview directory if it is empty (i.e. no other file is being previewed)
            fs::remove("media/.videopreview");
    }

private:
    // Parse `videopath` in order to determine the directory to which temporary files should be stored
    // This is saved to `exportDir`, and also returned from the function
    // Modified from https://stackoverflow.com/a/8520815
    string& determineExportPath()
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

    // Read in appropriate configuration options and write over the `frames` vector
    void makeFrames()
    {
        int totalFrames = video.numberOfFrames();
        int NFrames{ optionsHandler.getOptions().getOption("number_of_frames")->getValue()->getInt().value() };
        int frameSampling = totalFrames/NFrames + 1;

        frames.clear();
        int i  = 0;
        for (int frameNumber = 0; frameNumber < totalFrames; frameNumber += frameSampling)
        {
            Mat currentFrameMat;
            video.setFrameNumber(frameNumber);
            video.writeCurrentFrame(currentFrameMat);
            frames.emplace_back(currentFrameMat, frameNumber);
            i++;
        }
    }

    // Exports all frames in the `frames` vector as bitmaps
    void exportFrames()
    {
        fs::create_directories(exportDir); // Make the export directory (and intermediate direcories) if it doesn't exist
        cout << "Exporting frame bitmaps\n";
        for (Frame& frame : frames)
            frame.exportBitmap(exportDir);
    }

    // Exports a "preview video" for each frame in the `frames` vector
    void exportPreviewVideos()
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

    // Determine if a given configuration option has been changed since the last time the preview was updated
    // Achieved by comparing the relevant `ConfigOptionPtr`s in `currentPreviewConfigOptions` and `optionsHandler`
    bool configOptionHasBeenChanged(const string& optionID)
    {
        // If the option isn't defined in one of the vectors, it can only be unchanged if they are both equal to each other (i.e. nullptr)
        ConfigOptionPtr optionInternal{ optionsHandler.getOptions().getOption(optionID) };
        ConfigOptionPtr optionPreview { currentPreviewConfigOptions.getOption(optionID) };
        if (!optionInternal || !optionPreview)
            return optionInternal != optionPreview;

        // Knowing that neither option is a nullptr, we can safely compare the actual values stored in each option
        return !( optionInternal->getValueAsString() == optionPreview->getValueAsString() );
    }

private:
    string videoPath; // Path to the video file
    string videoDir;  // Path to the directory containing the video file
    string exportDir; // Path to the directory for exporting temporary files to
    Video video;
    ConfigOptionsHandler optionsHandler;
    ConfigOptionVector currentPreviewConfigOptions; // The configuration options corresponding to the current preview (even if internal options have been changed)
    vector<Frame>        frames;// Vector of each Frame in the preview
};


#endif /* Preview_hpp */
