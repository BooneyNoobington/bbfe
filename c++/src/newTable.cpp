/* Copyright: This software is licensed under
GPLv3. See: https://www.gnu.org/licenses/gpl-3.0.de.html
Bad but (somewhat) fast encryption. */

#include <math.h>  // For "ceil()".
#include <unistd.h>  // For "getpid()".
#include <time.h>  // Getting current time and use it for randomization.,
#include <iostream>  // Input-output operation.
#include <string>  // Using strings.
#include <fstream>  // Opening an writing files.
#include <iterator>  // Iterate over file operation.
#include <algorithm>  // For "random_shuffle()".
#include <map>  // Use map class.
#include <vector>  // Use vector class.
#include <numeric>  // For "iota()".
#include "./readCSV.h"  // Declaration of readCSV().
#include "./newTable.h"  // Include own header to avoid typos.

// Avoid e.g. having to call "string" "std::string".
using namespace std;

void newTable(string charset, string file, bool debug = false) {
  // Reset the seed as fast as possible.
  srand((unsigned) time(NULL) * getpid());

  // Define a few vectors which will hold the values from the .csv file.
  vector< string > characters;
  vector< float > abundances;
  vector< uint8_t > occurences;

  // Will serve as a line index later.
  uint8_t lineIndex = 0;

  // Obtain the contents of "charset".
  // Delimiter is a tabulator.
  map< string, vector< string> > characterSet = readCSV(charset, '\t');

  ifstream csvRead(charset);  // Read the file.
  // Constructs new object "csvRead".

  // Transfer and transform the contents of "characterSet"
  // into the respective vectors.
  characters = characterSet["letter"];
  // Transformation/calculation for "abundances" and "occurences" is necessary.
  for ( uint8_t i = 0; i < characterSet["abundance"].size(); i++ ) {
    // Transform string to vector.
    abundances.push_back(stof(characterSet["abundance"][i]));
    // Round it up and multiply with two.
    occurences.push_back(ceil(abundances[i]) * 2);
  }
  // Create a new vector which will hold all the characters
  // as often as "occurences" dictates.
  vector< string > charactersMultiplied;

  /* Enlarge the characters vector.
     Each element should appear according to "occurences". */
  for (uint8_t i = 0; i < characterSet["letter"].size(); i++) {
    // First iterate over all characters in the string "characters."
    for (uint8_t j = 0; j < occurences[i]; j++) {
      // Then see how often the character is supposed to occur (given
      // by occurences[i], while "i" beeing the position of the
      // current character.
      charactersMultiplied.push_back(characterSet["letter"][i]);
      // Add this new character to the new vector "charactersMultiplied".
    }
  }

  // Show the reading of the .csv-file.
  if ( debug ) {
    for ( uint8_t i = 0; i < characterSet["place"].size(); i++ ) {
    cout << characterSet["place"][i] << '\t'
         << characterSet["letter"][i] << '\t'
         << characterSet["abundance"][i] << '\t'
         << abundances[i] << '\t'
         << occurences[i] << '\t' << endl;
    }
  }

  // Now, that this vector is filled with chars, shuffle them.
  random_shuffle(charactersMultiplied.begin(),
   charactersMultiplied.end() );

  // Creat a new vector with all uppercase letters in the alphabet.
  vector< char > alphabet(26);
  iota(alphabet.begin(), alphabet.end(), 'A');

  /* How many "rows" will every "column" of the dictianory have? Important
     thing here: Reinterpret the vector sizes as double. Otherwise they
     won't yield another double after division. */
  int rowCount
    = ceil(static_cast< float >(charactersMultiplied.size())
      / static_cast< float >(alphabet.size()));

  // Declare a new map which will hold the cipher table.
  map< char, vector< string > > cipherTable;

  int characterIndex = 0;  // Will later be used as iteration index.

  /* Now go through all letters of the alphabet and add a new character
     from the "charactersMultiplied" vector succesively.
     The index "characterIndex" makes this succesion possible.*/
  for (int i = 0; i < alphabet.size(); i++) {  // For every letter …
    cipherTable.insert({ alphabet[i], { } });  // … add a key accordingly.
    // Leave the character vector empty for now.
    for (int j = 0; j < rowCount; j++) {  // For every row in the upcoming
                                            // cipher table …
      // … add one of the shuffled characters.
      if (characterIndex < charactersMultiplied.size()) {  // Characters left.
        cipherTable[ alphabet[i] ].push_back(
         charactersMultiplied[ characterIndex ]);
      } else {  // No further characters left.
        cipherTable[ alphabet[i] ].push_back(" ");  // Add a whitespace.
      }
      characterIndex++;  // Increase index of "charactersMultiplied" vector.
    }
  }

  // Write the newly generated cipher table.
  string line;  // Will be filled for every row later.
  ofstream writeCSV(file);  // Declare new output stream.
                                   // File was given to the function by main().
  ostream_iterator< string > outputIterator(writeCSV, "\n");
  for (int rowIndex = 0; rowIndex < rowCount; rowIndex++) {
    for (int columnIndex = 0; columnIndex < alphabet.size(); columnIndex++) {
      if (columnIndex < alphabet.size() -1) {
      // For every column except the last one …
        line = line + cipherTable[ alphabet[columnIndex] ][rowIndex] + "\t";
      } else {
        line = line + cipherTable[ alphabet[columnIndex] ][rowIndex] + "\n";
        // When the last column is reached the string should start a new line.
      }
      // Build the line vector.
      // Happens row by row (rowindex is incremented on the outer loop)
      // and column by columns (iteration over the keys of the map on
      // the outer loop).
    }
    writeCSV << line;
    line = "";  // Clear the vector to make it ready for the next line.
  }


  writeCSV.close();  // Close the output stream so that "file" gets unlocked.
}
