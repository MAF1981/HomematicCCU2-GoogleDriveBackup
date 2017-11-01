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

## Kurzanleitung
1. In Google Developer Console (http://console.developers.google.com) die Google Drive API aktivieren und dazu einen OAuth 2.0 Client (Web-Applikation) anlegen um  `client ID` und `client secret` Schlüssel zu bekommen
2. TCL-Skript öffnen und als Werte für die Parameter `google_client_id` und `google_client_secret` die Werte des OAuth 2.0 Clients setzen.
2. TCL-Skript in ein Verzeichnis auf die Homematic CCU2 hochladen (bspw. `/usr/local/gdrive`) und Verzeichnis + TCL-Skript mit folgenden Berechtigungen versehen (`CHMOD`): **755**
3. Mit PuTTY auf die Homematic CCU2 einloggen, in das Verzeichnis (`/usr/local/gdrive`) des TCL-Skriptes wechseln und dann folgenden Befehl ausführen:
```
# tclsh ./gdrive_backup.tcl -dc
```
Als Ergebnis liefert das Programm folgende Ausgabe:
```
Hole Device-Code + User-Code fuer den Google-Client: 346571031919-q77s2rpk4ntm0s70mdopbjb42t9o7349.apps.googleusercontent.com
Response: {
  "verification_url" : "https://www.google.com/device",
  "expires_in" : 1800,
  "interval" : 5,
  "device_code" : "AH-1Ng2VjTEcdVZAPFQKbKgVB7Iu_Ft4WI2DLlbFHWiE_kOvHoAtvvticYH6LiNqfgVA38Bmkg2kdoQfSR2AQGdZ6eau9JoBRg",
  "user_code" : "TSWS-GDMR"
```
**Wichtig in dieser Ausgabe sind folgende Werte:** `device_code` **und** `user_code`**!**

4. Den `device_code` kopieren und in das TCL-Skript als Wert für den Parameter `homematic_device_code` setzen (speichern und erneut auf die CCU2 hochladen nicht vergessen). 
5. Die Seite https://www.google.com/device aufrufen, dort den `user_code` eingeben und dann bestätigen, dass man das Gerät (`device_code`) mit dem Google Account verbinden möchte.
6. Erneut mit PuTTY auf der Homematic CCU2 das TCL-Skript ausführen - diesmal mit folgendem Parameter:
```
# tclsh ./gdrive_backup.tcl -rt
```
Nun bekommen wir in der Response einen Access-Token sowie einen Refresh-Token. Der **`refresh_token`** ist dabei wichtig! 
```
Response: {
 "access_token": "ya29.Glv2BB6oYsGW9BTmoL1YTCUrxuSCfbX6dUK5IbYX4YCWfpNR5uRSP6XU5zaFcBm9lwxVmUGH0lJ-5GKRzrOS3-zTNxHVz2OJYOVPyIlUBcaCeA7Zo65x0k2SxvEu",
 "token_type": "Bearer",
 "expires_in": 3600,
 "refresh_token": "1/MEV6TlU_Hh8NJMjxNUP9MjXOcyOk0m9EqZVBwjtJip4"
}
```
Den Wert des `refresh_token` kopieren wir wieder und setzen ihn im TCL-Skript als Wert der Variablen `google_refresh_token`. Nun haben wir alle erforderlichen Parameter für ein erfolgreiches Backup von der Homematic CCU2.

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

<img src="https://user-images.githubusercontent.com/26480749/32270533-90ec3806-bef6-11e7-8c0e-ac7284b14968.jpg" border="0">

Beim Anlegen der neuen `Credentials` entscheiden wir uns für den Punkt `OAuth client ID`:

<img src="https://user-images.githubusercontent.com/26480749/32270536-91323a86-bef6-11e7-90aa-dc04ea478fe1.jpg" border="0">

Bevor wir nun aber eine neue **client ID** anlegen können, werden wir aufgefordert, den `Consent screen` zu konfigurieren. Hierbei handelt es sich um einige Angaben, die für die OAuth Zertifizierung benötigt werden. Also klicken wir auf den entsprechenden Knopf `Configure consent screen`: 

<img src="https://user-images.githubusercontent.com/26480749/32270537-91525d2a-bef6-11e7-9434-d4980764ce33.jpg" border="0">

Viele Felder sind optional und für unsere Zwecke auch nicht relevant, allerdings ist der Produktname obligatorisch. Da die Email-Adresse bereits voreingestellt ist, vergeben wir folgenden Namen bei `Product name shown to users`: **Homematic Backup**

<img src="https://user-images.githubusercontent.com/26480749/32270539-91a67130-bef6-11e7-8f9e-46209e95a5a5.jpg" border="0">

Nachdem wir unsere Einstellungen gespeichert haben, wird uns wieder die vorherige Ansicht angezeigt, allerdings können wir nun einen `Application type` auswählen. Für unsere Zwecke selektieren wir hier den Wert **Web application** und vergeben noch einen Namen: **Homematic CCU2 Zentrale**

<img src="https://user-images.githubusercontent.com/26480749/32270540-91ca1c7a-bef6-11e7-8a40-9ddf51e97459.jpg" border="0">

Sobald wir nun auf `Create` klicken und uns die Anmeldeinformationen erzeugen lassen, werden diese danach in einem Popup angezeigt:

<img src="https://user-images.githubusercontent.com/26480749/32270524-8f9dafd4-bef6-11e7-9513-5074ba6bb96e.jpg" border="0">

Die beiden Werte für `client ID` und `client secret` sind nun **wichtig** für uns. Diese müssen wir uns kopieren, da wir sie später in das TCL-Skript einfügen werden:
> **client ID:** 346571031919-1ah7notaarq75dalaid32hceb226nl4p.apps.googleusercontent.com
> **client secret:** uXkYrz_oSE-Miptql89ue_8Y

Mit diesen Werten ist es nun möglich über einen Webservice bei Google Drive weitere Informationen anzufordern, die für das TCL-Skript benötigt werden.

#### Schritt 5: Geräte-Code für die CCU2 erzeugen und Geräte bestätigen ####
Nachdem wir `client ID` und `client secret` verfügbar haben, müssen wir damit **von** unserer Homematic CCU2 einen Google Drive Webservice aufrufen, der uns für das Gerät (also unsere Homematic CCU2) eine eindeutige Geräte-Id und einen Gerätecode zurückliefert. Die Geräte-Id benötigen wir später wieder im TCL-Script und mit dem Geräte-Code muss man die Homematic CCU2 einmalig manuell über eine Webseite für die Google Drive API freischalten!



### Google Drive Einrichten ###
Dieses Kapitel dient hautpsächlich dazu, dass das später verwendete Beispiel nachvollziehbar ist/bleibt. Bei der Anpassung des eigentlichen TCL-Skriptes wird sich auf diesen Punkt bezogen. In Google Drive bekommt jeder Ordner eine eindeutige Id zugeordnet, diese wird im TCL-Skript benötigt, wenn man seine Daten in einem bestimmten Unterverzeichnis speichern möchte und nicht alles im Root-Verzeichnis seines Google Drive Accounts liegen haben möchte.

## Anpassung des Skriptes
TODO
