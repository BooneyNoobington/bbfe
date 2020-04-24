#!/usr/bin/env python3
# coding: utf8
#
#
#
### Vorarbeit ###
from datetime import datetime  # Wird für die Datumsverarbeitung gebraucht.
from math import floor  # Später müssen wir Abrunden.
from calendar import isleap  # Antwort auf die Frage: "Ist Jahr YYYY ein Schalt-
# jahr?"
import argparse  # Umgang mit dem Input.
import sys  # Das sys-Modul stellt Informationen in Konstanten, Funktionen und
# Methoden über den Python-Interpreter zur Verfügung.
#
# Festlegen der Zeichen für elf und zwölf #
zehn=u"\u0661"  # Arabische 1.
elf=u"\u0662"  # Arabische 2.
#
#
## Einlesen der Funktionsdatei ##
sys.path.append("/usr/local/lib/")  # Hänge mein eigenes Libraryverzeichnis an.
from func import base10to12 # Importiere von dort aus die benötigte Funktion.
#
#
## Vorarbeit zu übergebenen Argumenten und Optionen ##
#
# Konfiguration von argparse #
parser = argparse.ArgumentParser()  # Festlegen des Parsers.
parser.add_argument("datum", help="Gibt Das angegebene Datum in unterschiedlichen Formaten aus. Die Eingabe von \"heute\" benutzt das aktuelle Datum.", type=str)  # Hinzufügen des möglichen Arguments.
parser.add_argument("-z","--zehn", help="Legt das Symbol für die Ziffer \"zehn\" fest")
parser.add_argument("-e","--elf", help="Legt das Symbol für die Ziffer \"elf\" fest")
args = parser.parse_args()  # Übergeben der Argumente an "parser".
if args.zehn != None:  # Falls für "args.zehn" etwas angegeben wurde …
  zehn=args.zehn  # … Lege das gewünschte Zeichen für zehn fest.
  print("Symbol für \"zehn\": ",zehn,sep='')
if args.elf != None:  # S.o.
  elf=args.elf
  print("Symbol für \"elf\": ",elf,sep='')
#TODO: Test darauf, ob GENAU ein Argument übergeben wurde.
#
#
## Berechnung der Differenz ##
if args.datum == "heute":  # Das aktuelle Datum soll verwendet werden.
  d1=datetime.now()
else:  # Ein angegebenes Datum soll verwendet werden.
  try:  # Versuche, die nachfolgende Aktion auszuführen.
    d1 = datetime.strptime(args.datum, "%d.%m.%Y")  # Datum aus Argument aus-
# lesen.
  except ValueError:  # "ValuError" bedeutet hier, dass das eingegebene Format
# kein gültiges Datum war. Das ist die Ausnahme (engl.: exception).
    print("Eingabe in ungültigem Format. Ich brauche dd.mm.yyyy.")
    sys.exit(2)  # "sys.exit" bricht das Programm mit einem anzugebenden Fehler-
# code ab. In diesem Fall 2 (für "unsachgemäße Verwendung").
d2 = datetime.strptime("10.09.2007", "%d.%m.%Y")  # "Stunde Null" des
# Unionskalenders.
diff=(d1 - d2).days  # Eigentliche Differenzberechnung.
#
#
## Umrechnung uns Unionsformat ##
union_jahr=int(floor(diff//360))
union_tag=diff%360
#
#
## Berechnung des Standard-Erdformats ##
erde_JAHR=int(d1.strftime('%Y'))  # Auslesen des aktuellen Jahrs ohne Rücksicht
# auf ein mögliches Schaltjahr. "int(·)" erzeugt einen Integer.
erde_TAG=d1.timetuple().tm_yday  # Auslesen des Tag des Jahres.
if isleap(erde_JAHR)==1:  # "erde_JAHR" repräsentiert ein Schaltjahr.
  erde_jahr=str(erde_JAHR)+"*"  # Füge der Jahresangabe einen Stern hinzu.
  if erde_TAG == 60:
    erde_tag=str("59+1")
  elif erde_TAG > 60:
    erde_tag=str(erde_TAG-1)
  else:
    erde_tag=str(erde_TAG)
  tagesanzahl=366
else:  # "erde_JAHR" ist kein Schaltjahr.
  erde_jahr=str(erde_JAHR)  # Kein Stern für die Jahresangabe.
  erde_tag=str(erde_TAG)  # Übernehme den Tag des Jahres ohne Veränderung.
  tagesanzahl=365
#
#
#
### Ausgabe ###
# Die in "data" festgelegten Daten sollen ausgegeben werden.
data = [["Vergangene Tage",str(diff)],  # Nur die vergangenen Tage.
["Vergangene Tage (Zwölfersystem)",str(base10to12(diff,zehn,elf))],  # Die ver-
# gangenen Tage im Zwölfersystem.
["Unionsstandard",str(union_jahr)+"."+str(union_tag)],  # Im Unionsstanard. Der
# 9.10.2007 ist "Stunde Null".
["Unionsstandard (Zwölfersystem)",str(base10to12(union_jahr,zehn,elf))+
"."+str(base10to12(union_tag,zehn,elf))],  # Unionsstandard mit Umrechnung ins
# Zwölfersystem.
["Erdstandard (prä-Gabbot)",d1.strftime('%d.%m.%Y')],
["Erdstandard",str(erde_jahr)+"."+str(erde_tag)],
["Prozent des Jahres abgeschlossen",str(
round(float(erde_TAG)/tagesanzahl*100,2))+"%"]
]
col_width = max(len(word) for row in data for word in row) + 3  # Bestimme die
# Spaltenbreite des längsten Worts.
for row in data:  # Für jede Zeile …
  print("".join(word.ljust(col_width) for word in row))  # … Gib einen String
# aus, der aus den "Wörtern" der Matrix besteht. Zwischen diesen Spalten lasse
# einen Abstand von "col_width".
# Eventuelles TODO: Statt "Text             Wert"
# lieber                  "Text ........... Wert"
