; Input parameters: 
;	- F: 
; Description: 	
;	
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/boards/record_imu_orientation.g"
M118 S{"[IMU] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}
; Checking global variables and input parameters ------------------------------
; Checking for files first
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/variable/save_number.g"} 				E69300
; Checking input parameters
M98 P"/macros/assert/abort_if.g" R{!exists(param.F)} 	Y{"Missing required input parameter F"} F{var.CURRENT_FILE} E69301
M98 P"/macros/assert/abort_if_null.g" R{param.F}  	 Y{"Input parameter F is null"} F{var.CURRENT_FILE} E69302

; Definitions -----------------------------------------------------------------
var SAVE_LOCATION = param.F
var count = 0

; Safe IMU values for all boards with IMU's
while iterations < #boards
	if((boards[iterations].accelerometer != null) && (boards[0].shortName != "EMU_CB-MA"))
		M956 P{boards[iterations].canAddress} S1000 A0 F{var.SAVE_LOCATION^""^boards[iterations].canAddress^".csv"}
		G4 S5


; -----------------------------------------------------------------------------
M118 S{"[IMU] Done "^var.CURRENT_FILE}
M99 ; Proper exit
