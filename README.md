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

## Kurzanleitung - Installation in 7 Schritten
1. In der Google Developer Console (http://console.developers.google.com) die Google Drive API aktivieren und dazu einen OAuth 2.0 Client (Web-Applikation) anlegen um  `client ID` und `client secret` Schlüssel zu bekommen.
2. TCL-Skript öffnen und als Werte für die Parameter `google_client_id` und `google_client_secret` die Werte des OAuth 2.0 Clients setzen.
2. TCL-Skript in ein Verzeichnis auf die Homematic CCU2 hochladen (bspw. `/usr/local/gdrive`) und Verzeichnis + TCL-Skript mit folgenden Berechtigungen versehen (`CHMOD`): **755**
3. Mit PuTTY auf die Homematic CCU2 einloggen, in das Verzeichnis (`/usr/local/gdrive`) des TCL-Skriptes wechseln und dann folgenden Befehl ausführen (Parameter `-dc` am Ende):
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
}
```
**Wichtig in dieser Ausgabe sind folgende Werte:** `device_code` **und** `user_code`**!**

4. Den `device_code` kopieren und in das TCL-Skript als Wert für den Parameter `homematic_device_code` setzen (Speichern und erneut auf die CCU2 hochladen nicht vergessen). 
5. Die Seite https://www.google.com/device aufrufen, dort den `user_code` eingeben und dann bestätigen, dass man das Gerät (=unsere Homematic CCU2) mit dem Google Account verbinden möchte.
6. Erneut mit PuTTY auf der Homematic CCU2 das TCL-Skript ausführen - diesmal mit folgendem Parameter (`-rt`):
```
# tclsh ./gdrive_backup.tcl -rt
```
Nun bekommen wir in der Response einen Access-Token sowie einen Refresh-Token: 
```
Response: {
 "access_token": "ya29.Glv2BB6oYsGW9BTmoL1YTCUrxuSCfbX6dUK5IbYX4YCWfpNR5uRSP6XU5zaFcBm9lwxVmUGH0lJ-5GKRzrOS3-zTNxHVz2OJYOVPyIlUBcaCeA7Zo65x0k2SxvEu",
 "token_type": "Bearer",
 "expires_in": 3600,
 "refresh_token": "1/MEV6TlU_Hh8NJMjxNUP9MjXOcyOk0m9EqZVBwjtJip4"
}
```
**Wichtig in dieser Ausgabe ist der Wert für:** `refresh_token`**!**
Diesen kopieren wir wieder und setzen ihn im TCL-Skript als Wert der Variablen `google_refresh_token`. Erneut Speichern und auf die Homematic CCU2 hochladen.

7. Sollen die Backups in einem bestimmten Unterordner auf Google Drive landen (also nicht im Root-Verzeichnis), benötigen wir noch den Ordnernamen. Dazu loggen wir uns in Google Drive ein, navigieren zum gewünschten Ordner und kopieren uns den Namen aus der URL-Browserleiste. Eingefügt wird der Name (bzw. die kryptische Zeichenkette) in das TCL-Skript als Wert der Variablen `google_drive_backup_folder`.

**Nun haben wir alle erforderlichen Parameter für ein erfolgreiches Backup von der Homematic CCU2 gesammelt und in dem TCL-Skript zur Verfügung.** Wie man das Skript ausführt und welche Einstellungen man treffen kann, steht im Kapitel "Einrichten des Backups auf der CCU2".

## Schritt-für-Schritt Anleitung
In diesem Abschnitt wird die Installation im Detail und mit Bildern ausführlich erklärt. Im Gegensatz zum Kapitel "Kurzanleitung" richtet sich dieser Abschnitt an Nutzer, die nicht im Detail mit den Systemen vertraut sind. 

###  Google Developer Console
**_Text nochmal überarbeiten_**

Zuerst werden die Voraussetzungen geschaffen, dass man sich bei Google Drive authentifizieren kann um dessen API zu verwenden. Die Authentifizierung erfolgt über das OAuth Verfahren, bei dem man sich mit einer Client-Id und einem geheimen "Client-Secret" Schlüssel bei der Google Drive API anmelden muss. Hat man die Schlüssel erzeugt ist das weitere Vorgehen wie folgt: Von dem Gerät, von dem aus man den Zugang zur Google Drive API benötigt (in unserem Fall die Homematic CCU2), wird ein spezieller Webservice aufgerufen, als Parameter werden die OAuth Schlüssel übergeben. Die Antwort enthält wiederum einen eindeutigen Geräteschlüssel und einen Geräte-Code, mit dem man sich einmalig manuell bei Google das Gerät freischalten lassen muss. Danach erfolgt ein einmaliger Aufruf eines anderen Webservices, welcher einen s.g. Access-Token und - viel wichtiger - einen Refresh-Token mitliefert. Letzterer ist wichtig, da der Access-Token nur immer 60 Minuten (3600 Sekunden) gültig ist. Mit dem Refresh-Token lässt sich dann ein neuer Access-Token generieren.

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

Der aktuelle Benutzer ist jetzt für die Google Drive API freigeschalten, kann sie aber noch nicht verwenden.

#### Schritt 4: Google Drive API Authentifizierung ####
Um die soeben aktivierte API auch verwenden zu können, muss man sich an der API authentifizieren. Dazu werden `Credentials` (Anmeldeinformationen) benötigt, welche sich auf der Übersichtsseite über die entsprechenden Link anlegen lassen.

<img src="https://user-images.githubusercontent.com/26480749/32270533-90ec3806-bef6-11e7-8c0e-ac7284b14968.jpg" border="0">

Beim Anlegen der neuen `Credentials` entscheiden wir uns für den Punkt `OAuth client ID`:

<img src="https://user-images.githubusercontent.com/26480749/32270536-91323a86-bef6-11e7-90aa-dc04ea478fe1.jpg" border="0">

Bevor wir nun aber eine neue **client ID** anlegen können, werden wir aufgefordert, den `Consent screen` zu konfigurieren. Hierbei handelt es sich um einige Angaben, die für die OAuth 2.0 Zertifizierung benötigt werden. Also klicken wir auf den entsprechenden Knopf `Configure consent screen`: 

<img src="https://user-images.githubusercontent.com/26480749/32270537-91525d2a-bef6-11e7-9434-d4980764ce33.jpg" border="0">

Viele Felder sind optional und für unsere Zwecke auch nicht relevant, allerdings sind Email-Adresse und Produktname obligatorisch. Da die Email-Adresse bereits voreingestellt ist, vergeben wir folgenden Namen bei `Product name shown to users`: **Homematic Backup**

<img src="https://user-images.githubusercontent.com/26480749/32270539-91a67130-bef6-11e7-8f9e-46209e95a5a5.jpg" border="0">

Nachdem wir unsere Einstellungen gespeichert haben, wird uns wieder die vorherige Ansicht angezeigt, allerdings können wir nun einen `Application type` auswählen. Für unsere Zwecke selektieren wir hier den Wert **Other** und vergeben noch einen Namen: **cURL Client Homematic CCU2**

<img src="https://user-images.githubusercontent.com/26480749/32324855-0727ea02-bfcd-11e7-8c13-cb063ffd7d93.jpg" border="0">

Sobald wir nun auf `Create` klicken und uns die Anmeldeinformationen erzeugen lassen, werden diese danach in einem Popup angezeigt:

<img src="https://user-images.githubusercontent.com/26480749/32324857-07814e4e-bfcd-11e7-9914-057176c6bf4b.jpg" border="0">

Die beiden Werte für `client ID` und `client secret` sind nun **wichtig** für uns. Diese müssen wir uns kopieren, da wir sie gleich in das TCL-Skript einfügen werden:
> **client ID:** 346571031919-348lfri1vqsl1dfc0krt4mocpurevd8o.apps.googleusercontent.com

> **client secret:** 133nRfGrMOV6Cqg8OKIjctdw

An dieser Stelle ist die Konfiguration in der Google Developer Console abgeschlossen.

#### Schritt 5: TCL-Skript anpassen und auf die CCU2 hochladen ####
Nachdem wir durch den vorherigen Schritt `client ID` und `client secret` verfügbar haben, müssen wir diese in das TCL-Skript an passender Stelle einfügen. Daher öffnen wir das TCL-Skript **`gdrive_backup.tcl`** mit einem Editor und setzen die `client ID` als Wert für den Parameter `google_client_id` und  `client secret` als Wert für Parameter `google_client_secret` . Das sollte dann so aussehen:

<img src="https://user-images.githubusercontent.com/26480749/32325378-07f6fe3a-bfcf-11e7-9cdd-bb557f003a8f.JPG" border="0">

Nachdem wir die Änderungen gespeichert haben, laden wir das Skript per FTP auf die Homematic CCU2 in ein eigenes Verzeichnis (bspw. `/usr/local/gdrive`) hoch. Im FTP Programm setzen wir gleich auch noch die richtigen Dateizugriffsrechte für das (neue) Verzeichnis und das TCL-Skript. Beide müssen den Wert **755** bekommen:
<img src="https://user-images.githubusercontent.com/26480749/32325633-0db1e550-bfd0-11e7-877c-dadf6140cd29.JPG" border="0">

Im nächsten Schritt führen wir das Skript aus um weitere, erforderliche Informationen zu bekommen.

#### Schritt 6: Geräte-Code anfordern und Gerät bestätigen ####
Mit den beiden gesetzten Werten für `google_client_id` und `google_client_secret` können wir **von** unserer Homematic CCU2 einen Google Drive Webservice aufrufen, der uns für unser Gerät (also unsere Homematic CCU2) eine eindeutige Geräte-Id erzeugt und einen Geräte-Code zurückliefert. Die Geräte-Id wird später ebenfalls im TCL-Script benötigt und mit dem Geräte-Code müssen wir unser "Produkt" (der Name aus dem `Consent Screen` - siehe Schritt 4) einmalig manuell über Google's Device Webseite freischalten! Aber auch hier der Reihe nach:
Zuerst loggen wir uns mit PuTTY auf unsere Homematic CCU2 ein. Der Benutzer sollte am besten Root-Rechte besitzen. Wir wechseln in das Verzeichnis mit dem TCL-Skript und führen es mit folgenden Parametern aus (`-dc` am Ende):
```
# tclsh ./gdrive_backup.tcl -dc
```
Nun bekommen wir als Antwort eine Ausgabe angezeigt, die wie folgt aussieht:
<img src="https://user-images.githubusercontent.com/26480749/32325994-8efc2732-bfd1-11e7-9b90-7936b64b297f.jpg" border="0">

> `device_code`: AH-1Ng3QdrBUIak8yvgv48SAtyHigqf3GaO0rSasBfJpPbN0LOXY8ErDmi_jg_mW9CiRC9e3ZQxz1TKYYp7N8z4uj44haA2Hvw
> `user_code`: NDFM-BVPP

**Wichtig sind an dieser Stelle der `device_code` und der `user_code`!** 
Den `user_code` kopieren wir uns und rufen folgende Webseite im Browser auf: https://www.google.com/device (das ist übrigens die `verification_url` die auch in der Antwort mitgeschickt wird) Dort geben wir den Wert aus `user_code` ein und bestätigen, dass wir unser "Produkt" freischalten möchten:
<table>
 <tr>
   <td width="50%">Eingabe des User-Codes:
<img src="https://user-images.githubusercontent.com/26480749/32326253-7bbca15a-bfd2-11e7-9b5d-f5b2f887cde6.jpg" border="0">
    </td>
  <td width="50%">Bestätigen:
   <img src="https://user-images.githubusercontent.com/26480749/32326255-7be36934-bfd2-11e7-9b07-90da9e44056f.jpg" border="0">
  </td>
 </tr>
 </table>
 
Den `device_code` kopieren wir uns ebenfalls. Nun öffnen wir im FTP-Programm auf der Homematic CCU2 das TCL-Skript und fügen den Wert als Wert für den Parameter `homematic_device_code` ein:
   <img src="https://user-images.githubusercontent.com/26480749/32326612-c6f4327c-bfd3-11e7-9e30-516662949f23.JPG" border="0">
Die Änderung speichern und das FTP-Programm sollte die Datei automatisch wieder hochladen.

#### Schritt 7: Refresh-Token anfordern ####
Mit der Angabe des `homematic_device_code` im TCL-Skript sind wir nun in der Lage, uns einen so genannten Access-Token für die Google Drive API zu holen, der uns den Zugriff erlaubt. Allerdings ist so ein Access-Token nur jeweils 60 Minuten gültig (3600 Sekunden), danach müsste die ganze Prozedur wiederholt werden. Daher sendet aber Google einen weiteren Token mit, den **Refresh-Token**. Mit ihm ist es möglich, jederzeit einen weiteren Access-Token anzufordern, ohne eben alle 60 Minuten komplett die Schritte 4 bis 6 zu wiederholen. Der Refresh-Token behält seine Gültigkeit, kann aber auch nur dazu genutzt werden, um einen neuen Access-Token zu ermitteln.
Fordern wir uns also unseren **Refresh-Token** an! Dazu wechseln wir wieder in die PuTTY Konsole und rufen unser TCL-Skript erneut auf, diesmal aber mit dem Parameter `-rt` am Ende:
```
# tclsh ./gdrive_backup.tcl -rt
```
Als Antwort bekommen wir nun folgende Ausgabe:
<img src="https://user-images.githubusercontent.com/26480749/32327342-7479f79a-bfd6-11e7-911b-abe1b066202f.jpg" border="0">
> `refresh_token`: 1/dZkonXUfO75ASOhgZdpt5urYH0rK2cvKTC70v_5sAOE

Hier erhalten wir nun auch unseren `refresh_token`, welcher als letzter Parameter für unser Backup-Skript benötigt wird. Auch diesen Wert kopieren wir uns und öffnen erneut das TCL-Skript im FTP-Programm auf unserer Homematic CCU2. Der Refresh-Token wird nun als Wert für den Parameter `google_refresh_token` gesetzt:
<img src="https://user-images.githubusercontent.com/26480749/32327527-216e2962-bfd7-11e7-8816-4ab99ff684c6.jpg" border="0">

**Nachdem die Datei gespeichert und wieder auf die Homematic CCU2 hochgeladen wurde, ist unser Backup-Script einsatzbereit! :-)** Bevor wir aber damit beginnen, wie man das Skript ausführt und welche zusätzlichen Parameter man noch setzen kann, widmen wir uns kurz noch Google Drive selbst. Dort werden wir noch einen Ordner erstellen, indem die Backups landen sollen. 


### Google Drive Einrichten ###
Nachdem wir nun mühsam alle Parameter für ein erfolgreiches Backup ermittelt haben und auch schon alles einsatzbereit ist, fiel dem ein oder anderen im TCL-Skript vielleicht auf, dass es noch einen Parameter `google_drive_backup_folder` gibt. Dieser Parameter kann auf einen beliebigen Ordner in Google Drive verweisen, in den die Backups letztendlich gespeichert werden. **Wird der Parameter nicht gesetzt, landen alle Backups im Root-Verzeichnis!**
Wir loggen uns also in Google Drive ein: https://drive.google.com und legen einen neuen Ordner **Homematic Backup** an.
<table>
 <tr>
   <td width="33%">Google Drive Dashboard:
<img src="https://user-images.githubusercontent.com/26480749/32328441-493302f8-bfda-11e7-9241-66cfd427091b.JPG" border="0">
    </td>
  <td width="33%">Ordner anlegen:
   <img src="https://user-images.githubusercontent.com/26480749/32328442-499bc8d8-bfda-11e7-8293-df80f824d627.JPG" border="0">
  </td>
  <td width="33%">Ordnername auslesen:
   <img src="https://user-images.githubusercontent.com/26480749/32328443-49caf7a2-bfda-11e7-95a1-7f46b73f4160.JPG" border="0">
  </td> 
 </tr>
 </table>

Der interne Name des neu angelegten Ordners ist (Bild rechts): **`0BwzYy3i2kz8ZdmJkUWVPaDRNb0E`**. Wenn wir diese Zeichenkette noch kopieren und in das TCL-Skript als Wert für `google_drive_backup_folder` setzen, haben wir wirklich alle Informationen zusammen und können endlich mit dem Einrichten des Backups auf der Homematic CCU2 beginnen:
<img src="https://user-images.githubusercontent.com/26480749/32329045-1b61201a-bfdc-11e7-9e6f-9fb909fe9be3.JPG" border="0">


## Anpassung des Skriptes
Nachdem die Voraussetzungen alle erfüllt sind und wir erfolgreich alle erforderlichen Parameter ermittelt haben, geht es nun an die Einrichtung des Backups. Die Wichtigste Information dabei ist, dass das Skript als Parameter einfach eine kommaseparierte Liste mit allen Dateien übergeben bekommt, die auf Google Drive gespeichert werden sollen:

**Beispiel des Skriptaufrufes auf der Kommandozeile der Homematic CCU2:**
```
# tclsh ./gdrive_backup.tcl /usr/local/logs/logfile.txt,/usr/local/logs/werte.csv,/usr/local/logs/log.txt
``` 

### Backup über Homematic CCU2 Programmverknüpfung ###
Wir loggen uns auf der Weboberfläche unserer Homematic ein und erstellen ein neues Programm (Menü "Programme und Verknüpfungen" -> "Programme & Zentralenverknüpfung"), welches das Homematic Zeitmodul verwendet und jeden Sonntag um 22 Uhr ein Backup starten soll. Zu diesem Zeitpunkt möchten wir die folgenden Dateien auf Google Drive sichern: `/usr/local/logs/temperatur.csv`, `/usr/local/logs/luftfeuchte.log` und `/usr/local/logs/fenster.txt`.

<img src="https://user-images.githubusercontent.com/26480749/32345279-01e14e34-c00a-11e7-80f0-ec5cf807c749.JPG" border="0">

Dazu starten wir ein Skript, verwenden den `system.Exec` Befehl und rufen darin unser TCL-Skript auf: 

```
string stdout;
string stderr;
string backupFiles = "/usr/local/logs/temperatur.csv,
                               /usr/local/logs/luftfeuchte.log,
                               /usr/local/logs/fenster.txt";
system.Exec ("tclsh /usr/local/gdrive/gdrive_backup.tcl "# backupFiles, &stdout, &stderr);
```

### Backup als Cronjob

