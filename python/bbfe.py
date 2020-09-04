#!/usr/bin/env python3
# encoding: utf8

# Imports:
from argparse import ArgumentParser  # Handle command line arguments
from csv import writer, reader, QUOTE_NONE
from math import ceil  # For rounding up.
from string import ascii_uppercase  # Get a list of uppercase letters.
from random import randint, shuffle  # Generate a random integer or shuffle
                                     # a list.
from datetime import datetime  # Get the current time.
from sys import exit  # Terminate the script early.
from table import newTable

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
              # ommited but in case of 'table' the 'text
              # argument makes no sense
 )
# Where is the cipher table or where should it be written to?
parser.add_argument("-f"
 , "--file"
 , help="Input or output of the cipher table."
 , default='bbfe_cipher_table_' 
            + datetime.now().strftime("%Y.%m.%d_%H.%M.%S") + '.csv'
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

# Variable assignment.
command = arguments.command  # Given command. First positional argument.
text = arguments.text  # Given text to en- or decipher. Second positional arg.
file = arguments.file  # Optional argument for path of cipher table.
charset = arguments.charset  # Optional argument for path of alphabet.
verbose = arguments.verbose  # Optional argument for verbose output.


### Creating a cipher table. ###
if command == 'table':
  newTable(charset, file)

### Encipher a message ###
if command == 'encipher':
  # Create a new dictionary for the cipher table.
  alphabet = list(ascii_uppercase)  # A list for the alphabet.
  cipherTable = {}  # A Dictianory for the character columns and rows.

  # Determine the number of lines in the given file.
  # Needed for the lists in the cipher table dictionary.

  for j in range(0, 26):  # 26 times, zero based.
    cipherTable[alphabet[j]] = []
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
          cipherTable[column].append(row[ord(column) - 65])
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
      for index in range(0, len(cipherTable[key])):  # For all elements of
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
    possibilities = find_positions( cipherTable, char )
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
  cipherTable = {}  # A Dictianory for the character columns and rows.

  # Determine the number of lines in the given file.
  # Needed for the lists in the cipher table dictionary.

  for j in range(0, 26):  # 26 times, zero based.
    cipherTable[alphabet[j]] = []
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
          cipherTable[column].append(row[ord(column) - 65])
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
      print(f'Deciphering column {letters[decipherPosition]} and row {str(numbers[decipherPosition])} as {cipherTable[letters[decipherPosition]][numbers[decipherPosition] -1]}' )    
    decipheredText = decipheredText + cipherTable[letters[decipherPosition]][numbers[decipherPosition] -1]
 
  print( decipheredText )

