/* Copyright: This software is licensed under
GPLv3. See: https://www.gnu.org/licenses/gpl-3.0.de.html
Bad but (somewhat) fast encryption. */

// Function which creates a new cipher table out of a given alphabet.

#ifndef C___SRC_NEWTABLE_H_
#define C___SRC_NEWTABLE_H_

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

void newTable(std::string charset, std::string file, bool debug);

#endif  // C___SRC_NEWTABLE_H_
