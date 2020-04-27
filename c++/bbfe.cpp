// Bad but (somewhat) fast encryption. //

#include <iostream>  // For printing to command line (e.g. cout).
#include <fstream>  // For file io.
#include <string>  // Working with strings.
#include <vector>  // For the class "vector".
#include <numeric>
#include <map>  // For the class "dictianory".
#include <math.h>
#include <algorithm>    // std::random_shuffle
#include <time.h>
#include <unistd.h> 
#include <iterator>
#include <boost/program_options.hpp>
namespace po = boost::program_options;

using namespace std;

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

  std::srand((unsigned) time(NULL) * getpid());  // Set the seed as randomly
                                                 // as possible.


  // Define a few vectors which will hold the values from the .csv file.
  std::vector<std::string> places;
  std::vector<std::string> characters;
  std::vector<float> abundances;
  std::vector<int> occurences;


  int lineIndex = 0;  // Will serve as a line index later.


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
        characters.push_back(line.character);  // Sames as above.
        abundances.push_back(std::stof(line.abundance));
        // Same as above but convert the passed string to a float.
        occurences.push_back(std::ceil(abundances[lineIndex-1]) * 2 );
      }
    }
  }

  std::vector<std::string> charactersMultiplied;  // Create a new vecotr which 
                                                  // will hold the characerts.

  /* Enlarge the characters vector.
     Each element should appear according to "occurences". */
  for ( int i = 0; i < characters.size(); i++) {
    // First iterate over all characters in the string "characters."
    for ( int j = 0; j < occurences[i]; j++ ){
      // Then see how often the character is supposed to occur (given
      // by occurences[i], while "i" beeing the position of the
      // current character.
      charactersMultiplied.push_back( characters[i] );
      // Add this new character to the new vector "charactersMultiplied".
    }
  }

  // Now, that this vector is filled with chars, shuffle them.
  std::random_shuffle( charactersMultiplied.begin(),
   charactersMultiplied.end() );

  // Creat a new vector with all uppercase letters in the alphabet.
  std::vector<char> alphabet(26);
  std::iota(alphabet.begin(), alphabet.end(), 'A');

  /* How many "rows" will every "column" of the dictianory have? Important
     thing here: Reinterpret the vector sizes as double. Otherwise they
     won't yield another double after division. */
  int rowCount = std::ceil(
   (double)charactersMultiplied.size() / (double)alphabet.size() );

  // Declare a new map which will hold the cipher table.  
  std::map<char, std::vector<std::string>> cipherTable;

  int characterIndex = 0;  // Will later be used as iteration index.

  /* Now go through all letters of the alphabet and add a new character
     from the "charactersMultiplied" vector succesively.
     The index "characterIndex" makes this succesion possible.*/
  for ( int i = 0; i < alphabet.size(); i++ ) {  // For every letter …
    cipherTable.insert( { alphabet[i], {} } );  // … add a key accordingly.
    // Leave the character vector empty for now.
    for ( int j = 0; j < rowCount; j++ ) {  // For every row in the upcoming
                                            // cipher table …
      // … add one of the shuffled characters.
      if ( characterIndex < charactersMultiplied.size() ) {  // Characters left.
        cipherTable[ alphabet[i] ].push_back(
         charactersMultiplied[ characterIndex ] );
      } else { // No further characters left.
        cipherTable[ alphabet[i] ].push_back( " " );  // Add a whitespace.
      }
      characterIndex++;  // Increase index of "charactersMultiplied" vector.
    }
  }

  // Write the newly generated cipher table.
  std::string line;  // Will be filled for every row later.
  std::ofstream writeCSV( file );  // Declare new output stream.
                                   // File was given to the function by main().
  std::ostream_iterator<std::string> outputIterator(writeCSV, "\n");
  for ( int rowIndex = 0; rowIndex < rowCount; rowIndex++ ) {
    for ( int columnIndex = 0; columnIndex < alphabet.size(); columnIndex++ ) {
      if ( columnIndex < alphabet.size() -1  ) {
      // For every column except the last one …
        line = line + cipherTable[ alphabet[columnIndex] ][rowIndex] + "\t";
      } else {
        line = line + cipherTable[ alphabet[columnIndex] ][rowIndex] + "\n";
        // When the last column is reached the string should start a new line.
      }
      // Build the line vector.
      // Happens row by row (rowindex is incremented on the outer loop)
      // and column by columns (iteration over the keys of the map on
      // the outer loop).
    }
    writeCSV << line;
    line = "";  // Clear the vector to make it ready for the next line.
  }


  writeCSV.close();  // Close the output stream so that "file" gets unlocked.

}


// Encipher a message.
void encipher( std::string text, std::string file ) {
  // "text" is the message to be enciphered, 
  // "file" the path to the cipher table.
  if ( file.empty() ) {  // No file was given.
    file = "./cipher_table.csv";  // Assume an existing cipher table in the
                                  // current directory.
  }
}


// Main function.
int main(int argc, char **argv){  // Must have 2 or 0 arguments. Why?

  try {
 
    po::options_description desc("Allowed options");
    desc.add_options()
    ("help", "produce help message")
    ("compression", po::value<double>(), "set compression level")
    ;

    po::variables_map vm;        
    po::store(po::parse_command_line(argc, argv, desc), vm);
    po::notify(vm);    

    if (vm.count("help")) {
      cout << desc << "\n";
      return 0;
    }

    if (vm.count("compression")) {
      cout << "Compression level was set to " 
       << vm["compression"].as<double>() << ".\n";
    } else {
      cout << "Compression level was not set.\n";
    }
  
  }
  
  catch(exception& e) {
    cerr << "error: " << e.what() << "\n";
    return 1;
  }
 
  catch(...) {
    cerr << "Exception of unknown type!\n";
  }

  std::setlocale(LC_NUMERIC, "en_US.UTF-8");
  // Set the locale. E.g. for the decimal point.
  // TODO: This should rather depend on how the charset file is formatted.

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
