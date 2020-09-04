/* Copyright: This software is licensed under
GPLv3. See: https://www.gnu.org/licenses/gpl-3.0.de.html
Bad but (somewhat) fast encryption. */

// "encipher.h" includes what's needed in this function. E.g. "<string>".
#include "./encipher.h"
// "findInMap.h" provides "findInMap()".
#include "./findInMap.h"


// Avoid having to call e.g. "string" "string".
using std::string;
using std::to_string;
using std::wstring;
using std::wstring_convert;
using std::codecvt_utf8_utf16;
using std::map;
using std::pair;
using std::vector;
using std::cout;
using std::endl;

// _____________________________________________________________________________
void encipher(string textRaw, string file, bool debug = false) {
  wstring_convert<codecvt_utf8_utf16< wchar_t > > converter;
  wstring text = converter.from_bytes(textRaw);
  // "text" is the message to be enciphered,
  // "file" the path to the cipher table.

//  if (text.empty()) {
//    cout << "Error: Pleasy provide a text to be enciphered.";
//  }
  // Call the function to read a previously generated cipher table.
  // By setting the second argument to false, a "headless" file (no
  // headers) is assumed.
  // This also chooses the second overload of "readCSV()" which
  // returns a map with integers as keys.
  map< uint8_t, vector< string > > cipherTable =
    readCSV(file, false, '\t');
  // Show the reading of the .csv-file.
  if ( debug ) {
    // General information about the map.
    cout << "The read cipher table has " << cipherTable.size()
         << " columns." << endl;
    cout << "The first column has " << cipherTable[1].size() << " rows" << endl;
    // A String which will later be used as output.
    string cipherTableLine;
    // For every key in the map …
    for (uint8_t i = 0; i < cipherTable[1].size(); i++) {
      // … build a new string of the j-th vector elements …
      for (uint8_t j = 0; j < cipherTable.size(); j++) {
        if (j < cipherTable.size() -1) {
        // For every column except the last one …
          cipherTableLine = cipherTableLine + cipherTable[j][i] + ' ';
        } else {
          cipherTableLine = cipherTableLine + cipherTable[j][i] + '\n';
        }
      }
      // … and output it to stdout.
      cout << cipherTableLine;
      cipherTableLine = "";
    }
  }
  // Enciphering.
  // Reset the seed as fast as possible.
  srand((unsigned) time(NULL) * getpid());
  // Random number for later.
  unsigned int randomNumber = getpid();
  // Creat a new vector with all uppercase letters in the alphabet.
  vector< char > alphabet(26);
  iota(alphabet.begin(), alphabet.end(), 'A');
  // Create a new string for the output.
  string cipherString;
  // Iterate over all characters in string.
  for (int i = 0; i < text.size(); i++) {
    vector< pair< int, int > > possibilites
      = findInMap(cipherTable, converter.to_bytes(text.at(i)));
      // "ü");  // text.substr(i, 1));
    // Choose one possibility.
    int choice = rand_r(&randomNumber) % possibilites.size();
    cipherString = cipherString + alphabet[possibilites[choice].first]
                    + to_string(possibilites[choice].second + 1);
  }
  // Respond to the user by outputting the generated cipher string.
  cout << cipherString << endl;
}

// _____________________________________________________________________________
void encipher(string textRaw, string file, string charset
  , bool debug = false) {
  wstring_convert<codecvt_utf8_utf16< wchar_t > > converter;
  wstring text = converter.from_bytes(textRaw);
  // "text" is the message to be enciphered,
  // "file" the path to the cipher table.

  // Call the function to read a previously generated cipher table.
  // By setting the second argument to false, a "headless" file (no
  // headers) is assumed.
  // This also chooses the second overload of "readCSV()" which
  // returns a map with integers as keys.
  map< uint8_t, vector< string > > cipherTable =
    readCSV(file, false, '\t');

  // Call the function to read a previously generated charset.
  // This also chooses the first overload of "readCSV()" which
  // returns a map with integers as keys.
  map< string, vector< string > > characterMap =
    readCSV(charset, '\t');

  // Create a map for every character in the charset.
  map< wstring, vector< pair< int, int > > > characterPositions;
  for (int i = 0; i < characterMap["letter"].size(); i++) {
    // Add a new entry in map to store any findings of a certain character.
    // Convert the individual characters to wide strings.
    // Later "characterPositions" will take input from "text" (also wstring).
    characterPositions.insert(
      pair< wstring, vector< pair< int, int > > >
        (converter.from_bytes(characterMap["letter"][i]),
        findInMap(cipherTable, characterMap["letter"][i]))
    );
  }

  // Enciphering.
  string cipherString;
  // Creat a new vector with all uppercase letters in the alphabet.
  vector< char > alphabet(26);
  iota(alphabet.begin(), alphabet.end(), 'A');
  // Reset the seed as fast as possible.
  srand((unsigned) time(NULL) * getpid());
  // Random number for later.
  unsigned int randomNumber = getpid();
  // Respond to the user by outputting the generated cipher string.
  // Iterate over all characters in string.
  for (int i = 0; i < text.size(); i++) {
    // Choose one possibility.
    int choice =
      rand_r(&randomNumber) % characterPositions[text.substr(i, 1)].size();
    cipherString
      = cipherString
        + alphabet[characterPositions[text.substr(i, 1)][choice].first]
        + to_string(characterPositions[text.substr(i, 1)][choice].second + 1);
  }
  cout << cipherString << endl;
}
