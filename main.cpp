#include <opencv2/core/mat.hpp>
#include <opencv2/imgcodecs.hpp> // for reading and writing
#include <opencv2/highgui.hpp>   // for displaying an image in a window
#include <opencv2/videoio.hpp>

#include <iostream>

int main( int argc, char** argv ) 
{ 
	cv::Mat img = cv::imread(argv[1],cv::IMREAD_UNCHANGED); 
	if( img.empty() )
	{
		std::cout << "Could not read the image: " << argv[1] <<'\n';
		return -1; 
	}
	cv::namedWindow( "Example Image", cv::WINDOW_AUTOSIZE ); 
	cv::imshow( "Example Image", img ); 
	int k = cv::waitKey( 0 );
	if (k=='s') { cv::imwrite("test.jpg",img); } // save the image
	cv::destroyWindow( "Example1" );
	return 0; 
}