#include <iostream>

#if defined(__has_warning)
#if __has_warning("-Wreserved-id-macro")
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdocumentation"
#endif
#endif

#include <opencv2/core/mat.hpp>  // for basic OpenCV structures (cv::Mat, Scalar)
#include <opencv2/imgcodecs.hpp> // for reading and writing
#include <opencv2/highgui.hpp>   // for displaying an image in a window
#include <opencv2/videoio.hpp>

#if defined(__has_warning)
#if __has_warning("-Wdocumentation")
#pragma GCC diagnostic pop
#endif
#endif

int main( int argc, char** argv ) // takes one input argument: the name of the input video file
{ 
	// Load video
	const std::string inputVideoName = argv[1];
	cv::VideoCapture inputVideoCapture(inputVideoName);
	if (!inputVideoCapture.isOpened())
    {
        std::cout  << "Could not open video: " << inputVideoName << '\n';
        return -1;
    }
	
	// Step through frames
	std::string frameTitle = "Press any key to step through frames | q or ESC to exit";
	cv::namedWindow(frameTitle, cv::WINDOW_AUTOSIZE);
	cv::Mat frameIn;
	while(true)
	{
		inputVideoCapture >> frameIn;
		if (frameIn.empty()) { break; }
		cv::imshow(frameTitle, frameIn);
		char k = cv::waitKey( 0 );
		if (k=='q'|| k==27) { break; } // break if 'q' or ESC are pressed
	}
	cv::destroyAllWindows();

	// Export video
	inputVideoCapture.open(inputVideoName); // go back to the start of the video
	cv::VideoWriter outputVideoWriter;
	int      ex   = static_cast<int>(inputVideoCapture.get(cv::CAP_PROP_FOURCC)); 	  // input video codec type (Int form)
	double   fps  = inputVideoCapture.get(cv::CAP_PROP_FPS);						  // input video fps
	cv::Size size = cv::Size((int) inputVideoCapture.get(cv::CAP_PROP_FRAME_WIDTH),
							 (int) inputVideoCapture.get(cv::CAP_PROP_FRAME_HEIGHT)); // input video size
	outputVideoWriter.open("media/output.mp4",ex,fps,size,true);			          // set up video writer of same file type, fps, size, and with colour
	cv::Mat frameOut;
	while(true)
	{
		inputVideoCapture >> frameIn;
		if (frameIn.empty()) break;   // if at end of video
		cv::flip(frameIn,frameOut,1); // 1 = horizontal; -1 = vertical; 0 = both
		outputVideoWriter << frameOut;
	}

	return 0;
}
