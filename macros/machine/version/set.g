; Description: 		
;	We will set the machine version id in the microcontroller flash.
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
; Input Parameters:
;	- V : Machine version name.
; Example:
;	M98 P"/macros/machine/version/set.g" V"EMULATOR_VIIO_V0"
;------------------------------------------------------------------------------
var CURRENT_FILE 	= "/macros/machine/version/set.g"
M118 S{"[MACHINE] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking if the machine version is supported in the OM
M98 P"/macros/assert/abort_if.g" 	  R{!exists(state.machineVersion)} 		Y{"Missing machineVersion in the object model"}  	F{var.CURRENT_FILE} E62000
; Checking global variables
M98 P"/macros/assert/abort_if.g" 	  R{!exists(param.V)}  	Y{"Missing parameter V"}  			F{var.CURRENT_FILE} E62001
M98 P"/macros/assert/abort_if_null.g" R{param.V}  			Y{"Input parameter V is null"}  	F{var.CURRENT_FILE} E62002
M98 P"/macros/assert/abort_if.g" 	  R{(param.V == "")}  	Y{"Parameter V is empty"}  			F{var.CURRENT_FILE} E62003

; Getting the code ------------------------------------------------------------
var machineCode = 0	; Not valid 
if(param.V == "VIIO_V0")
	set var.machineCode = 0xFFED
elif(param.V == "VIIO_V1")
	set var.machineCode = 0xFFDD
elif(param.V == "VIIO_V2")
	set var.machineCode = 0xFFCD
elif(param.V == "EMULATOR_VIIO_V0")
	set var.machineCode = 0xFFEC
; Checking if there was no change
M98 P"/macros/assert/abort_if.g" R{(var.machineCode == 0)}	Y{"Machine not supported"}  F{var.CURRENT_FILE} E62010

; Saving the value in flash ---------------------------------------------------
M900 C{var.machineCode}

; Report the machine update as an event.
M98 P"/macros/report/event.g"   Y{"Machine version updated with code: %s"} A{var.machineCode,}  F{var.CURRENT_FILE} V62000
M98 P"/macros/report/warning.g" Y{"Reset the machine to reload the value and the configuration"}  F{var.CURRENT_FILE} W62000

;------------------------------------------------------------------------------
M118 S{"[MACHINE] Done "^var.CURRENT_FILE}
M99 ; Proper exit