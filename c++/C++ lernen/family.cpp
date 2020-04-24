#include <iostream>  // Für Eingabe-Ausgabe-Operationen.
#include <ctime>
#include <chrono>
#include <fstream>
using namespace std;  // Für diverse Funktionen.
using namespace chrono;

class person {
  public:
    string vorName;
    string nachName;
    double koerperHoehe;
    bool geschlecht;
    tm geburtsTag;
};

class familie {  // Klasse für eine Familie.
  public:  // Zugriff von Überall auf diese Klasse.
    person mutter;
    person vater;
    person kinder[];
};

int zeilenInDatei( string dateipfad ) {
  int anzahlZeilen = 0;
  string dummy_Zeile;
  ifstream datei( dateipfad );

  while (getline(datei, dummy_Zeile)){
    ++anzahlZeilen;
  }

  return anzahlZeilen;

}


string namenLesen( string dateipfad) {
  ifstream einzulesendeDatei (dateipfad);

  string vorNamen = new string[zeilenInDatei(dateipfad)];
  string name;
  int i = 0;

  while (getline (einzulesendeDatei, name)) {
    vorNamen[i] = name;
    ++i;
  }

  cout << vorNamen;
  return "Dummy";

}

int main() {

  person MarkusRoth;
  MarkusRoth.vorName = "Markus";
  MarkusRoth.nachName = "Roth";
  MarkusRoth.koerperHoehe = 1.68;
  MarkusRoth.geschlecht = 0;
  MarkusRoth.geburtsTag.tm_year = 1986;

  cout << MarkusRoth.vorName << " ist im Jahr " << MarkusRoth.geburtsTag.tm_year
  << " geboren.\n";

  string *verfuegbareNamen;
  verfuegbareNamen = namenLesen("Namensliste.txt");
  cout << "Verfügbare Namen: " << verfuegbareNamen << "\n";

}
