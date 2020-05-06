/* Copyright: This software is licensed under
GPLv3. See: https://www.gnu.org/licenses/gpl-3.0.de.html
Bad but (somewhat) fast encryption. */

#include "./findInMap.h"  // Include own header to avoid typos.

// Using declarationsg to avoid long identifiers as "std::string".
// Can be written in a single line if > C++17 is used.
using std::vector;
using std::pair;
using std::string;
using std::map;
using std::make_pair;

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
