// Reads a .csv-file into a map of <string, vector<int>> key value pairs where
// each pair represents <column name, column values>

#ifndef READCSV_H
#define READCSV_H

// Overload for string keys.
std::map< std::string, std::vector<std::string>> readCSV(
 std::string filename, char sep = ',');

// Overload for missing headers and int keys.
std::map< uint8_t, std::vector<std::string>> readCSV(
 std::string filename, bool header, char sep = ',');

#endif
