/* Copyright: This software is licensed under
GPLv3. See: https://www.gnu.org/licenses/gpl-3.0.de.html
Bad but (somewhat) fast encryption. */

#include <iostream>
#include <map>  // For storing result in a map.
#include <vector>  // Map is made up partially by vectors.
#include <string>
#include <numeric>  // For "iota()".
#include <unistd.h>
#include "./readCSV.h"  // For the function of the same name.
#include "./findInMap.h"  // For the function of the same name.

// Avoid having to call e.g. "string" "std::string".
using namespace std;

// Encipher a message.
void encipher(string text, string file, bool debug = false) {
  // "text" is the message to be enciphered,
  // "file" the path to the cipher table.

  if (text.empty()) {
    cout << "Error: Pleasy provide a text to be enciphered.";
  }
  // Call the function to read a previously generated cipher table.
  // By setting the second argument to false, a "headless" file (no
  // headers) is assumed.
  // This also chooses the second overload of "readCSV()" which
  // returns a map with integers as keys.
  map<uint8_t, vector<string>> cipherTable =
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
      // … and output it.
      cout << cipherTableLine;
      cipherTableLine = "";
    }
  }
  // Enciphering.
  // Reset the seed as fast as possible.
  srand((unsigned) time(NULL) * getpid());
  // Creat a new vector with all uppercase letters in the alphabet.
  vector<char> alphabet(26);
  iota(alphabet.begin(), alphabet.end(), 'A');
  // Create a new string for the output.
  string cipherString;
  wstring bull = "ü";
  // Iterate over all characters in string.
  for (int i = 0; i < bull.size(); i++) {
    vector<pair<int, int>> possibilites
      = findInMap(cipherTable, "ü");  // text.substr(i, 1));
    // Choose one possibility.
    int choice = rand() % possibilites.size();
    cipherString = cipherString + alphabet[possibilites[choice].first]
                    + to_string(possibilites[choice].second + 1);
  }
  // Respond to the user by outputting the generated cipher string.
  cout << cipherString << endl;
}
