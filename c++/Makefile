# Some variables.
PREFIX = /usr/local

all: bbfe

# Checking section.
checkcpp:
	touch src/.svn
	-src/cpplint.py src/*.cpp
	rm -rf src/.svn

checkh:
	src/cpplint.py src/*.h

# Buildung section.
bbfe.o: src/bbfe.cpp src/newTable.h src/encipher.h src/decipher.h
	g++ -c src/bbfe.cpp -Wall

newTable.o: src/newTable.cpp src/readCSV.h src/newTable.h
	g++ -c src/newTable.cpp -Wall

readCSV.o: src/readCSV.cpp src/readCSV.h
	g++ -c src/readCSV.cpp -Wall

encipher.o: src/encipher.cpp src/encipher.h src/readCSV.h src/findInMap.h
	g++ -c src/encipher.cpp -Wall

findInMap.o: src/findInMap.cpp src/findInMap.h
	g++ -c src/findInMap.cpp -Wall

decipher.o: src/decipher.cpp src/decipher.h src/readCSV.h
	g++ -c src/decipher.cpp -Wall

# Linking section.
bbfe: bbfe.o newTable.o readCSV.o encipher.o findInMap.o decipher.o
	g++ -o bbfe bbfe.o newTable.o readCSV.o encipher.o findInMap.o decipher.o -lboost_program_options

# Cleaning section.
clean:
	rm -rf *.o *.cpp  # Delete all created objects and maybe missguided cpp files.
	rm -rf bbfe

# Installation section.
install:
	# Create /bin directory in $(PREFIX) if it doesn't already exist.
	mkdir -p $(PREFIX)/bin
	# Copy the new file there. TODO: What's the difference between copy and inst.?
	install bbfe $(PREFIX)/bin
	# Create a new directory for the charset.
	mkdir -p $(PREFIX)/share
	# Copy it there.
	install ../share/alphabet_histogram.csv $(PREFIX)/share
