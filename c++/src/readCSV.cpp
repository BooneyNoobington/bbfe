/* Copyright: This software is licensed under
GPLv3. See: https://www.gnu.org/licenses/gpl-3.0.de.html
Bad but (somewhat) fast encryption.
Kudos to:
https://www.gormanalysis.com/blog/reading-and-writing-csv-files-with-cpp/*/

#include "./readCSV.h"  // Include own header to avoid typos.

// Using declarationsg to avoid long identifiers as "std::string".
// Can be written in a single line if > C++17 is used.
using std::map;
using std::string;
using std::vector;
using std::ifstream;
using std::map;
using std::pair;
using std::runtime_error;
using std::stringstream;

// _____________________________________________________________________________
map< string, vector< string > > readCSV(string filename, char sep = ',') {
  // Create a map of keys as strings and values as string vectors
  // to store the result.
  map< string, vector< string > > result;

  // Create an input filestream
  ifstream csvFile(filename);

  // Make sure the file is open.
  if (!csvFile.is_open()) {  // "is_open()" is a method of "ifstream".
    throw runtime_error("Could not open file");  // Raise an error message.
  }

  // Auxiliary variables.
  // "line" for storing "getline()" output.
  // "colname" for setting the keys of the "map" later.
  // "val" for the actual value of the column imported from .csv-file.
  string line, colname, val;
  // Later it's necessary to access a key of the map "result" not by its
  // key but an index.
  // Maps don't have indexes but this auxiliary vector can help.
  vector< string > columns;

  // Read the column names
  // "good()" is a comprehensive function to check if the stream is "working".
  if ( csvFile.good() ) {
    // Extract the first line in the file.
    // This is done by not using a while-loop.
    getline(csvFile, line);
    // Create a stringstream from line.
    // Stringstream is a bit similar to ifstream.
    stringstream ss(line);
    // Extract each column name.
    // Take the stringstream, modify the string "colname" and stop at
    // the delimiter given by "sep" (argument of the function).
    // TODO(grindel): Add the option to read .csv-files without headers.
    while (getline(ss, colname, sep)) {
      // Initialize and add <colname, string vector> pairs to result.
      result.insert( pair<string, vector<string>>(
        colname, vector<string>()));
      // Also add the "colname" to the correspoding vector "columns".
      columns.push_back(colname);
    }
  }

  // Read data, line by line.
  // This time do call while to repeat reading after line is complete.
  while ( getline(csvFile, line) ) {
    // Create a stringstream of the current line.
    stringstream ss(line);
    // Keep track of the current column index
    uint8_t columnIndex = 0;  // TODO(grindel): Maybe not redeclare?
    // Extract the item from each column.
    // Remember: "val" is a string declared above.
    while (getline(ss, val, sep)) {
      // Add the current item to the vector which is the correspoding
      // value to key "result[columnIndex]"
      result[columns[columnIndex]].push_back(val);
      // If the next token is the given delimiter, ignore it and move on.
      if ( ss.peek() == sep ) { ss.ignore(); }
      // Increment the column index
      columnIndex++;
    }
  }
  // Close file.
  csvFile.close();
  // return the result.
  return result;
}


// _____________________________________________________________________________
map< uint8_t, vector< string > > readCSV(string filename
  , bool header, char sep = '\t') {
  // Create a map of keys as integers and values as string vectors
  // to store the result.
  map< uint8_t, vector< string > > result;

  // Create an input filestream
  ifstream csvFile(filename);

  // Make sure the file is open
  if (!csvFile.is_open()) {  // "is_open()" is a method of "ifstream".
    throw runtime_error("Could not open file");  // Raise an error message.
  }

  // Auxiliary variables.
  // "line" for storing "getline()" output.
  // "val" for the actual value of the column imported from .csv-file.
  // columnIndex will later be used as key for the result map.
  string line, val;
  uint8_t columnIndex;

  // Create the column names/keys.
  // "good()" is a comprehensive function to check if the stream is "working".
  if ( csvFile.good() ) {
    // Extract the first line in the file.
    // This is done by not using a while-loop.
    getline(csvFile, line);
    // Determine how many columns there are.
    // Since "sep" is the delimiter, its how often sep occurs + 1.
    // "count()" from <algorithm> counts the occurence of "sep".
    size_t sepCount = count(line.begin(), line.end(), sep);
    // Initialize result with empty vectors but as many keys as there are
    // columns.
    for (uint8_t i = 0; i < sepCount; i++) {
      result.insert({ i, vector< string > {} });
    }
  }
  // Return to line 0 or line 1 depending of wether headers should be
  // incorporated or not.
  if (header) {  // a header should be included.
    // Go to line 1 which is the first line after the header.
    csvFile.seekg(1);
  } else {  // Otherwise …
    // … return to line 0, which contains data and not headers.
    csvFile.seekg(0);
  }
  // Read data, line by line.
  // This time do call while to repeat reading after line is complete.
  while ( getline(csvFile, line) ) {
    // Create a stringstream of the current line.
    stringstream ss(line);
    // Keep track of the current column index
    columnIndex = 0;
    // Extract the item from each column.
    // Remember: "val" is a string declared above.
    while (getline(ss, val, sep)) {
      // Add the current item to the vector which is the correspoding
      // value to key "result[columnIndex]"
      result[columnIndex].push_back(val);
      // If the next token is the given delimiter, ignore it and move on.
      if ( ss.peek() == sep ) { ss.ignore(); }
      // Increment the column index
      columnIndex++;
    }
  }
  // Close file.
  csvFile.close();
  // return the result.
  return(result);
}
