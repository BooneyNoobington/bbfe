#include <iostream>
#include <fstream>
#include <string>

// --   Eine Person
struct Person
{
    std::string vname;
    std::string nname;
    std::string alter;
    std::string geschlecht;
};

// --  diese Funktion liest eine Person vom std::istream
std::istream& lese_ein( std::istream& in, Person& p ){
  getline( in, p.vname, ';');
  getline( in, p.nname, ';');
  getline( in, p.alter, ';');
  getline( in, p.geschlecht, '\n');
  return in;
}

int main()
{
    using namespace std;

    ifstream csvread( "test.csv" );
    if(!csvread.is_open()) 
        cerr << "Fehler beim Oeffnen der Datei!" << endl;
    else {
        for( Person person; lese_ein( csvread, person ); ) {
            ; // tue was mit 'person'
        }
    }
    return 0;
}
