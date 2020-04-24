#include <iostream>  // Für Eingabe-Ausgabe-Operationen.
using namespace std;  // Für diverse Funktionen.

void AddNumbers(int &x, int &y) {
  cout << "Ergebnis der Kalkulation: " << x+y << "\n";  /* Zähle zwei Zahlen
  zusammen und schreibe das Ergebnis in die Konsole. */
}

int main() {
  string NumberOneString;  // Deklariere String für erste Variable.
  string NumberTwoString;  // s.o.
  cout << "Bitte geben Sie eine Zahl ein: ";  /* Fordere den Nutzer
  zur Eingabe der ersten Zahl. */
  getline (cin, NumberOneString);  // Lese die erste Zahl ein.
  cout << "Bitte geben Sie eine weitere Zahl ein: ";  // s.o.
  getline (cin, NumberTwoString);  // s.o.
  int NumberOneInteger = stoi(NumberOneString);  /* Wandle die Zeichen-
  kette in eine Zahl um. TODO: Exception abfangen. */
  int NumberTwoInteger = stoi(NumberTwoString);  // s.o.
  AddNumbers(NumberOneInteger, NumberTwoInteger);  /* Rufe die obige Funk-
  tion auf. */
}
