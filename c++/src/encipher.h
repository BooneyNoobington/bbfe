/* Copyright: This software is licensed under
GPLv3. See: https://www.gnu.org/licenses/gpl-3.0.de.html
Bad but (somewhat) fast encryption. */

// Encipher a message.

#ifndef C___SRC_ENCIPHER_H_
#define C___SRC_ENCIPHER_H_

#include <unistd.h>  // For "getpid()".
#include <string>  // For class "string".
#include <iostream>  // For console in- and output.
#include <map>  // For storing result in a map.
#include <vector>  // Map is made up partially by vectors.
#include <numeric>  // For "iota()".
#include <locale>  // For "wstring" conversion.
#include <codecvt>  // See above.
#include "./readCSV.h"  // For the function of the same name.
#include "./findInMap.h"  // For the function of the same name.

// Encipher a message, naive version.
void encipher(std::string text, std::string file, bool debug);

// Encipher a message but cache the possible charaters first.
void encipher(std::string text, std::string file, std::string charset
  , bool debug);

#endif  // C___SRC_ENCIPHER_H_
