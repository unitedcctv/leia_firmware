; Description: 		
;	We will get the machine version id saved in the microcontroller flash.
; 	The code is codified in a 16 bits:
;		b0: 	1: Real machine | 0: Emulator
;		b3..1:	0: Reserved | 1: Reserved | 2: Reserved | 3: Reserved
;				4: PRO | 5: ONE | 6: VIIO | 7: Reserved
;		b15..4: The version is stored like this: (0xFFE-Version).
;				The values 0x000 and 0xFFF should be avoided.
; 	As an example, the VIIO_V0 is:		 '0xFFED' = '0b 1111 1111 1110 1101'
;					0 = 0xFFE - 0xFFE	----------------||||-||||-||||
;						   0x6 = VIIO	-------------------------------|||
;				   0x1 = Real machine	----------------------------------|
; Output parameters:
;	- global.MACHINE_VERSION : Machine version name.
;------------------------------------------------------------------------------
var CURRENT_FILE 	= "/macros/machine/version/get.g"
M118 S{"[MACHINE] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking if the machine version is supported in the OM
M98 P"/macros/assert/abort_if.g" 	  	R{!exists(state.machineVersion)} 	Y{"Missing machineVersion in the object model"} F{var.CURRENT_FILE} E62020
M98 P"/macros/assert/abort_if_null.g" 	R{state.machineVersion} 			Y{"In OM, machineVersion is null"}  			F{var.CURRENT_FILE} E62021
M98 P"/macros/assert/abort_if.g" 		R{exists(global.MACHINE_VERSION)} 	Y{"Global MACHINE_VERSION already exists. Reset the machine to reload it."}  	F{var.CURRENT_FILE} E62022

; Getting the code ------------------------------------------------------------
var CODE = state.machineVersion	; Not valid 
var machineName = "VIIO_V2"
;if(var.CODE == 0xFFED)
;	set var.machineName = "VIIO_V0"
;elif(var.CODE == 0xFFDD)
;	set var.machineName = "VIIO_V1"
;elif(var.CODE == 0xFFCD)
;	set var.machineName = "VIIO_V2"
if(var.CODE == 0xFFEC)
	set var.machineName = "EMULATOR_VIIO_V0"

if(var.machineName == null)
	M98 P"/macros/report/event.g" Y{ "Missing the machine version. To set it: M98 P""/macros/machine/set_version.g"" V""VIIO_V0""" }  F{var.CURRENT_FILE} V62023
	M98 P"/macros/assert/abort.g" Y{ "Unknown machine version code: %s"} A{var.CODE,}  F{var.CURRENT_FILE} E62023

; Set as global constant variable.
global MACHINE_VERSION = var.machineName

; Report the machine update as an event.
M98 P"/macros/report/event.g" Y{"Machine version detected: %s"} A{global.MACHINE_VERSION,}  F{var.CURRENT_FILE} V62024

;------------------------------------------------------------------------------
M118 S{"[MACHINE] Done "^var.CURRENT_FILE}
M99 ; Proper exit