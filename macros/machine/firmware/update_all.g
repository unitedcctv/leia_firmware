; This file was auto-generated.
; The FW version to update is "3.6.0.3"
;
; Description:
;   This GCode can be used to update the Firmware in all the boards that the
;	firmware version is not matching.
;	(!) NOTE:to restart the board after the update you need to pass param R1 
;	M98 P"/macros/firmware/update_all.g" R1; to restart
;	M98 P"/macros/firmware/update_all.g" R0; not to restart
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/machine/firmware/update_all.g"

; Put the machine in a safe state before updating.
M118 P3 S"Updating Firmware started. Turning everything off."

M98 P"/macros/report/event.g" Y{"Start updating firmware"}  F{var.CURRENT_FILE} V62300

; Set the flag to disable / enable the restart boards after update---------------
var restart = true
if(exists(param.R) && (param.R == 0))
	set var.restart = false
	M118 S{"Skipping restart boards after FW update"}

while true
	if iterations >= #boards
		break
	if iterations != 0
		var FIRMWARE_IN_BOARD = {""^boards[iterations].firmwareVersion}
		if( var.FIRMWARE_IN_BOARD != "3.6.0.3" )
			M98 P"/macros/report/event.g" Y{"Updating firmware in board with address "^boards[iterations].canAddress}  F{var.CURRENT_FILE} V62301
			M997 B{boards[iterations].canAddress}
			G4 S3
		else
			M118 S{"Board with address "^boards[iterations].canAddress^" has the proper FW version"}

var FIRMWARE_IN_MAINBOARD = {""^boards[0].firmwareVersion}
if( var.FIRMWARE_IN_MAINBOARD != "3.6.0.3" )
	M98 P"/macros/report/event.g" Y{"Restarting to update the firmware in the main-board"}  F{var.CURRENT_FILE} V62302
	M118 P3 S"Updating XBoard in 3 Secs"
	G4 S3
	M997 B0
else
	M118 S{"Mainboard has the proper FW version"}
	if(var.restart)
		M98 P"/macros/report/event.g" Y{"Restarting after updating the firmware in some boards."}  F{var.CURRENT_FILE} V62303
		G4 S3
		M999
M99