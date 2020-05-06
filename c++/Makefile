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
	g++ -c src/bbfe.cpp

newTable.o: src/newTable.cpp src/readCSV.h src/newTable.h
	g++ -c src/newTable.cpp

readCSV.o: src/readCSV.cpp src/readCSV.h
	g++ -c src/readCSV.cpp

encipher.o: src/encipher.cpp src/encipher.h src/readCSV.h src/findInMap.h
	g++ -c src/encipher.cpp

findInMap.o: src/findInMap.cpp src/findInMap.h
	g++ -c src/findInMap.cpp

decipher.o: src/decipher.cpp src/decipher.h src/readCSV.h
	g++ -c src/decipher.cpp

# Linking section.
bbfe: bbfe.o newTable.o readCSV.o encipher.o findInMap.o decipher.o
	g++ -o bbfe bbfe.o newTable.o readCSV.o encipher.o findInMap.o decipher.o -lboost_program_options -static

# Cleaning section.
clean:
	rm -rf *.o *.cpp  # Delete all created objects and maybe missguided cpp files.
	rm -rf bbfe

install:
	install bbfe /home/grindel/Programme
