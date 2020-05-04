/* Copyright: This software is licensed under
GPLv3. See: https://www.gnu.org/licenses/gpl-3.0.de.html
Bad but (somewhat) fast encryption. */

#include <vector>  // For class "vector".
#include <iostream>  // For console in- and output.
#include <map>  // For class "map".
#include "./findInMap.h"  // Include own header to avoid typos.

// Avoid e.g. having to call "string" "std::string".
using namespace std;

// _____________________________________________________________________________
vector< pair< int, int > > findInMap(map< uint8_t, vector< string > > x
  , string y ) {
  // A vector of int pairs as a result.
  vector< pair< int, int > > searchResult;
  // Search every key in the map
  for (int key = 0; key < x.size(); key++) {
    // Search trough the value of said key.
    for (int valueIndex = 0; valueIndex < x[key].size(); valueIndex++) {
      // Check wether the character is there or not.
      if ( x[key][valueIndex] == y ) {
        // If the result was found, add position to "searchResult".
        searchResult.push_back(make_pair(key, valueIndex));
      }
    }
  }
  return(searchResult);
}
