; Description: 		
;	We will load the machine serial number using the file loaded from the HMI.
; TODO: 
;	Remove the support to 'setMachineSerialNumber.g' once the file is renamed
;	to 'set_machine_serial_number.g'
;------------------------------------------------------------------------------
var CURRENT_FILE 	= "/macros/machine/serial_number/get.g"
M118 S{"[MACHINE] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking if the machine version is supported in the OM
M98 P"/macros/assert/abort_if.g" 	  R{exists(global.machineSerialNumber)} 		Y{"Missing machineSerialNumber is already loaded"}  	F{var.CURRENT_FILE} E62050

if(fileexists("/sys/set_machine_serial_number.g"))
	M98 P"/sys/set_machine_serial_number.g"
else
	M98 P"/macros/report/warning.g" Y"Missing file to set the machine serial number." F{var.CURRENT_FILE} W62050
	M99 ; Proper exit without aborting

M98 P"/macros/assert/abort_if.g" 	  R{!exists(global.machineSerialNumber)} 		Y{"Unable to load the machineSerialNumber from file"}  	F{var.CURRENT_FILE} E62051
M99 ; Proper exit