/* Copyright: This software is licensed under
GPLv3. See: https://www.gnu.org/licenses/gpl-3.0.de.html
Bad but (somewhat) fast encryption. 
Kudos to: https://www.geeksforgeeks.org/extract-integers-string-c/*/

#include <stdlib.h>  // Break of program.
#include <iostream>  // For console in- and output.
#include <string>  // For class "string".
#include <vector>  // For class "vector".
#include <algorithm>  // For "remove_if()".
#include <cctype>  // For "isdigit()".
#include <sstream>  // For stringstream.
#include <map>  // For class "map".
#include "./readCSV.h"  // For the function of the same name.
#include "./decipher.h"  // Include own header to avoid typos.


using namespace std;

// _____________________________________________________________________________
void decipher(string text, string file) {
  // Later the input will be cut down to characters and numbers.
  vector<char> characters;
  vector<int> numbers;
  // It is simple for characters.
  // They only appear as a single character (never "abc", just "A").
  // Just loop over all the individual characters in "text" and
  // decide wether they are a letter (by applying "isalpha()") or not.
  for (int i = 0; i < text.size(); i++) {
    // If a character is a letter add it to vector "characters".
    if (isalpha(text[i])) { characters.push_back(text[i]); }
  }

  // Remove the letters (and other non number characters) from "text".
  // This is a little more complicated since numbers shouldn't be
  // cut into individual characters like this:
  // "A149B12" -> "1", "4", "9", "1", "2"
  // but rather:
  // "149", "12".
  // First we need to remove all alphanumeric characters.
  // We also strike out all punctioation just to be sure.
  replace_if(text.begin(), text.end(), ::isalpha, ' ');
  replace_if(text.begin(), text.end(), ::ispunct, ' ');
  // Now relay the sring to a stringstream.
  // Then check every "word" (groups of characters between whitespaces)
  // if the are an integer.
  // Declare a new stringstream. This object can be used somewhat similar to
  // a file which contents are read.
  stringstream textStream;
  // "Stream" the input string into the stringstream "textStream".
  textStream << text;
  // Declare a new string "temp" which will hold the above mentioned words.
  string temp;
  // "found" will be an integer which the stringstream will try to fill
  // with values.
  int found;
  while (!textStream.eof()) {
    textStream >> temp;
    // Only if a "word" can be interpreted as a number it will be added to
    // the numbers vector.
    if (stringstream(temp) >> found) {
      numbers.push_back(found);
    }
    // Clear the string "temp". Safety measure against trailing whitespaces.
    temp = "";
  }

  // Quick sanity check.
  if (characters.size() != numbers.size()) {
    cout << "Error: Letters and numbers differ in length. Input is invalid."
         << endl;
    // Break of execution.
    exit(EXIT_FAILURE);
  }
  // Iterate over all number letter pairs and find their corresponding
  // character in "cipherTable".
  // First of: load the cipher table.
  // By setting the second argument to false, a "headless" file (no
  // headers) is assumed.
  // This also chooses the second overload of "readCSV()" which
  // returns a map with integers as keys.
  map<uint8_t, vector<string>> cipherTable =
    readCSV(file, false, '\t');
  // Prepare a string for output.
  string clearText;
  // Now go through all results.
  // The index of the "numbers" vector can be used, since
  // it has to have the same size than "characters".
  for ( uint8_t i = 0; i < numbers.size(); i++ ) {
    clearText = clearText +
      cipherTable[
        static_cast<int>(tolower(static_cast<char>(characters[i]))) - 97]
                 [numbers[i]-1];
  }
  // Present the result.
  cout << clearText << endl;
}
