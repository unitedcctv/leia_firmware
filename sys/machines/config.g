; Description: 	
; 	Generic configuration file. It will take care of calling the proper config
;	file depending on the machine type.
; Machines available:
;	- EMULATOR_VIIO_V0:
; 		Emulator machine with no expansion boards. All the sensors are emulated
;		and the motors will not really move. For more information refeer to:
;			/sys/machines/emulator/v0/config.g
;	- VIIO_V0:
;		This version supports most of the modules (not FHX) and it should only
;		be used in the alpha machine. For more information refeer to:
;			/sys/machines/viio/v0/config.g
;	- VIIO_V1:
;		This version supports most of the modules (not FHX). X axis needs 2 
;		endstops. For more information refeer to:
;			/sys/machines/viio/v1/config.g
;	- VIIO_V2:
;		This version supports most of the modules with FHX. X axis needs only 
;		1 endstop. For more information refeer to:
;			/sys/machines/viio/v2/config.g
;------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/machines/config.g"

; Let's make sure Daemon is not working ---------------------------------------
if(!exists(global.daemonStop))
	global daemonStop = true
set global.daemonStop = true

global errorMessage = ""
global errorRestartRequired = false
set global.hmiStateDetail = "board_configuring"

; Definitions -----------------------------------------------------------------
var UPDATE_READY_FILE = "/sys/machines/update_ready.g"

; 1. Enable the Logs ----------------------------------------------------------
M98 P"/sys/modules/logs/generic/v0/config.g"

; 2. Checking if an update is pending -----------------------------------------
M98 P"/macros/machine/update/is_waiting_state.g"

; 4. Get Machine Type ---------------------------------------------------------
M98 P"/macros/machine/version/get.g"
; 5. Loading serial number -------------------------
M98 P"/macros/machine/serial_number/get.g"
; 6. Load FW configuration version -------------------------------------------
M98 P"/sys/modules/version/config.g"

; 7. Checking the bootloader and FW versions ----------------------------------
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/machine/firmware/abort_if_wrong_version.g"} F{var.CURRENT_FILE} E29000
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/machine/bootloader/abort_if_wrong_version.g"} F{var.CURRENT_FILE} E29001
G4 S2 ; Making sure all the boards are connected
M98 P"/macros/machine/bootloader/abort_if_wrong_version.g"
M98 P"/macros/machine/firmware/abort_if_wrong_version.g"
;; Configuring variable for power failure call
global powerFailure = false
if(fileexists("/sys/resurrect.g"))
	set global.powerFailure = true
M400
; Configuring steps for print recovery from power failure
M911 S22 P"M913 X0 Y0 Z0" ;set the power failure voltage to 22, and currents of the axes to 0 
; 8. Set the proper configuration depending on the machine type ---------------
var machineConfigFile = "/sys/machines/viio/v2/config.g"	; Default value 
if(global.MACHINE_VERSION == "VIIO_V2")	
	set var.machineConfigFile = "/sys/machines/viio/v2/config.g"			; VIIO 			| v2
elif(global.MACHINE_VERSION == "EMULATOR_VIIO_V0")
	set var.machineConfigFile = "/sys/machines/emulator/v0/config.g"		; Emulator VIIO	| v0	

M550 P{global.MACHINE_VERSION}		; set printer name
M98 P"/macros/assert/result.g" R{result} Y"Unable to set the printer name" F{var.CURRENT_FILE} E29002

; Check if the machine is supported and if the configuration file is available
M98 P"/macros/assert/abort_if_file_missing.g" R{var.machineConfigFile} F{var.CURRENT_FILE} E29003
; Calling the configuration file
M98 P{var.machineConfigFile}
if(global.MACHINE_VERSION == "")
	M118 S{"Set the machine config to the default version VIIO_V2 as the global.MACHINE_VERSION is "^global.MACHINE_VERSION}
	M98 P"/macros/report/warning.g" Y"Please verify the machine version is correct" F{var.CURRENT_FILE} W29000
; Enable Daemon
set global.daemonStop = false	
set global.hmiStateDetail = "board_configured"
; -----------------------------------------------------------------------------
M118 S{"[CONFIG] Done configuration of: "^global.MACHINE_VERSION}
M118 S{"[CONFIG] Done "^var.CURRENT_FILE}
M99