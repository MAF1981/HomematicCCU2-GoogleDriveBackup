# HomematicCCU2-GoogleDriveBackup
Zeitgesteuerte Datensicherung von der Homematic CCU2 Zentrale auf einen Google Drive Account.

## Einleitung
Mit diesem Skript lassen sich Daten von einer CCU2 Zentrale des Smart-Home Systems Homematic der Firma eQ-3 auf einem Google Drive Account in der Cloud sichern. Dabei lässt sich das Skript entweder über die Homematic Weboberfläche mittels Programmverknüpfung und dem Zeitmodul steuern oder kann - unabhängig - direkt auch als Cronjob auf der CCU2 laufen. Das TCL-Skript kommt dabei ohne weitere Bibliotheken oder Abhängigkeiten aus. Dies ist insofern interessant, als das die Homematic Zentrale mit der TCL Version 8.2 ausgeliefert wird - das Release-Datum dieser TCL-Version war der 16.12.1999! In dieser Version gab es keinen Support für JSON und auch viele andere Sprachkonstrukte, die das Leben einfacher machen, waren noch nicht implementiert.

 1. Einrichten der Google Developer Console
 2. Einrichten von Google Drive 
 3. Anpassungen im Skript
 4. Einrichten des Backups auf der CCU2

## Voraussetzungen
Folgende Voraussetzungen werden für das Projekt benötigt:
- Google Account
- Die Zentrale des Homematic Smart-Home Systems CCU2 der Firma eQ-3
- Auf der Homematic CCU2 muss das AddOn CUxD (CUx Daemon) installiert sein
- FTP Zugriff auf die Homematic CCU2 (bpsw. FileZilla)
- SSH Zugriff auf die Homematic CCU2 (bspw. PuTTY)

## Schritt-für-Schritt Anleitung
Im Folgenden wird Schrittweise erklärt, welche Einstellungen vorgenommen und welche Parameter gesetzt werden müssen, damit das automatische Backup nach Google Drive funktioniert.

###  Google Developer Console
**_Text nochmal überarbeiten_**

Als erstes werden die Voraussetzungen geschaffen, dass man sich bei Google Drive authentifizieren kann um dessen API zu verwenden. Die Authentifizierung erfolgt über das OAuth Verfahren, bei dem man sich mit einer Client-Id und einem geheimen "Client-Secret" Schlüssel bei der Google Drive API anmelden muss. Hat man die Schlüssel erzeugt ist das weitere Vorgehen wie folgt: Von dem Gerät, von dem aus man den Zugang zur Google Drive API benötigt (in unserem Fall die Homematic CCU2), wird ein spezieller Webservice aufgerufen, als Parameter werden die OAuth Schlüssel übergeben. Die Antwort enthält wiederum einen eindeutigen Geräteschlüssel und einen Geräte-Code, mit dem man sich einmalig manuell bei Google das Gerät freischalten lassen muss. Danach erfolgt ein einmaliger Aufruf eines anderen Webservices, welcher einen s.g. Access-Token und - viel wichtiger - einen Refresh-Token mitliefert. Letzterer ist wichtig, da der Access-Token nur immer 60 Minuten (3600 Sekunden) gültig ist. Mit dem Refresh-Token lässt sich dann ein neuer Access-Token generieren.

Aber der Reihe nach!

#### Schritt 1: Login Developer Console ####
Wir loggen uns mit dem User an der Google Developer Console an, bei dem später das Backup in Google Drive landen soll:
http://console.developers.google.com

<img src="https://user-images.githubusercontent.com/26480749/32270528-902cc228-bef6-11e7-955d-0521f953e6eb.JPG" border="0">

#### Schritt 2: Projekt anlegen ####
Nach dem Login landet man in der Dashboard-Ansicht. Diese ist entweder noch leer oder enthält bereits andere, existierende Projekte des Benutzers. Hier legen wir nun ein (weiteres) neues Projekt an, indem man oben im Menü auf `Select a project` klickt und dann über `Create` ein neues erstellt. Existiert bisher kein Projekt, bekommt man direkt auf der Dashboard Seite schon den Link `Create Project` angezeigt.

<img src="https://user-images.githubusercontent.com/26480749/32270526-8fe480bc-bef6-11e7-9b17-606be833e704.JPG" border="0">

Nun vergeben wir bei `Project name` einen Projektnamen, bspw.: **Homematic CCU2**

<img src="https://user-images.githubusercontent.com/26480749/32270531-90a23db4-bef6-11e7-876f-8faa998c3696.jpg" border="0">

Nachdem das Projekt erfolgreich angelegt wurde, landet man nun auf dessen Übersichtsseite. Da wir unsere Dateien von der CCU2 auf Google Drive sichern möchten, müssen wir uns im nächsten Schritt für die Google Drive API freischalten lassen.

#### Schritt 3: Google Drive API aktivieren ####
Die Google Drive API lässt sich für das Projekt aktivieren, indem man auf der Dashboard-Seite des Projektes über einen der `Library` Links die **Google Drive API** sucht:

<img src="https://user-images.githubusercontent.com/26480749/32270532-90c2a3f6-bef6-11e7-838b-0aadae2b0176.jpg" border="0">

Die API muss nun noch aktiviert werden, indem man auf `Enable` klickt:

<img src="https://user-images.githubusercontent.com/26480749/32270534-9111c1e8-bef6-11e7-8bd8-fbd22d3eab1b.jpg" border="0">

Der aktuelle Benutzer ist jetzt für die Google Drive API freigeschalten und kann sie verwenden.

#### Schritt 4: Google Drive API Authentifizierung ####
Nun ist der Benutzer zwar für die Google Drive API freigeschalten, kann Sie aber noch nicht verwenden, da man sich bei der API authentifizieren muss. Dazu benötigen wir neue `Credentials`, die sich auf der Übersichtsseite über die entsprechenden Links anlegen lassen.


### Google Drive Einrichten ###
Dieses Kapitel dient hautpsächlich dazu, dass das später verwendete Beispiel nachvollziehbar ist/bleibt. Bei der Anpassung des eigentlichen TCL-Skriptes wird sich auf diesen Punkt bezogen. In Google Drive bekommt jeder Ordner eine eindeutige Id zugeordnet, diese wird im TCL-Skript benötigt, wenn man seine Daten in einem bestimmten Unterverzeichnis speichern möchte und nicht alles im Root-Verzeichnis seines Google Drive Accounts liegen haben möchte.

## Anpassung des Skriptes
TODO
