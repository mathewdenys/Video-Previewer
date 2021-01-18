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
#include <opencv2/imgproc.hpp>   // for cv::cvtColor()
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
    Video() {};
    
    Video(const string& path) : vc{ path }
    {
        if (!vc.isOpened())
            throw FileException("file either could not be opened or is not an accepted format\n", path);
    }

    int      getFrameNumber()    const    { return vc.get(cv::CAP_PROP_POS_FRAMES);  }
    int      getNumberOfFrames() const    { return vc.get(cv::CAP_PROP_FRAME_COUNT); }
    int      getCodec()          const    { return vc.get(cv::CAP_PROP_FOURCC); }
    double   getFPS()            const    { return vc.get(cv::CAP_PROP_FPS);    }
    cv::Size getDimensions()     const    { return cv::Size(vc.get(cv::CAP_PROP_FRAME_WIDTH),vc.get(cv::CAP_PROP_FRAME_HEIGHT)); }
    
    void setFrameNumber(const int num)    { vc.set(cv::CAP_PROP_POS_FRAMES, num); }
    void writeCurrentFrame(Mat& frameOut) { vc.read(frameOut); }                       // Overwrite `frameOut` with a `Mat` corresponding to the currently selected frame

    // Exports an MJPG to exportDir consisting of frames frameBegin to frameEnd-1. Used for exporting preview videos
    void exportVideo(const string& exportPath, const int frameBegin, const int frameEnd);

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
    VideoPreview(const string& videoPathIn) : videoPath{ videoPathIn } { determineExportPath();}
    
    void loadVideo() { video = Video(videoPath); }
    void loadConfig() { optionsHandler = ConfigOptionsHandler{ videoPath}; }

    // Everything that needs to be run in order to update the actual video preview that the user sees
    // To be run on start-up and whenever configuration options are changed
    void updatePreview();

    ConfigOptionPtr getOption(const string& optionID)                       { return optionsHandler.getOptions().getOption(optionID); }
    void            setOption(const ConfigOption& optionIn);

    // Save a set of current configuration options to either 1) a preexisiting configuration file, or 2) an arbitrary new file
    // In the case of 1, the formatting of the file is maintained, but any options that have been changed are overwritten
    // Function overrides allow the file to be passed as either a string, or a ConfigFilePtr
    void saveOptions(ConfigOptionVector options, const ConfigFilePtr& file) { optionsHandler.saveOptions(options, file); }
    void saveOptions(ConfigOptionVector options, const string& filePath);
    
    void saveAllOptions(const ConfigFilePtr& file)                          { optionsHandler.saveAllOptions(file); }
    void saveAllOptions(const string& filePath)                             { saveOptions(optionsHandler.getOptions(), filePath); }
    
    void saveOption (ConfigOptionPtr option, const ConfigFilePtr& file)     { optionsHandler.saveOptions(ConfigOptionVector{option}, file); }
    void saveOption (ConfigOptionPtr option, const string& filePath)        { saveOptions(ConfigOptionVector{option}, filePath); }

    void printConfig() const
    {
        cout << "Current configuration options:\n";
        optionsHandler.print();
    }
    
    string getVideoNameString()        { return videoPath; }
    string getVideoNumOfFramesString() { return std::to_string(video.getNumberOfFrames()); }
    
    string getVideoFPSString()
    {
        std::stringstream ss;
        ss << video.getFPS() << " fps";
        return ss.str();
    }
    
    string getVideoDimensionsString()
    {
        cv::Size size { video.getDimensions() };
        return std::to_string(size.width) + "x" + std::to_string(size.height);
    }
    
    string getVideoCodecString()
    {   // Refer to https://docs.opencv.org/2.4/doc/tutorials/highgui/video-write/video-write.html
        int ex = video.getCodec();
        char EXT[] = {static_cast<char>(ex & 0XFF) , static_cast<char>((ex & 0XFF00) >> 8),static_cast<char>((ex & 0XFF0000) >> 16),static_cast<char>((ex & 0XFF000000) >> 24), 0};
        return EXT;
    }
    
    string getVideoLengthString()
    {
        double fps     = video.getFPS();
        int    nFrames = video.getNumberOfFrames();
        
        int    seconds = nFrames / fps;
        
        int h = seconds / 60*60;
        int m = seconds / 60;
        int s = seconds % 60;
        
        string H = h<10 ? '0' + std::to_string(h) : std::to_string(h);
        string M = m<10 ? '0' + std::to_string(m) : std::to_string(m);
        string S = s<10 ? '0' + std::to_string(s) : std::to_string(s);
        
        return H + ':' + M + ':' + S;
    }
    
    const static ConfigOption::OptionInformationMap getRecognisedOptionInformation() { return ConfigOption::recognisedOptionInfo; }
    
    vector<Frame> getFrames()   { return frames; }
    
    ~VideoPreview()
    {
        fs::remove_all(exportDir.erase(exportDir.length())); // Delete the temporary directory assigned to this file (remove trailing slash from exportDir)
        if (fs::exists("media/.videopreview") && fs::is_empty("media/.videopreview")) // Delete .videopreview directory if it is empty (i.e. no other file is being previewed)
            fs::remove("media/.videopreview");
    }
    
private:
    // Parse `videopath` in order to determine the directory to which temporary files should be stored
    // This is saved to `exportDir`, and also returned from the function
    // Modified from https://stackoverflow.com/a/8520815
    string& determineExportPath();

    // Read in appropriate configuration options and write over the `frames` vector
    void makeFrames();

    // Exports a "preview video" for each frame in the `frames` vector
    void exportPreviewVideos();

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
    string               videoPath;                   // Path to the video file
    string               videoDir;                    // Path to the directory containing the video file
    string               exportDir;                   // Path to the directory for exporting temporary files to
    Video                video;
    ConfigOptionsHandler optionsHandler;
    ConfigOptionVector   currentPreviewConfigOptions; // The configuration options corresponding to the current preview (even if internal options have been changed)
    vector<Frame>        frames;                      // Vector of each Frame in the preview
};

#endif /* Preview_hpp */
