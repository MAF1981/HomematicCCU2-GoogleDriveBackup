#!/bin/tclsh
    load tclrega.so

	# Konfiguration
	set google_client_id ""
	set google_client_secret ""
	set google_refresh_token "";
	set homematic_device_code ""

	#Name des Backup Verzeichnisses (aus URL) unterhalb Google Drive Root
	set google_drive_backup_folder "";
 
	# Liste aller Dateien mit vollstaendiger Pfadangabe, deren Backup auf GoogleDrive gespeichert werden soll.
	# Wenn die Dateiliste dem Programm als argv0 uebergeben wird, kann der Parameter leer bleiben.
	set backupFilesList [list {}]
	
	# Erstellt im oben angegebenen "google_drive_backup_folder" einen zusaetzlichen Unterordner mit dem aktuellen
	# Backup Datum als Namen (Format: YYYY-MM-DD) und laed alle Dateien aus "backupFilesList" in diesen Ordner
	set createDatetimeFolderInBackupFolder 1
	
	#############################################################################
	#############################################################################
	################# ! AB HIER KEINE ANPASSUNGEN MEHR NOETIG ! #################
	#############################################################################
	#############################################################################

	# Datei in die der aktuelle Access-Token gespeichert wird
	set currentDirectory [file dirname [info script]]
	set accessTokenFile "$currentDirectory/gdrive_backup.token"
	
	######################################################################
	# Funktion: readAccessToken
	# Liest den aktuellen AccessToken aus der Datei (accessTokenFile)
	# wenn dieser nicht mehr gueltig sein sollte, wird
	# ein neuer angefordert und in die Datei geschrieben.
	# 
	# @PARAM - keine Parameter
	# @RETURN - Aktuellen Access-Token (im Fehlerfall leeren String)
	#
	proc readAccessToken {} {
		global accessTokenFile
		if { [file exists "$accessTokenFile"] == 1 && [file size "$accessTokenFile"] > 0 } {
			set fsize [file size "$accessTokenFile"]
			set fp [open "$accessTokenFile" r]
			set accessToken [read $fp $fsize]
			close $fp
			return $accessToken
		} else {
			return ""
		}
	}
	
	######################################################################
	# Funktion writeAccessToken
	# Schreibt einen neuen AccessToken in die Datei (accessTokenFile),
	# falls die Datei noch nicht existiert, wird sie angelegt.
	# 
	# @PARAM accessToken - Access Token der in die Datei geschrieben wird
	# @RETURN - kein Rueckgabewert
	#
	proc writeAccessToken { accessToken } {
		global accessTokenFile
		set fp [open "$accessTokenFile" w+]
		puts -nonewline $fp $accessToken
		close $fp
	}
	
	######################################################################
	# Funktion: checkAccessToken
	# Es wird ueberprueft, ob der uebergebene Access Token noch gueltig ist,
	# indem eine Abfrage auf das Root Verzeichnis von GoogleDrive gestartet 
	# wird. Bei erfolgreichem Login ist der Token noch valide. Enthaelt die
	# Response einen Fehler, ist anzunehmen, dass der Token abgelaufen ist.
	#
	# @PARAM accessToken - Token der ueberprueft werden soll
	# @RETURN - 1 wenn der Token noch gueltig ist, 0 wenn ungueltig
	#
	proc checkAccessToken { accessToken } {		
		# Alle Parameter mit Werten fuer den cURL Aufruf setzen		
		set curlCommand {}
		lappend curlCommand -H "GData-Version: 3.0"
		lappend curlCommand -H "Authorization: Bearer $accessToken"
		lappend curlCommand "https://www.googleapis.com/drive/v2/files"

		# cURL Command absetzen und Ergebnis holen
		set response [ curlResponse $curlCommand ]

		# Ergebnis auswerten und neuen Access-Token aus Response lesen
		set isError ""
		regexp -linestop {\"error\"} $response isError
		if { [string length $isError] > 0 } {
			# Fehlerfall
			return 0
		} else {
			# Token ist noch gueltig
			return 1
		}
	}	
	
	######################################################################
	# Funktion: getRefreshToken
	# Fordert einen neuen getRefreshToken an.
	#
	# !! Diese Funktion ist fuer die eigentliche Backup-Prozedur nicht relevant
	#
	# @PARAM - keine Parameter
	# @RETURN - Komplette Response
	#
	proc getRefreshToken {} {
		global google_client_id
		global google_client_secret
		global homematic_device_code
		
		if {[string length $google_client_id] == 0
			|| [string length $google_client_secret] == 0
				|| [string length $homematic_device_code] == 0} {
					puts "Fehler! Nicht alle erforderlichen Parameter gesetzt!"
					exit 1
		}
		puts "Anfordern des Refresh-Tokens:"
		set curlCommand "-d client_id=$google_client_id"
		append curlCommand "&client_secret=$google_client_secret"
		append curlCommand "&code=$homematic_device_code"
		append curlCommand "&grant_type=http://oauth.net/grant_type/device/1.0"
		append curlCommand " https://www.googleapis.com/oauth2/v4/token"
		
		# cURL Command absetzen und Ergebnis holen
		set response [ curlResponse $curlCommand ]		
		puts "Response: $response"
	}
	
	######################################################################
	# Funktion: requestDeviceCode
	# Fordert einen neuen requestDeviceCode an.
	#
	# !! Diese Funktion ist fuer die eigentliche Backup-Prozedur nicht relevant
	#
	# @PARAM - keine Parameter
	# @RETURN - Komplette Response
	#
	proc requestDeviceCode {} {
		global google_client_id
		global google_client_secret
		
		puts "Anfordern von Device-Code und User-Code!"
		set curlCommand "-d client_id=$google_client_id"
		append curlCommand "&scope=https://docs.google.com/feeds"
		append curlCommand " https://accounts.google.com/o/oauth2/device/code"
		# cURL Command absetzen und Ergebnis holen
		set response [ curlResponse $curlCommand ]		
		puts "Response: $response"
	}
	
	######################################################################
	# Funktion: refreshAccessToken
	# Fordert ueber die entsprechende Google API einen neuen Access-Token
	# an, wenn der aktuelle nicht mehr gueltig ist. Prueft die Response
	# und ermittelt daraus den Access-Token. Der neue Token wird in die 
	# Datei (accessTokenFile) geschrieben und zusaetzlich von der Funktion
	# zurueckgegeben.
	# 
	# @PARAM - keine Parameter
	# @RETURN - Neuen Access-Token (oder Fehlermeldung)
	#
	proc refreshAccessToken {} {
		# Erforderliche globale Parameter fuer den CURL Request
		global google_client_id
		global google_client_secret
		global google_refresh_token
		
		# Zusammensetzen der Parameter fuer den cURL Aufruf
		set curlCommand "-d client_id=$google_client_id"
		append curlCommand "&client_secret=$google_client_secret"
		append curlCommand "&refresh_token=$google_refresh_token"
		append curlCommand "&grant_type=refresh_token"
		append curlCommand " https://accounts.google.com/o/oauth2/token"
		
		# CURL Command absetzen und Ergebnis holen
		set response [ curlResponse $curlCommand ]
		
		# Ergebnis auswerten und neuen Access-Token aus Response lesen
		regexp -linestop {\"access_token\"\s:\s\"(.*?)\"} $response dummy accessToken
		
		if { [ string length $accessToken ] > 0 } {
			# Neuen Access-Token in die Datei schreiben
			writeAccessToken $accessToken
			return $accessToken
		} else {
			# Fehler! Kein AccessToken in Response verfuegbar?
			puts "Es konnte kein Access-Token aus der Response ermittelt werden! Komplette Response:\n$response"
			return $response
		}
	}
	
	######################################################################
	# Funktion: curlResponse
	# Setzt den CURL Request ab und liefert dessen Antwort zurueck.
	# Ueberspringt die Ueberpruefung des Zertifikates indem immer die
	# Option -k mitgegeben wird. Weitere Informationen zu diesem Punkt
	# gibt es unter: http://curl.haxx.se/docs/sslcerts.html
	# 
	# @PARAM curlCommand - Kompletter CURL Aufruf mit allen Parametern
	# @RETURN - Die Response des cURL Aufrufes
	#
	proc curlResponse { curlCommand } {
		#puts "CURL Command: $curlCommand"
		catch { eval exec /usr/local/addons/cuxd/curl -k $curlCommand } response
		#puts "CURL Response:\n$response"
		return $response	
	}
	
	######################################################################
	# Funktion: createSubfolder
	# Erzeugt ein Unterverzeichnis im angegebenen 'parentFolder' mit dem
	# in 'folderName' spezifizierten Namen.
	# "MimeType: application/vnd.google-apps.folder" muss in den Metadaten
	# angegeben werden, damit es ein Verzeichnis wird.
	# 
	# @PARAM accessToken - Access Token fuer die cURL Verbindung
	# @PARAM parentFolder - ID des Uebergeordneten Verzeichnisses
	# @PARAM folderName - Name des neuen Verzeichnisses
	# @RETURN - Die ID des erzeugten Verzeichnisses
	#	
	proc createSubfolder { accessToken parentFolder folderName} {
		set description "Automatisch erzeugtes Verzeichnis"
		set mimeType "application/vnd.google-apps.folder"
		# Erzeugen der benoetigten Metadaten fuer den Ordner
		set fileMetaData [format \
				{{name : '%s', title : '%s', description : '%s', mimeType : '%s',parents : [{id : '%s'}]}} \
				$folderName $folderName $description $mimeType $parentFolder] 
		# cURL Command mit allen Informationen erzeugen
		set curlCommand {}
		lappend curlCommand -H "GData-Version: 3.0"
		lappend curlCommand -H "Authorization: Bearer $accessToken"
		lappend curlCommand -F "metadata=$fileMetaData;type=application/json;charset=UTF-8"
		lappend curlCommand "https://www.googleapis.com/upload/drive/v2/files"

		# cURL Command absetzen
		set response [ curlResponse $curlCommand ]
		# Erzeugte Folder ID aus der Response ermitteln
		set neueFolderId ""
		regexp -linestop {"id":\s+"(.*?)"} $response dummy neueFolderId
		# Wenn Response einen Fehler enthaelt und neueFolderId in der RegEx nicht existiert, 
		# dann wird ein leerer String zurueckgegeben
		return $neueFolderId
	}
	
	proc checkFiles {} {
		global backupFilesList
		
	}
	
	######################################################################
	# Funktion: doGoogleDriveBackup
	# Laed alle in der Liste (backupFilesList) angegebenen Dateien in das
	# angegebene GoogleDrive Backup Verzeichnis (google_drive_backup_folder).
	# Wurde kein Backup Verzeichnis angegeben, erfolgt der Upload ins Root
	# Verzeichnis von Google Drive.
	# 
	# Verwendete Quellen fuer diese Funktion:
	# https://stackoverflow.com/questions/45878753/upload-zip-file-to-google-drive-using-curl
	# https://stackoverflow.com/questions/12889532/insert-a-file-to-a-particular-folder-using-google-drive-api
	# https://www.hitchhq.com/googledrive/activities/work-with-folders-drive-rest-api-v2-google-developers-57dfb66c7ab5cb2d63b136e3
	# https://github.com/soulseekah/bash-utils/blob/master/google-drive-upload/upload.sh
	# https://stackoverflow.com/questions/47025626/upload-files-to-google-drive-using-tcl-and-curl
	#
	# @PARAM accessToken - Access Token fuer die cURL Verbindung
	# @RETURN - kein Rueckgabewert
	#
	proc doGoogleDriveBackup { accessToken } {
		global backupFilesList
		global google_drive_backup_folder
		global createDatetimeFolderInBackupFolder
		set systemTime [clock seconds]
		set datum [clock format $systemTime -format {%d.%m.%Y %H:%M:%S}]
		
		#Pruefe ob ein zusaetzlicher Unterordner mit dem Zeitstempel als Namen erstellt werden soll
		if {$createDatetimeFolderInBackupFolder == 1} {
			set folderName [clock format $systemTime -format {%Y-%m-%d_%H:%M}]
			set backupfolder [createSubfolder $accessToken $google_drive_backup_folder $folderName]
			if { [string length $backupfolder] == 0} {
				# Konnte aus irgenwelchen Gruenden das Unterverzeichnis nicht erstellt werden, 
				# wird als Speicherort das google_drive_backup_folder verwendet
				set backupfolder $google_drive_backup_folder
			}
		} else {
			# Wenn kein zusaetzlicher Unterordner erstellt werden soll, wird der angegebene Backup-Ordner verwendet
			set backupfolder $google_drive_backup_folder
		}

		# Setze die Beschreibung fuer die Dateien in den Metadaten
		set description "Backup von Homematic CCU2 am $datum"

		# Fuer alle in der Liste angegebenen Dateien...
		foreach backupFile $backupFilesList {
			#Ueberpruefe ob die angegebene Datei existiert
			if { [file exists $backupFile] == 0 || [file isfile $backupFile] == 0} {
				#Datei nicht gefunden, lese naechste Datei...
				puts "Datei $backupFile konnte nicht gefunden werden oder ist keine Datei!"
				continue
			}
			set fileName [file tail $backupFile]

			set fileMetaData [format \
					{{name : '%s', title : '%s', description : '%s', parents : [{id : '%s'}]}} \
					$backupFile $fileName $description $backupfolder] 
			
			set curlCommand {}
			lappend curlCommand -H "GData-Version: 3.0"
			lappend curlCommand -H "Authorization: Bearer $accessToken"
			lappend curlCommand -F "metadata=$fileMetaData;type=application/json;charset=UTF-8"
			lappend curlCommand -F "file=@$backupFile"
			lappend curlCommand "https://www.googleapis.com/upload/drive/v2/files?uploadType=multipart"

			# CURL Command absetzen
			set response [ curlResponse $curlCommand ]
		}
	}

	###### Starte Skript ######
	
	if { $argc == 1 && [lindex $argv 0] == "-dc" } {
			requestDeviceCode
			exit 0
	}
	if { $argc == 1 && [lindex $argv 0] == "-rt" } {
			getRefreshToken
			exit 0
	}

	puts "Google Drive Backup gestartet..."	
	# Holt den aktuellen Access-Token aus der Datei.
	# Falls Datei nicht existiert oder leer ist, ermittele
	# neuen Access-Token und schreibe ihn in Datei
	set currentFileAccessToken [readAccessToken]
	if { [string length "$currentFileAccessToken"] == 0 
		|| [checkAccessToken $currentFileAccessToken] == 0} {
		set currentFileAccessToken [refreshAccessToken]
	}
	
	# Wenn Argumente uebergeben werden, dann werden diese genommen werden anstatt die Angabe der
	# Dateien backupFilesList
	if { $argc == 1 } {
		set argument [lindex $argv 0]
		# Es wurde ein Argument mit den zu sichernden Dateien uebergeben. 
		set backupFilesList [split $argument "," ]		
	} else {
		# Keine Argumente -> verwende die Dateien aus backupFilesList
	}

	doGoogleDriveBackup $currentFileAccessToken
	puts "Google Drive Backup beendet!"
	#getAccessToken
	#createBackup	
	