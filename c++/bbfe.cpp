// Bad but (somewhat) fast encryption. //

#include <iostream>  // For printing to command line (e.g. cout).
#include <fstream>  // For file io.
#include <string>  // Working with strings.
#include <vector>  // For the class "vector".
#include <numeric>
#include <map>  // For the class "dictianory".
#include <math.h>
#include <algorithm>    // random_shuffle
#include <time.h>  // For setting the seed.
#include <unistd.h> 
#include <iterator>
#include <boost/program_options.hpp>  // For handling input.
#include <utility> // pair
#include <stdexcept> // runtime_error
#include <sstream> // stringstream

// Set an alias for the long namespace identifier "boost::programm_options".
namespace po = boost::program_options;

// Use the namespace std to avoid long identifiers as "std::string".
using namespace std;

// Reads a .csv-file into a map of <string, vector<int>> key value pairs where
// each pair represents <column name, column values>
map< string, vector<string>> readCSV( string filename, char sep = ',') {
  // Create a vector of <string, int string> pairs to store the result
  map<string, vector<string>> result;
  
  // Create an input filestream
  ifstream csvFile(filename);
 
 // Make sure the file is open
  if( !csvFile.is_open() ) {  // "is_open()" is a method of "ifstream".
    throw runtime_error("Could not open file");  // Raise an error message.
  }

  // Auxiliary variables.
  // "line" for storing "getline()" output.
  // "colname" for setting the keys of the "map" later.
  // "val" for the actual value of the column imported from .csv-file.
  string line, colname, val;
  // Later it's necessary to access a key of the map "result" not by its
  // key but an index.
  // Maps don't have indexes but this auxiliary vector can help.
  vector<string> columns;

  // Read the column names
  // "good()" is a comprehensive function to check if the stream is "working".
  if ( csvFile.good() ) {
    // Extract the first line in the file.
    // This is done by not using a while-loop.
    getline(csvFile, line);
    // Create a stringstream from line.
    // Stringstream is a bit similar to ifstream.
    stringstream ss(line);
    // Extract each column name.
    // Take the stringstream, modify the string "colname" and stop at
    // the delimiter given by "sep" (argument of the function).
    // TODO: Add the option to read .csv-files without headers.
    while( getline( ss, colname, sep ) ) {
      // Initialize and add <colname, string vector> pairs to result.
      result.insert( { colname, vector<string> {} } );
      // Also add the "colname" to the correspoding vector "columns".
      columns.push_back( colname );
    }
  }

  // Read data, line by line.
  // This time do call while to repeat reading after line is complete.
  while ( getline(csvFile, line) ) {
    // Create a stringstream of the current line.
    stringstream ss(line);
    // Keep track of the current column index
    unsigned short columnIndex = 0;  // TODO: Maybe not redeclare?
    // Extract the item from each column.
    // Remember: "val" is a string declared above.
    while( getline(ss, val, sep) ) {
      // Add the current item to the vector which is the correspoding
      // value to key "result[columnIndex]"
      result[ columns[columnIndex] ].push_back( val );
      // If the next token is the given delimiter, ignore it and move on.
      if ( ss.peek() == sep ) { ss.ignore(); }
      // Increment the column index
      columnIndex++;
    }
  }
  // Close file.
  csvFile.close();
  // return the result.
  return result;
}

// Function for creating a cipher_table.csv.
void newTable( string charset, string file, bool debug = false ){

  // Reset the seed as fast as possible.
  srand((unsigned) time(NULL) * getpid());

  // Define a few vectors which will hold the values from the .csv file.
  vector<string> characters;
  vector<float> abundances;
  vector<int> occurences;

  // Will serve as a line index later.
  short unsigned lineIndex = 0;

  // Obtain the contents of "charset".
  // Delimiter is a tabulator.
  map< string, vector<string> > characterSet = readCSV( charset, '\t' );

  ifstream csvRead( charset );  // Read the file.
  // Constructs new object "csvRead".

  // Transfer and transform the contents of "characterSet"
  // into the respective vectors.
  characters = characterSet["letter"];
  // Transformation/calculation for "abundances" and "occurences" is necessary.
  for ( unsigned short i = 0; i < characterSet["abundance"].size(); i++ ) {
    // Transform string to vector.
    abundances.push_back( stof( characterSet["abundance"][i] ) );
    // Round it up and multiply with two.
    occurences.push_back( ceil( abundances[i] ) * 2 );
  }
  
  // Create a new vector which will hold all the characters
  // as often as "occurences" dictates.
  vector<string> charactersMultiplied;

  /* Enlarge the characters vector.
     Each element should appear according to "occurences". */
  for ( unsigned short i = 0; i < characterSet["letter"].size(); i++) {
    // First iterate over all characters in the string "characters."
    for ( unsigned short j = 0; j < occurences[i]; j++ ){
      // Then see how often the character is supposed to occur (given
      // by occurences[i], while "i" beeing the position of the
      // current character.
      charactersMultiplied.push_back( characterSet["letter"][i] );
      // Add this new character to the new vector "charactersMultiplied".
    }
  }

  // Show the reading of the .csv-file.
  if ( debug ) {
    for ( unsigned short i = 0; i < characterSet["place"].size(); i++ ) {
    cout << characterSet["place"][i] << '\t'
         << characterSet["letter"][i] << '\t'
         << characterSet["abundance"][i] << '\t'
         << abundances[i] << '\t'
         << occurences[i] << '\t' << endl;
    } 
  } 

  // Now, that this vector is filled with chars, shuffle them.
  random_shuffle( charactersMultiplied.begin(),
   charactersMultiplied.end() );

  // Creat a new vector with all uppercase letters in the alphabet.
  vector<char> alphabet(26);
  iota(alphabet.begin(), alphabet.end(), 'A');

  /* How many "rows" will every "column" of the dictianory have? Important
     thing here: Reinterpret the vector sizes as double. Otherwise they
     won't yield another double after division. */
  int rowCount = ceil(
   (float)charactersMultiplied.size() / (float)alphabet.size() );

  // Declare a new map which will hold the cipher table.  
  map<char, vector<string>> cipherTable;

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
  string line;  // Will be filled for every row later.
  ofstream writeCSV( file );  // Declare new output stream.
                                   // File was given to the function by main().
  ostream_iterator<string> outputIterator(writeCSV, "\n");
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
void encipher( string text, string file ) {
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
    // Declare and initialize a new object for description of options.
    desc.add_options()
    ("help", "produce help message")
    ("charset,c", po::value<string>() ->default_value("alphabet_histogram.csv")
     , "path to file with characters to be used in cipher table")
    ("file,f", po::value<string>() ->default_value("cipher_table.csv")
     , "path to cipher table")
    ("debug,d", po::value<bool>() ->default_value( false )
     , "print debug related output")
    ;

    po::variables_map options;  // Initialize a map called options.
    po::store(po::parse_command_line(argc, argv, desc), options);
    po::notify(options);

    setlocale(LC_NUMERIC, "en_US.UTF-8");
    // Set the locale. E.g. for the decimal point.
    // TODO: This should rather depend on how the charset file is formatted.

    /* TODO: Understand, why I need to pass argv[1] to a string instead  of
       using it directly. */
    string command = argv[1];  // The command given to the programm.

    if ( command == "table" ){  // Creation of a new cipher table.
      // Call function for creating a new table.
      newTable( options["charset"].as<string>()
       , options["file"].as<string>(), options["debug"].as<bool>() );
    }

  }

  catch(exception& e) {
    cerr << "error: " << e.what() << "\n";
    return 1;
  }
 
  catch(...) {
    cerr << "Exception of unknown type!\n";
  }

  return(0);

}
