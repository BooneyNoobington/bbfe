#!/usr/bin/env python3
# encoding: utf8

# Imports:
from argparse import ArgumentParser  # Handle command line arguments
from csv import writer, reader, QUOTE_NONE
from math import ceil  # For rounding up.
from itertools import repeat  # For repeating a given statement.
from string import ascii_uppercase  # Get a list of uppercase letters.
from random import randint  # Generate a random integer.
from datetime import datetime  # Get the current time.

parser = ArgumentParser()  # Define a parser.
# The command passed to this script.
parser.add_argument("command"
                    , help="Action to be performed by this script."
                    , choices=[ "encipher", "decipher", "table" ]
                   )
# The text to be processed.
parser.add_argument("text"
                    , help="Text to be en- or deciphered."
                    , nargs="?"  # Needed since positional arguments cannot be
                                 # ommited but in case of 'table' the 'text'
                                 # argument makes no sense.
                   )
# Where is the cipher table or where should it be written to?
parser.add_argument("-f"
                    , "--file"
                    , help="Input or output of the cipher table."
                    , default='bbfe_cipher_table_' 
                              + datetime.now().strftime("%Y.%m.%d_%H.%M.%S")
                              + '.csv'
                   )
# An alphabet table.
parser.add_argument("-c"
                    , "--charset"
                    , help="Characters to be distributed in the cipher table."
                    , default="alphabet.csv"
                   )
# An option for verbose output.
parser.add_argument('-v'
                    , '--verbose'
                    , help='Give a verbose output.'
                    , action="store_true"
                    , dest="verbose"
                   )

arguments = parser.parse_args()  # Read arguments from the command line. 


### Variable assignment. ###
command = arguments.command  # Given command. First positional argument.

text = arguments.text  # Given text to en- or decipher. Second positional arg.

file = arguments.file 

charset = arguments.charset

verbose = arguments.verbose


### Creating a cipher table. ###
if command == 'table':

  # Lists, gathered from a csv-file.
  place = []
  letter = []
  abundance = []
  occurence = []

  try:
    with open( charset ) as csv_file:  # "with" handles opening and closing.
        csv_reader = reader( csv_file, delimiter='\t' , quoting=QUOTE_NONE )
        # An object that contains rows extracted from the file above.
        next(csv_reader)
        for row in csv_reader:  # For all extracted lines …
          # … add new items to the lists for place, letter and its' abundance.
          place.append(row[0])
          letter.append(row[1])
          abundance.append(float(row[2].replace(",",".")))
          # Decimal could be given by a comma.
  except:
    print(f'Something went wrong, when opening \'{charset}\'. ' 
          + 'Does the file exist in the current directory?')

  # Define a new list which contains an integer for how often a char is to appear.
  for element in abundance:
    occurence.append( ceil( element ) * 2 )  # Round up to get a integer
                                                  # bigger than zero.

  # New list for characters from the charset but every character appears at
  # least twice.

  characters = []

  # Fill this new list.
  for i in letter:  # For all elements in the "letter" list …
    for _ in repeat(None, occurence[letter.index(i)]):
      # … repeat the following statement n-times (given by occurence).
      characters.append(i)  # Add a new item.

  alphabet = list(ascii_uppercase)  # A list for the alphabet.
                                           # Represents the columns.
  rowcount = ceil(len(characters) / 26)  # How many rows will there be?

  character_table = {}  # A Dictianory for the character columns and rows.

  for j in range(0, 26):  # 26 times, zero based.
    character_table[alphabet[j]] = [None] * rowcount
    # Add a new key, which is a letter from the alphabet in ascending order …
    # and then add empty lists as the value.
    # Their length is determined by a rounded up number of charactes from
    # the characters list.

  for key in character_table:  # Meaning: from A to Z.
    for index in range(0, len(character_table[key])):
    # Create an index for the elements of the respective list.
      if len(characters) > 0:  # The character list still has elements.
        character_table[key][index] = characters.pop(
                                       randint(0, len(characters) - 1)
                                      )
        # Go to the value of "key" and it's position "index" …
        # … and place a random element of "characters" there.
      else:  # Characters list is empty.
        character_table[key][index] = " "  # Fill the position with a whitespace.


  # Write the character table to a csv file.
  try:
    with open( file, mode='w', newline='' ) as csvfile:
      linewriter = writer( csvfile, delimiter='\t'
                           , quoting=QUOTE_NONE, quotechar='', escapechar='\\' )
      line = []
      for lineindex in range(0, rowcount):
        for rowindex in alphabet:
          line.append(character_table[rowindex][lineindex])
        linewriter.writerow( line )
        line.clear()
  except:
    print(f'A problem when writing the cipher tablle \'{file}\' occured. ' +
          'No output was generated.' )

  print(f'Succesfully generated a cipher table here \'{file}\'.')

if command == 'encipher':
  # Create a new dictionary for the cipher table.
  alphabet = list(ascii_uppercase)  # A list for the alphabet.
  character_table = {}  # A Dictianory for the character columns and rows.

  # Determine the number of lines in the given file.
  # Needed for the lists in the cipher table dictionary.

  for j in range(0, 26):  # 26 times, zero based.
    character_table[alphabet[j]] = []
    # Add a new key, which is a letter from the alphabet in ascending order …
    # and then add empty lists as the value.
    # Their length is determined by how many lines there are in the file.

  try: 
    with open( file ) as cipher_table:
      # TODO: Is it possible to read the csv-file by column instead of row?
      csv_reader = reader(cipher_table, delimiter='\t', quoting=QUOTE_NONE)
      # Open the cipher table file for line by line reading.
      for row in csv_reader:  # For every line …
        for column in alphabet:  # … iterate over every letter in the alphabet.
        # These letters correspond with the keys of the cipher table dictionary.
          character_table[column].append(row[ord(column) - 65])
          # The column is the key (letters).
          # Append an entry from the row that was just read.
          # "Transform" the letter into a number to get a proper list index.
  except:
    print(f'The File {file} could not be read.')
    exit(1)
      
  # Function to determine occurences of a char in a dictionary.
  def find_positions( dictionary, search_char ):
    # Initialize a new dictionary as a return value.
    rowsAndColumns = { "columns": [], "rows": [] }
    # Containing keys "columns" (A to Z) and "rows".
    for key in dictionary:  # Meaning: from A to Z.
      # TODO: Works only of the value to a key is a list.
      for index in range(0, len(character_table[key])):  # For all elements of
                                                         # the list belonging to
                                                         # the "key".
        if dictionary[key][index] == search_char:  # If the interesting char
                                                   # is there …
          # Append new items to "rows" and "columns".
          rowsAndColumns["columns"].append(key)
          rowsAndColumns["rows"].append(index + 1)  # Zero based …
    return( rowsAndColumns )

  cipheredText = ''

  for char in text:
    possibilities = find_positions( character_table, char )
    # What possibilities are there encipher a given character?

    # Quick sanity check.
    if len( possibilities['columns'] ) != len( possibilities['rows'] ):
      print('Error, lists for columns and rows differ in length.')
    else:
      choiceIndex = randint(0, len( possibilities['columns'] ) - 1  )

    choice = possibilities['columns'][choiceIndex] + str(possibilities['rows'][choiceIndex])
    cipheredText = cipheredText + choice
  if verbose:
    print(f'Enciphering \n"{text}"\nto: \n{cipheredText}')
  else:
    print( cipheredText )

if command == 'decipher':

  # Create a new dictionary for the cipher table.
  alphabet = list(ascii_uppercase)  # A list for the alphabet.
  character_table = {}  # A Dictianory for the character columns and rows.

  # Determine the number of lines in the given file.
  # Needed for the lists in the cipher table dictionary.

  for j in range(0, 26):  # 26 times, zero based.
    character_table[alphabet[j]] = []
    # Add a new key, which is a letter from the alphabet in ascending order …
    # and then add empty lists as the value.
    # Their length is determined by how many lines there are in the file.

  try:
    with open( file ) as cipher_table:
      # TODO: Is it possible to read the csv-file by column instead of row?
      csv_reader = reader(cipher_table, delimiter='\t', quoting=QUOTE_NONE)
      # Open the cipher table file for line by line reading.
      for row in csv_reader:  # For every line …
        for column in alphabet:  # … iterate over every letter in the alphabet.
        # These letters correspond with the keys of the cipher table dictionary.
          character_table[column].append(row[ord(column) - 65])
          # The column is the key (letters).
          # Append an entry from the row that was just read.
          # "Transform" the letter into a number to get a proper list index.
  except:
    print(f'Something went wrong, when opening {file}.')

  print(f'Deciphering string: {text}')

  letters = []
  numbers = []

  for char in text:
    if char.isalpha():
      letters.append( char )
  
  textDigitsOnly = ''.join([c if c.isdigit() else ' ' for c in text])

  numbers = [int(s) for s in textDigitsOnly.split() if s.isdigit()]

  # Quick sanity check.
  if len(letters) != len(numbers):
    print('Error: text to be deciphered invalid. More letters ' +
          'than numbers or vice versa.''')

  decipheredText = ""

  for decipherPosition in range(0, len(letters) ):
    if verbose == True:
      print(f'Deciphering column {letters[decipherPosition]} and row {str(numbers[decipherPosition])} as {character_table[letters[decipherPosition]][numbers[decipherPosition] -1]}' )    
    decipheredText = decipheredText + character_table[letters[decipherPosition]][numbers[decipherPosition] -1]
 
  print( decipheredText )

