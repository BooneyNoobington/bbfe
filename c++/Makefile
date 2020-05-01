all : stylecheck compile

stylecheck :
	./cpplint.py --filter -build/namespaces,-build/include,-runtime/threadsafe_fn *.cpp

compile :
	g++ -c bbfe.cpp newTable.cpp readCSV.cpp encipher.cpp findInMap.cpp
	g++ -o bbfe bbfe.o newTable.o readCSV.o encipher.o findInMap.o -lboost_program_options -static

