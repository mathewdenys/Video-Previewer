#include "Exceptions.hpp"
#include "Configuration.hpp"
#include "Preview.hpp"

// Accepts one input argument: the name of the input video file
int main( int argc, char** argv )
{
    try
    {
        if (argc < 2)
            throw std::invalid_argument("Not enough arguments: expected a file path\n");

        if (argc > 2)
            std::cerr << "Ignoring additional arguments.\n";

        VideoPreview vidprev(argv[1]);                     // argv[1] is the input video file path
        ConfigOption<int> updatedOption{"number_of_frames",2};
        vidprev.setOption(updatedOption);
        //vidprev.saveOption(vidprev.getOption("number_of_frames"), "/Users/mathew/Projects/Video-Previewer/Video-Previewer/media/.videopreviewconfig");
        vidprev.saveAllOptions("/Users/mathew/Projects/Video-Previewer/Video-Previewer/media/.videopreviewconfig");
    }
    catch (const std::exception& exception)
    {
        std::cerr << exception.what();
        return 1;
    }

    return 0;
}
