/* Copyright: This software is licensed under
GPLv3. See: https://www.gnu.org/licenses/gpl-3.0.de.html
Bad but (somewhat) fast encryption. */

// Functionn which deciphers a given input.

#ifndef C___SRC_DECIPHER_H_
#define C___SRC_DECIPHER_H_

#include <stdlib.h>  // Break of program.
#include <string>  // For class "string".
#include <iostream>  // For console in- and output.
#include <vector>  // For class "vector".
#include <algorithm>  // For "remove_if()".
#include <cctype>  // For "isdigit()".
#include <sstream>  // For stringstream.
#include <map>  // For class "map".
#include "./readCSV.h"  // For the function of the same name.

void decipher(std::string text, std::string file);

#endif  // C___SRC_DECIPHER_H_
