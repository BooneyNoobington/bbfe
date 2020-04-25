# bbfe: Bad but (somewhat) fast encryption

Ciphering of characters according to their positions in a corresponding cipher table.
It is written in different languages for comparison.

## Purpose

This program is meant for studying and not actual encryption.
Perhaps it can be used in conjunction with gnupg or other actual encrytion software to encipher mail headers and make it more difficult to monitor mail traffic.

### Prerequisites

Depending on which variant of bbfe you want to use, you need:

```
An R environment
An python 3 environment
A c++ compiler and common libraries
```

### Installing

Interpreted versions of this programm don't need installing and shoud work out of the box.

For C++ just run navigate to the ````c++```` directory and run.

```
g++ -o bbfe bbfe.cpp
```

## Basic functions

The three functions of bbfe are:

* creating a new cipher table (table).
* enciphering a string (encipher) according to a given cipher table.
* deciphering a string (decipher) according to a given cipher table.

### table

In order to create a new cipher table one must provide bbfe with a set of characters to place in said table.

This file needs three columns.

* place: consecutive number of a certain character (to be removed in future versions). 
* letter: the character to be placed in the cipher table.
* abundance: How often does a letter appear statistically in common words of a language? Can be chosen at random for non letter characters like dots or exclamation marks. 

To encipher create a new new cipher table navigate to the programing language directory of your choosing.

For the python variant type:

```
./bbfe.py table --file path_to_write_cipher_table --charset path_to_possible_characters_file
```

The characters from the charset file will now be randomly placed in the cipher table.
Characters with a higher abundance will be placed more often.

For the C++ and R variants simply use:

```
./bbfe[.r] table path_to_write_cipher_table charset path_to_possible_characters_file
```

### encipher

To encipher the string ````Hello world.```` navigate to the programing language directory of your choosing.

For python type:

```
./bbfe.py encipher "Hello World." --file path_to_cipher_table
```

For the C++ and R variants type:

```
./bbfe[.r] encipher "Hello World." path_to_cipher_table
```

### decipher

Vice versa.



## Authors

* **Markus Roth** - *Initial work*


## License

This project is licensed under GNU General Public License (GPLv3) - see [https://www.gnu.org/licenses/gpl-3.0.html](https://www.gnu.org/licenses/gpl-3.0.html) for details

## Acknowledgments

* stackoverflow.com
* Google Search
* Prof. Hannah Bast and her lecture on programming with C++

