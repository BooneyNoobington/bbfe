/* Copyright: This software is licensed under
GPLv3. See: https://www.gnu.org/licenses/gpl-3.0.de.html
Bad but (somewhat) fast encryption. */

#include <iostream>  // For printing to console.
#include <boost/program_options.hpp>  // For handling input.
#include "./newTable.h"  // Function called by this programm.
#include "./encipher.h"  // Function to encipher a text.
#include <locale>
#include <codecvt>

// Set an alias for the long namespace identifier "boost::programm_options".
namespace po = boost::program_options;

// Use the namespace std to avoid long identifiers as "std::string".
using namespace std;

// Main function.
int main(int argc, char **argv) {  // Must have 2 or 0 arguments. Why?
  try {
    po::options_description desc("Allowed options");
    // Declare and initialize a new object for description of options.
    desc.add_options()
    ("help", "produce help message")
    ("charset,c", po::value<string>() ->default_value("alphabet_histogram.csv")
     , "path to file with characters to be used in cipher table")
    ("file,f", po::value<string>() ->default_value("cipher_table.csv")
     , "path to cipher table")
    ("debug,d", po::value<bool>() ->default_value(false)
     , "print debug related output");

    po::variables_map options;  // Initialize a map called options.
    po::store(po::parse_command_line(argc, argv, desc), options);
    po::notify(options);

    setlocale(LC_NUMERIC, "en_US.UTF-8");
    // Set the locale. E.g. for the decimal point.
    // TODO(grindel): This should rather depend on how the charset file is
    // formatted.

    // TODO(grindel): Understand, why I need to pass argv[1] to a string instead
    // of using it directly. */

    std::wstring_convert<std::codecvt_utf8_utf16<wchar_t>> converter;
    string command = argv[1];  // The command given to the programm.
    string testString = argv[2];
    // The second argument is a text.
    wstring text = converter.from_bytes(testString);

    // Creation of a new cipher table from a given set of characters.
    if (command == "table") {
      // Call function for creating a new table.
      newTable(options["charset"].as<string>()
       , options["file"].as<string>(), options["debug"].as<bool>());
    }

    // A message is to be enciphered.
    if (command == "encipher") {
      // Call the function specifically written for that.
      encipher(text, options["file"].as<string>()
        , options["debug"].as<bool>());
    }
  }

  catch(exception& e) {
    cerr << "error: " << e.what() << "\n";
    return 1;
  }

  catch(...) {
    cerr << "Exception of unknown type!\n";
  }

  return(0);
}
