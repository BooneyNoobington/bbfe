#include <sstream>
#include <iostream>
#include <fstream>
//To handle localized input -
//#include <windows.h>
//#include <conio.h>

int main()
{

//read from file - 
    std::ifstream stream("c:\\temporary\\in.txt");
    std::string line;

    if (stream.is_open()) 
    { 
        std::getline(stream, line);
    }

//print on console -
    if(!SetConsoleOutputCP(CP_UTF8)) { // 65001
        std::cerr << "Failed to set console output mode!\n";
        return 1;
    }
    HANDLE const consout = GetStdHandle(STD_OUTPUT_HANDLE);
    DWORD nNumberOfCharsWritten;
    const char* utf8 = line.c_str();
    if(!WriteConsoleA(consout, utf8, strlen(utf8), &nNumberOfCharsWritten, NULL)) {
        DWORD const err = GetLastError();
        std::cerr << "WriteConsole failed with << " << err << "!\n";
        return 1;
    }

//write to file -
    std::fstream myfile;
    myfile.open("c:\\Temporary\\out.txt",std::ios::out);
    if (myfile.is_open()) 
    { 

        myfile << line <<"\n"<<std::endl;
    } 
    myfile.flush();
    myfile.close();
    return 0;
}
