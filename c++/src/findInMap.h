/* Copyright: This software is licensed under
GPLv3. See: https://www.gnu.org/licenses/gpl-3.0.de.html
Bad but (somewhat) fast encryption. */

// Function to extract key and value index of a certain item.

#ifndef C___SRC_FINDINMAP_H_
#define C___SRC_FINDINMAP_H_

#include <vector>  // For class "vector".
#include <iostream>  // For console in- and output.
#include <map>  // For class "map".
#include <utility>  // For class "pair".
// TODO(grindel): Why is this needed? It compiles without this header.
#include <string>  // For class "string".

// First overload with a map of int keys and string vector values.
std::vector< std::pair< int, int > >
  findInMap(std::map< uint8_t, std::vector< std::string > > x, std::string y);

#endif  // C___SRC_FINDINMAP_H_
