; This file was auto-generated.
; The FW version to update is "3.6.0.3"
;
; Description:
;   This GCode can be used to update the Firmware in all the boards that the
;	bootloader version is not matching.
;	(!) NOTE:to restart the board after the update you need to pass param R1 
;	M98 P"/macros/machine/bootloader/update_all.g" R1 to restart
;	M98 P"/macros/machine/bootloader/update_all.g" R0 not to restart
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/machine/bootloader/update_all.g"

; Notification that we will start updating the boards -------------------------
M98 P"/macros/report/event.g" Y{"Start updating bootloader"}  F{var.CURRENT_FILE} V62300
G4 S1

; Setting the reset boards flag------------------------------------------------
var restart = true
if(exists(param.R) && (param.R == 0))
	set var.restart = false
	M118 S{"Skipping restart after Bootloader update"}

; Start the loop to check and update the bootloader ---------------------------
while true
	if (iterations >= #boards)
		break
	if (iterations == 0)
		continue
	if( !exists(boards[iterations].bootloaderVersion) )
		M98 P"/macros/report/warning.g" Y{"Missing boards["^iterations^"].bootloaderVersion, it may need a firmware update first."} F{var.CURRENT_FILE} W62311
		continue
	var BOOTLOADER_IN_BOARD = {""^boards[iterations].bootloaderVersion}
	if( var.BOOTLOADER_IN_BOARD != "3.6.0.3" )
		M98 P"/macros/report/event.g" Y{"Updating bootloader in board with address "^boards[iterations].canAddress}  F{var.CURRENT_FILE} V62311
		M997 B{boards[iterations].canAddress} S3
		G4 S3
	else
		M118 S{"Board with address "^boards[iterations].canAddress^" has the proper bootloader version"}

; Restarting the mainboard ----------------------------------------------------
if(var.restart)
	M98 P"/macros/report/event.g" Y{"Restarting after updating the bootloader in some boards."}  F{var.CURRENT_FILE} V62312
	G4 S3
	M999
M99
