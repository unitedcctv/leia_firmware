; Input parameters: 
;	-  
; Description: 	
;	Safe gravity vectors of IMU's of true horizontal orientation of the printer.
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/boards/set_imu_orientation.g"
M118 S{"[IMU] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}
; Checking global variables and input parameters ------------------------------
; Checking for files first
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/boards/record_imu_orientation.g"} 				E69303

; Definitions -----------------------------------------------------------------
var fileLocation = ""
; (!) This path is shared between others xy_calibration g-codes
if(boards[0].shortName = "EMU_CB-MA")
	set var.fileLocation = "0:/macros/boards/emulation_files/reference/" ; Path where the files are saved
else
	set var.fileLocation = "0:/sys/imu_reference/" ; Path where the reference measurement is saved
; Take measurements of IMU's --------------------------------------------------
M98 P"/macros/boards/record_imu_orientation.g" F{var.fileLocation}

; -----------------------------------------------------------------------------
M118 S{"[IMU] Done "^var.CURRENT_FILE}
M99 ; Proper exit