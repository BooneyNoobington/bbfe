/* Copyright: This software is licensed under
GPLv3. See: https://www.gnu.org/licenses/gpl-3.0.de.html
Bad but (somewhat) fast encryption. */

// Function to extract key and value index of a certain item.

#ifndef C___SRC_FINDINMAP_H_
#define C___SRC_FINDINMAP_H_

#include <string>  // For class "string".
#include <map>  // For class "map".
#include <utility>  // For class "pair".
#include <vector>  // For class "vector".

// First overload with a map of int keys and string vector values.
std::vector< std::pair<int, int>>
  findInMap(std::map<uint8_t, std::vector<std::string>> x, std::string y);

#endif  // C___SRC_FINDINMAP_H_
