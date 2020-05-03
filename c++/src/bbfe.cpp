/* Copyright: This software is licensed under
GPLv3. See: https://www.gnu.org/licenses/gpl-3.0.de.html
Bad but (somewhat) fast encryption.
Writte by Markus Roth, 2020 */

#include <iostream>  // For printing to console.
#include <boost/program_options.hpp>  // For handling input.
#include "./newTable.h"  // Function to create a new table.
#include "./encipher.h"  // Function to encipher a text.
#include "./decipher.h"  // Function to decipher a text.

// Set an alias for the long namespace identifier "boost::programm_options".
namespace po = boost::program_options;

// Use the namespace std to avoid long identifiers as "std::string".
using namespace std;

// Main function.
int main(int argc, char **argv) {
  try {
    po::options_description optionsDescription("Allowed options");
    // Declare and initialize a new object for description of options.
    optionsDescription.add_options()
    ("help,h", "produce help message")
    ("charset,c", po::value<string>() ->default_value("alphabet_histogram.csv")
     , "path to file with characters to be used in cipher table")
    ("file,f", po::value<string>() ->default_value("cipher_table.csv")
     , "path to cipher table")
    ("debug,d", po::value<bool>() ->default_value(false)
     , "print debug related output")
    ("command", po::value<string>(), "command to be executed by this program.")
    ("text", po::value<string>(), "Text to be en- or deciphered");
    // Handle positional arguments (not comments).
    po::positional_options_description positionalArgumentsDescription;
    // Add command descriptions to object.
    positionalArgumentsDescription.add("command", 1);
    positionalArgumentsDescription.add("text", 2);

    // Declare a new map for command line arguments.
    po::variables_map optionsArgumentsMap;

    // Store defined options and arguments in map.
    po::store(
      po::command_line_parser(argc, argv)
        .options(optionsDescription)
        .positional(positionalArgumentsDescription)
        .run()
        , optionsArgumentsMap);
    po::notify(optionsArgumentsMap);

    // Set the locale. E.g. for the decimal point.
    // TODO(grindel): This should rather depend on how the charset file is
    // formatted.
    setlocale(LC_NUMERIC, "en_US.UTF-8");

    // TODO(grindel): Understand, why I need to pass argv[1] to a string instead
    // of using it directly. */

//    std::wstring_convert<std::codecvt_utf8_utf16<wchar_t>> converter;
//    string command = argv[1];  // The command given to the programm.
//    string testString = argv[2];
    // The second argument is a text.
//    wstring text = converter.from_bytes(testString);

    // Print help to console.
    if (optionsArgumentsMap.count("help")) {
      cout << optionsDescription << "\n";
      return 1;
    }

    // Creation of a new cipher table from a given set of characters.
    if (optionsArgumentsMap["command"].as<string>() == "table") {
      // Call function for creating a new table.
      cout << "Creating a new cipher table …" << endl;
      newTable(optionsArgumentsMap["charset"].as<string>()
        , optionsArgumentsMap["file"].as<string>()
        , optionsArgumentsMap["debug"].as<bool>());
      cout << "Cipher table \'" << optionsArgumentsMap["file"].as<string>()
           << " succesfully created." << endl;
    }

    // A message is to be enciphered.
    if (optionsArgumentsMap["command"].as<string>() == "encipher") {
      if (optionsArgumentsMap.count("text")) {
        // Call the function specifically written for that.
        encipher(optionsArgumentsMap["text"].as<string>()
          , optionsArgumentsMap["file"].as<string>()
          , optionsArgumentsMap["debug"].as<bool>());
      }
    }

    // A message is to be enciphered.
    if (optionsArgumentsMap["command"].as<string>() == "decipher") {
      if (optionsArgumentsMap.count("text")) {
        // Call the function specifically written for that.
        decipher(optionsArgumentsMap["text"].as<string>()
          , optionsArgumentsMap["file"].as<string>());
      }
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
