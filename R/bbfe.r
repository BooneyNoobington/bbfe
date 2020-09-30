#!/usr/bin/env Rscript

# Read arguments from the command line.
# "commandArgs()" gives a vector.
args <- commandArgs(trailingOnly=TRUE)

# Check wether arguments were given or not.
if (length(args)==0) {
  # Stop execution of the script.
  stop(
	"Error: At least command must be supplied."
	, call.=F  # Don't reference whatever called "stop()".
	)
}

# Checks for the supplied command line arguments.
command <- args[1]  # First argument should be a command.

# Setup a list of available commands.
availableCommands <- c(
	"encipher"  # Decipher a text.
	, "decipher"  # Encipher a text.
	, "table"  # Create a new cipher table.
)

# Check wether the passed command is valid.
# Done by "is.element()" which checks wether "command" is included
# in "availableCommands".
if ( is.element(command, availableCommands) == F ){
	stop(  # Stop execution of the script.
    "No available command provided. These are: ",
     paste( availableCommands, collapse=", " )
		, call.=F  # Don't reference whatever called "stop()".
	)
}

# Second argument is the string to be processed.
secondArgument <- args[2]  

# Check wether a cleartext was provided if not only a new cipher table is
# to be created.
if ( is.na(secondArgument) & command != "table" ){
	stop(
		"No cleartext to be de- or enciphered was provided."
		, call.=F  # # Don't reference what called "stop()".
	)
}

# An optional third argument for various purposes.
thirdArgument <- args[3]  

# Function to create a fresh cipher table.
createCipherTable <- function( alphabet, destination ){

	# Create a data frame which contains the characters which are to be
	# distributed among the cells of the cipher table.
	chars <- read.table(
						 file=alphabet  # alphabet is a filepath passed to this function.
						 , sep="\t"  # The table must be separated by a tabulator.
						 , header=T  # The table must contain headers.
						 , quote=""  # No quoting characters, otherwise a " would
												 # mess up the columns.
						 , comment=""  # Same goes for #.
	 				 )

	# Every character should appear at least two times.
	# To achieve this add a new column called "occurence" which is double
	# the set abundance in the alphabet file.
	chars$occurence <- ceiling(chars$abundance) * 2

  # New empty vector.
	charsVector <- vector()  

	# Now fill this vector with the charaters from alphabet
	# but add characters multiple times according to their occurence (calculated
  # above)
  # For all lines.
  # TODO: Is there a more elegant way?
	for ( i in 1:length(chars$letter) ) {
	  # For however often the characters is to occur.
		for ( j in 1:chars$occurence[i] ) {
		  # Add the characters one by one.
		  charsVector <- c(charsVector, as.character(chars$letter[i]))
		}
	}

	# Create a new empty matrix, which is supposed to become the cipher table.
	characterMap <- matrix( 
										 , ncol=26  # As many as the alphabet has letters, somwhat…
										 # Divide the number of characters to be places inside the
										 # matrix by 26 (number of columns) and round round up
										 # to get an interger and not a fraction.
										 , nrow=ceiling(length(charsVector) / 26 )
									 )

	# Begin to fill this new matrix.
	# For every line in the matrix …
	for ( i in 1:nrow(characterMap) ) {
	  # and every column …
		for ( j in 1:ncol(characterMap) ) {  
			# … choose a random integer between 1 and however many characters there 
			# are to be distributed.
		  n <- sample( x=1:length(charsVector), size=1 )

			# Now place the character at the position of the randomnly chosen integer
			# inside the cipher table and remove it from the characters vecor.
		  if ( length(charsVector) > 0) {  # If there are still characters left …
		    characterMap[i,j] <- charsVector[n]  # … map them.
		    charsVector <- charsVector[-n]  # Remove the character that
																					# was distributed.
		  } else {  # Vector became empty.
		    # Map a whitespace.
		    characterMap[i,j] <- " "  
		  }
		}
	}

	# Write the table to the disk.
	write.table(
		x=characterMap  # Object to export is the character map just created.
		, file=destination  # Either a given file or a default location.
		, quote=FALSE  # No quotes, because this would mess up quotation marks.
		, sep="\t"  # Separated by tabulators.
		, fileEncoding="UTF-8"  # Well known on linux.
		, col.names=F  # No names for columns.
		, row.names=F  # No names for rows either.
	)

}

# If the user just wants to create a new cipher table, do it here.
if ( command == "table" ){

	if ( is.na( thirdArgument ) == F ){  # A third argument was given.
	  # Interpret it as a target path.
		targetFile <- thirdArgument  
	} else {  # Use a standard value.
	  # Just call it that.
		targetFile <- "cipherTable.csv"
	}

	if ( file.exists( secondArgument ) ){
	# Check wether the given character map exists.
		createCipherTable( alphabet=secondArgument, destination=targetFile )
		# text is here a path to the character map.
		print( paste ( "Cipher table created. Name:", thirdArgument ) )
		quit( save="no" )
	} else {  # File not found
		stop(
			"The given character map file doesn't exist."
			, call.=F  # Don't reference the calling function in the error message.
		)
	}
}


# Function to encipher a given string.
encipher <- function( clearText ){

	# A path for the cipher table was given.
	if ( length(args)==3 ){
	  # Assume third argument as file.
		givenFile <- thirdArgument  
	} else {
	  # Assume cipherTable lies in the same directory as the script.
		givenFile <- "cipherTable.csv"
	}

	# Obtain a given or default cipher table
	cipherTable <- read.csv(
										file=givenFile  # Given file, see above.
										, sep="\t"  # Separated by tabulators.
										, header=F  # No headers.
										, comment.char=""  # No comments, would mess with hash.
										, quote=""  # No quotes, would mess with quotation marks.
										, encoding="UTF-8"  # Well known in Linux.
									)

	# In order to provess the cleartext, which is a string, it needs
	# to be split in its individual characters.
	# "strsplit()" gives more than one output. [[1]] reduces it to the characters.
	clearText.split <- strsplit(clearText, "")[[1]]  

	# New empty string.
	cipherResult <- ""
	
	# For every individual char in string …
	for (char in clearText.split) {
	
	  # … find cells in the cipher tables that contain char.
	  # "arr.ind" makes "which()" returns a row-column pairs instead of 
	  # numbers describing the position.
  	possibilities <- which(cipherTable == char, arr.ind=T)
		
		# From these randomly pick one. 
		choice <- sample(x=1:nrow(possibilities), size=1)
		
		# Get the line …
		cipherTableLine <- possibilities[ choice, 1]
		# … and the column. But replace the number of the column (1…26) with
		# a letter. (LETTERS is a character vector in all caps provided by R).
		cipherTableColumn <- LETTERS[possibilities[ choice, 2]]

		# Now smash the results together to a string.
		cipherResult <- paste(
											 cipherResult  # The previosly empty vector …
											 # … expanded by cipher row and column.
											 , paste( cipherTableColumn, cipherTableLine, sep="")
                       , sep=""  # No separation character.
										 )
	}


	# Output for user.
	return(cipherResult)  # Return value for use in other function.

}

# Decipher a give input string.
decipher <- function( string ) {

	if ( length(args)==3 ){  # A path for the cipher table was given.
		givenFile <- thirdArgument  # Specified by third argument.
	} else {  # Assume cipherTable lies in the same dir as the script.
		givenFile <- "cipherTable.csv"  # Default value.
	}

	cipherTable <- read.csv(  # Load a cipher table.
										file=givenFile  # Specified above.
										, sep="\t"  # Separation character is a tabulator.
										, header=F  # No headers.
										, comment.char=""  # No comment char, otherwise a hash would
																			 # mess up the lines.
										, quote=""  # Same goes for quotation marks.
										, encoding="UTF-8"
									)  # Well known on Linux.

	# Build a matrix containing letters and numbers directly following them.

  decipherResults <- cbind(
                       as.numeric(match(strsplit(gsub("[^A-Z-]", "", string), "")[[1]], LETTERS))
                       , as.numeric(strsplit(trimws(gsub("[^0-9-]", " ", string)), " ")[[1]])
                     )

	cleartext <- ""  # New empty vector for printing the result.

	for ( j in 1:nrow(decipherResults) ) {  # For all found cells …
		cleartext <- paste(
									 cleartext  # Add to the already obtained cleartext.
                   , cipherTable[decipherResults[j,2], decipherResults[j,1]]
									 # Whatever the cipher table says for the given rows and cols.
									 # These Are given by accessing the matrix decipherResults
									 # by its indexes.
									 , sep=""  # No separation.
								 )
	}

	print(cleartext)  # Print the cleartext.

}

# If the cipher command was given as well as a text to be enciphered …
if ( command == "encipher" & is.na( thirdArgument ) == F ){
  # Encipher third argument.
	print(encipher( secondArgument ), quote=F)  
}


if ( command == "decipher" & is.na( thirdArgument ) == F ){
	decipher( secondArgument )  # Decipher whatever text was passed.
}
