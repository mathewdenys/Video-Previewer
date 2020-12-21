#include "Configuration.hpp"

// Template specialisation of getAsString() functions
template<> string ConfigValue<bool>  ::getAsString() const { return (getBool().value() ? "true" : "false"); }
template<> string ConfigValue<int>   ::getAsString() const { return std::to_string(getInt().value()); }
template<> string ConfigValue<string>::getAsString() const { return getString().value(); }



// An array that contains every RecognisedConfigOption that the program "understands"
const array<RecognisedConfigOption,3> BaseConfigOption::recognisedConfigOptions {
    RecognisedConfigOption("number_of_frames", "Number of frames to show",                 ValidOptionValues::ePositiveInteger        ),
    RecognisedConfigOption("show_frame_info",  "Show individual frame information",        ValidOptionValues::eBoolean                ),
    RecognisedConfigOption("action_on_hover",  "Behaviour when mouse hovers over a frame", ValidOptionValues::eString, {"none","play"}) // TODO: add "slideshow","scrub" as validStrings when I support them
};
