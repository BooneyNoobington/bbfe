#include <iostream>  // Für Eingabe-Ausgabe-Operationen.
#include <sstream>  // Für String-Konversionen.
using namespace std;  // Für diverse Funktionen.

// Kinderzuordnung via Text.
string kid(string parent){
  if (parent == "Mario"){return "Jakob";}
  if (parent == "Markus"){return "Flora";}
  if (parent == "Isin"){return "Flora";}
  if (parent == "Joe"){return "Sebastian";}
  if (parent == "Jasmin"){return "Alma & Matthy";}
  if (parent == "Nicolai"){return "Alma & Matthy";}
  return "Kein Kind bekannt";
}

// Kinderzuordnung via Nummer.
string kid(int parent_no){
  if (parent_no = 1){return "Jakob";}
  if (parent_no = 2){return "Flora";}
  if (parent_no = 3){return "Flora";}
  if (parent_no = 4){return "Sebastian";}
  if (parent_no = 5){return "Alma & Matthy";}
  if (parent_no = 6){return "Alma & Matthy";}
  return "Kein Kind bekannt";
}

int main(){

  // Fordere eine Nutzerinteraktion an.
  cout << "Bitte gib ein Elternteil an: \n";

  // Greife den Nutzerinput als String ab.
  string input;
  getline(cin, input);  /* "input" wird durch die Funktion getline gesetzt. Als
  Eingabequelle wird das Objekt "cin" genutzt.*/

  // Versuche nun, den Input in einen Integer umzuwandeln.
  std::stringstream ss(input);

  int parent_no;

  if ( (ss >> parent_no).fail() ){  // Umwandlung ist gescheitert.
    string parent = input;
    cout << kid(parent) << "\n";  // Rufe die Funktion mit string-Argument auf.
  } else {
    int parent;
    ss >> parent;
    // Rufe sie mit Integer auf.
    cout << "Kind/Kinder heißt/heißen " << kid( parent ) << "\n";
  }

}
