#include <fstream>
#include <iterator>
#include <string>
#include <vector>

int main()
{
    std::vector<std::string> example;
    example.push_back("this");
    example.push_back("is");
    example.push_back("a");
    example.push_back("test");

    std::ofstream output_file("./example.txt");
    std::ostream_iterator<std::string> output_iterator(output_file, "\n");
    std::copy(example.begin(), example.end(), output_iterator);
}
