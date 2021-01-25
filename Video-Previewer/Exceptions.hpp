#ifndef Exceptions_hpp
#define Exceptions_hpp

#include <iostream>

using std::string;

class FileException : public std::exception
{
public:
    FileException(string errorDescription, string fileIn) : file{ fileIn }, message{ "Error when accessing \"" + fileIn + "\": " + errorDescription } {};
    const char* what() const noexcept override { return message.c_str(); }

protected:
    string message;
    string file;
};

#endif /* Exceptions_hpp */
