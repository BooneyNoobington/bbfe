// Bad but (somewhat) fast encryption. //

#include <iostream>  // For printing to command line (e.g. cout).
#include <fstream>  // For file io.
#include <string>  // Working with strings.
#include <vector>  // For the class "vector".
#include <map>  // For the class "dictianory".


// A function to convert a string to a float.
// TODO: Why is this nececarry and I can't just use stof().
// But stof( "17.40" ) gives just 17.
float stringToFloat(std::string x){
  float result= 0.0;  // Initialize "result" as float and 0,0.
  int len = x.length();  // Extract the length of the passed string.
  int dotPosition = 0;  // Position of the decimal point.

  // Iterate over all characters in the string.
  for (int i = 0; i < len; i++){
    if (x[i] == '.' or x[i] == ','){  // Find the decimal deilimieter.
      dotPosition = len - i  - 1;  // Lock its' position.
    } else {  // Haven't reached decimal point yet.
      result = result * 10.0 + (x[i]-'0');  // Multiply according to position.
    }
  }

  // Handle everything behind the decimal point.
  while (dotPosition--){  // Count the post decimal point digits down.
        result /= 10.0;  // Divide according to position.
  }

  return result;  // Return the produced float.
}


// A new struct containing the three important rows,
struct histogramLine {
  std::string place;
  std::string character;
  std::string abundance;
};


// Function for reading a single line of the histogram file.
std::istream& readLine( std::istream& inputStream, histogramLine& x ){
  getline( inputStream, x.place, '\t');  // Read a fiven line until ";" appears.
  getline( inputStream, x.character, '\t');  // see above.
  getline( inputStream, x.abundance, '\n');  // Now stop at the newline.
  return( inputStream );  // Return inputStream.
  /* TODO: Understand why I need to return something…
     Maybe because the input stream is computed and thereforce changed? */
} 

// Function for creating a cipher_table.csv.
void newTable( std::string charset, std::string file ){

  std::vector<std::string> places;
  std::vector<std::string> characters;
  std::vector<float> abundances;
  int lineIndex = 0;

  std::ifstream csvRead( charset );  // Read the file.
  // Constructs new object "csvRead".

  if ( !csvRead.is_open() ){  // For whatever reason the file wasn't opened.
    std::cout << "File " << charset << " couldn't be opened.";
  } else {  // Otherwise …
    for ( histogramLine line; readLine( csvRead, line ); lineIndex++){
    // Construct a new oject "line" from class "histogramLine"…
    // … every time the function readLine() is called on the object "csvRead".
    // Also: increase increment of lineIndex.
      if (lineIndex > 0) {  // Omit the headers.
        places.push_back(line.place);  // Add a new entry in the places vec.
        characters.push_back(line.character);
        abundances.push_back(std::stof(line.abundance));
        std::cout << characters[lineIndex-1] << "|" << abundances[lineIndex-1] << std::endl;
      }
    }
  }

}

// Main function.
int main(int argc, char **argv){  // Must have 2 or 0 arguments. Why?

  std::locale::global( std::locale( "de_DE.utf8" ) );

  /* TODO: Understand, why I need to pass argv[1] to a string instead  of
     using it directly. */
  std::string command = argv[1];  // The command given to the programm.

  if ( command == "table" ){  // Creation of a new cipher table.
    if ( argc > 3 ){  // Enough arguments provided.
      newTable( argv[2], argv[3] );  // Call function for creating a new table.
    } else {
      std::cout << "You must provide a alphabet histogram"
                 << " and a file to output.\n";
    }
  }

  return(0);

}
