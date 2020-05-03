/* Copyright: This software is licensed under
GPLv3. See: https://www.gnu.org/licenses/gpl-3.0.de.html
Bad but (somewhat) fast encryption. */

// Function which creates a new cipher table out of a given alphabet.

#ifndef C___SRC_NEWTABLE_H_
#define C___SRC_NEWTABLE_H_

#include <string>  // For class "string".

void newTable(std::string charset, std::string file, bool debug);

#endif  // C___SRC_NEWTABLE_H_
