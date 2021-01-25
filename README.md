# Video Preview
Eventually, this program will provide a GUI for previewing a video. The intended use case is when looking for a specific parts of / scrubbing through a long video file.

## Requirements

- Will be built as a GUI for macOS
- Video processing is achieved with [OpenCV](https://opencv.org/) dynamic libraries, and [ffmpeg](https://ffmpeg.org/). Both can be installed using `brew`

## Configuration Files

### Format

- Each line of the configuration file is expected to be of the form 

  ```toml
  option_id = option_value
  ```

- All whitespace is ignored, so all of the following are valid, and interpreted as above

  ```toml
  option_id =option_value
  option_id= option_value
  option_id=option_value
  opti on_ id= o p t i o n _ v a l u e
  ```

  - Corollary: the last possibility in particular is recommended against

- Comments are indicated by a hash, `#`

  - Any line beginning with hash will be ignored
  - Any text after a hash on a given line will be ignored

### Recognised Options & Values

Currently the supported options that can be set in configuration files are

| Option ID        | Possible values               |
| ---------------- | ----------------------------- |
| number_of_frames | Any integer >0                |
| maximum_frames   | Any integer between 0 and 100 |
| show_frame_info  | true, false                   |
| action_on_hover  | "none", "play"                |

#### Unrecognised options

For compatibility with future versions, any option parsed from a configuration file with an unrecognised ID (i.e. not one of those listed above) will be stored internally, allowing it to be exported via VideoPreview::exportOptions().

#### Invalid values

Similarly, any *recognised* option with an invalid value (i.e. one not listed under *Possible values* above) will be saved internally, but ignored by the program. If the same option is also parsed from a different configuration file with a valid value, that value will be 

### Files

- Local configuration files, named `.videopreviewconfig`, can be placed in any directory
  - Any configuration file between the working directory and the user home (or root, if the working directory is not a child of the home directory) will be searched for configuration files
- User options are set in `$HOME/.config/videopreview`
- System wide / global options are set in `/etc/videopreviewconfig`

### Priority

- Options defined in local config files take precedent over user options, which take precedent over global options
  - Local files: those lower in the directory hieracy are prioritised
    - e.g. `$HOME/project/videos/.videopreviewconfig` is prioritised over `$HOME/project/.videopreviewconfig`
  - Lower priority files are still parsed. Any options that aren't defined in higher priority files are implemented
- Within a given configuration file, options closer the top are prioritised (i.e if there is a duplicate option, the second version will be ignored)