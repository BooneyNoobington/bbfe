/* Copyright: This software is licensed under
GPLv3. See: https://www.gnu.org/licenses/gpl-3.0.de.html
Bad but (somewhat) fast encryption. */

// Reads a .csv-file into a map of <string, vector<int>> key value pairs where
// each pair represents <column name, column values>

#ifndef C___SRC_READCSV_H_
#define C___SRC_READCSV_H_

#include <map>  // For class "map".
#include <string>  // For class "string".
#include <vector>  // For class "vector".
#include <fstream>  // For file in- and output.
#include <sstream>  // For class "stringstream".
#include <algorithm>  // For "count()".

// Overload for string keys.
std::map< std::string, std::vector< std::string > > readCSV(
  std::string filename, char sep);

// Overload for missing headers and int keys.
std::map< uint8_t, std::vector< std::string > > readCSV(
  std::string filename, bool header, char sep);

#endif  // C___SRC_READCSV_H_
