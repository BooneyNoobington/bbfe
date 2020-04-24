#!/usr/bin/env Rscript

# Read arguments from the command line.
args=commandArgs(trailingOnly=TRUE)

# Check wether arguments were given or not.
if (length(args)==0) {
  stop(
	"At least command must be supplied."
	, call.=F  # Don't reference what called "stop()".
	)
}

# Checks for the supplied command line arguments.
command <- args[1]  # First argument should be a command.

available_commands <- c(
	"cipher"  # Decipher a text.
	, "decipher"  # Encipher a text.
	, "table"  # Create a new cipher table.
)

# Check wether the passed command is valid.
if ( is.element(command, available_commands) == F ){  # No available command
                                                      # was supplied.
	stop(  # Stop execution.
    "No available command provided. These are: ",
     paste( available_commands, collapse=", " )
		, call.=F  # Don't reference what called "stop()".
	)
}


text <- args[2]  # Second argument is the string to be processed.

# Check wether a cleartext was provided if not only a new cipher table is
# to be created.
if ( is.na(text) & command != "table" ){
	stop(
		"No cleartext to be de- or enciphered was provided."
		, call.=F  # # Don't reference what called "stop()".
	)
}

third_argument <- args[3]  # An optional third argument for various purposes.


# Function to create a fresh cipher table.
create_cipher_table <- function( alphabet, destination ){

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
	chars$occurence <- ceiling(chars$abundance) * 2  # Multiply the abundance
																									 # with two.

	chars_vector <- vector()  # New empty vector.

	# Now fill this vector with the charaters from alphabet
	# but add characters multiple times according to their occurence (calculated
  # above)
	for ( i in 1:length(chars$letter) ) {  # For all lines.
		for ( j in 1:chars$occurence[i] ) {  # For however often the characters
																				 # is to occur.
		  chars_vector <- c(chars_vector, as.character(chars$letter[i]))
			# Add the characters one by one.
		}
	}

	# Create a new matrix, which is supposed to become the cipher table.
	character_map <- matrix( 
										 , ncol=26  # As many as the alphabet has letters, somwhat…
										 , nrow=ceiling(length(chars_vector) / 26 )
										 # Divide the number of characters to be places inside the
										 # matrix by 26 (number of columns) and round round up
										 # to get an interger and not a fraction.
									 )

	# Begin to fill this new matrix.
	for ( i in 1:nrow(character_map) ){  # For every line in the matrix …
		for ( j in 1:ncol(character_map) ){  # and every column …
		  n <- sample( x=1:length(chars_vector), size=1 )
			# … choose a random integer between 1 and however many characters there 
			# are to be distributed.

			# Now place the randomnly chosen integer inside the cipher table
			# and remove it from the characters vecor.
		  if ( length(chars_vector) > 0) {  # If there are still characters left …
		    character_map[i,j] <- chars_vector[n]  # … map them.
		    chars_vector <- chars_vector[-n]  # Remove the character that
																					# was distributed.
		  } else {  # Vector became empty.
		    character_map[i,j] <- " "  # Map a whitespace.
		  }
		}
	}

	# Print the cipher table for inspection.
	print(character_map)

	# Write the table to the disk.

	write.table(
		x=character_map  # Object to export is the character map just created.
		, file=target_file  # Either a given file or a default location.
		, quote=FALSE  # No quotes, because this would mess up quotation marks.
		, sep="\t"  # Separated by tabulators.
		, fileEncoding="UTF-8"  # Well known on linux.
		, col.names=F  # No names for columns.
		, row.names=F  # No names for rows either.
	)

}

# If the user just wants to create a new cipher table, do it here.
if ( command == "table" ){

	if ( is.na( third_argument ) == F ){  # A third argument was given.
		target_file <- third_argument  # Interpret it as a target path.
	} else {  # Use a standard value.
		target_file <- "cipher_table.csv"  # Just call it that.
	}

	if ( file.exists( text ) ){
	# Check wether the given character map exists.
		create_cipher_table( alphabet=text, destination=target_file )
		# text is here a path to the character map.
		print( paste ( "Cipher table created. Name:", third_argument ) )
		quit( save="no" )
	} else {  # File not found
		stop(
			"The given character map file doesn't exist."
			, call.=F  # Don't reference the calling function in the error message.
		)
	}
}


# Function to encipher a given string.
cipher <- function( string ){
	
	if ( length(args)==3 ){  # A path for the cipher table was given.
		given_file <- third_argument  # Assume third argument as file.
	} else {  # Assume cipher_table lies in the same dir as the script.
		given_file <- "cipher_table.csv"
	}

	# Obtain a given or default cipher table
	cipher_table <- read.csv(
										file=given_file  # Given file, see above.
										, sep="\t"  # Separated by tabulators.
										, header=F  # No headers.
										, comment.char=""  # No comments, would mess with hash.
										, quote=""  # No quotes, would mess with quotation marks.
										, encoding="UTF-8"  # Well known in Linux.
									)

	# In order to provess the cleartext, which is a string, it needs
	# to be split in its individual characters.
	string_split <- strsplit(string, "")[[1]]  # strsplit gives more than
																						 # one output. [[1]] catches the
																						 # characters.
	cipher_result <- ""  # New empty string.
	for (char in string_split) {  # For every individual char in string …
  	possibilities <- which(cipher_table == char, arr.ind=T)
		# … find cells in the cipher tables that contain char.
		possibility <- sample( x=1:nrow(possibilities), size=1 )
		# From these randomly pick one. 
		cipher_line <- possibilities[ possibility, 1]  # Get the line …
		cipher_column <- LETTERS[possibilities[ possibility, 2]]
		# … and the column. But replace the number of the column (1…26) with
		# a letter. (LETTERS is a character vector in all caps provided by R).

		# Now smash the results together to a string.
		cipher_result <- paste(
											 cipher_result  # The previosly empty vector …
											 , paste( cipher_column, cipher_line, sep="")
											 # … expanded by cipher row and column.
                       , sep=""  # No separation character.
										 )
	}

  print( paste( "Enciphering:", text, "to:", cipher_result ) )
	# Output for user.

	return(cipher_result)  # Return value for use in other function.

}

# Decipher a give input string.
decipher <- function( string ) {

	if ( length(args)==3 ){  # A path for the cipher table was given.
		given_file <- third_argument  # Specified by third argument.
	} else {  # Assume cipher_table lies in the same dir as the script.
		given_file <- "cipher_table.csv"  # Default value.
	}

	cipher_table <- read.csv(  # Load a cipher table.
										file=given_file  # Specified above.
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
                   , cipher_table[decipherResults[j,2], decipherResults[j,1]]
									 # Whatever the cipher table says for the given rows and cols.
									 # These Are given by accessing the matrix decipherResults
									 # by its indexes.
									 , sep=""  # No separation.
								 )
	}

	print(cleartext)  # Print the cleartext.

}

# If the cipher command was given as well as a text to be enciphered …
if ( command == "cipher" & is.na( third_argument ) == F ){
	cipher( text )  # Encipher third argument.
}


if ( command == "decipher" & is.na( third_argument ) == F ){
	decipher( text )  # Decipher whatever text was passed.
}
