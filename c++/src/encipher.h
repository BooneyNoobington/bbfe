/* Copyright: This software is licensed under
GPLv3. See: https://www.gnu.org/licenses/gpl-3.0.de.html
Bad but (somewhat) fast encryption. */

// Encipher a message.

#ifndef C___SRC_ENCIPHER_H_
#define C___SRC_ENCIPHER_H_

#include <string>  // For class "string".

void encipher(std::string text, std::string file, bool debug);

#endif  // C___SRC_ENCIPHER_H_
