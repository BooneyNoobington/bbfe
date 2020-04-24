#include <iostream>  // Für Eingabe-Ausgabe-Operationen.
using namespace std;  // Für diverse Funktionen.

void swapNums(string &x, string &y) {
  string hilfsVariable = x;
  x = y;
  y = hilfsVariable;
}

int main() {
  string ersterWert = "erster Wert";
  string zweiterWert = "zweiter Wert";

  cout << "Vor Tausch: " << "\n";
  cout << ersterWert << " " << zweiterWert << "\n";
  cout << *ersterWert << " " << *zweiterWert << "\n";

  // Call the function, which will change the values of ersterWert and zweiterWert
  swapNums(ersterWert, zweiterWert);

  cout << "Nach Tausch: " << "\n";
  cout << ersterWert << " " << zweiterWert << "\n";
  cout << *ersterWert << " " << *zweiterWert << "\n";

  return 0;
}
