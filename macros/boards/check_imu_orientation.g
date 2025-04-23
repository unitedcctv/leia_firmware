; Description: 	
;	Check current IMU's gravity vector to reference gravity vector to check if 
; 	printer still leveled
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/boards/check_imu_orientation.g"
M118 S{"[IMU] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}
; Checking global variables and input parameters ------------------------------
; Checking for files first
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/boards/record_imu_orientation.g"} 				E69308

; Definitions -----------------------------------------------------------------
var folderLocations = ""
var fileLocation = "0:/sys/accelerometer/"^+state.time^"/"
; (!) This path is shared between others xy_calibration g-codes
if(boards[0].shortName = "EMU_CB-MA")
	set var.folderLocations = "0:/macros/boards/emulation_files/reference/,0:/macros/boards/emulation_files/tilted/" ; Path where the files are saved
else
	set var.folderLocations = "0:/sys/imu_reference/,"^var.fileLocation ; Path where the files are saved
var MAX_DEVIATION = 0.005												; [] Max deviation of tilt 
 
; Load the reference gravity vector
;M98 P"/macros/variable/load.g" N{"reference_gravity_vectors"} 
;M98 P"/macros/assert/abort_if.g" R{!exists(global.savedValue)} Y{"Missing required global savedValue"}  					 F{var.CURRENT_FILE} E69310
;M98 P"/macros/assert/abort_if_null.g" R{global.savedValue}     Y{"Calibration variable not found: reference_gravity_vectors"} F{var.CURRENT_FILE} E69311
;var REFERENCE_GRAVITY_VECTORS = global.savedValue

; Take measurements of IMU's --------------------------------------------------
M98 P"/macros/boards/record_imu_orientation.g" F{var.fileLocation}
G4 S5 
; Call HMI-Server to calculate gravity vectors and store them -----------------
M118 S{"[IMU] Calling HMI-Server to execute gravity vector calculation for measurement: "^var.folderLocations}
M98 P"/macros/python/call_function.g" N"IMU_LEVEL" F{var.folderLocations}
M98 P"/macros/assert/abort_if.g" R{!exists(global.pythonResult)} Y{"Missing required global pythonResult"}  F{var.CURRENT_FILE} E69312
M98 P"/macros/assert/abort_if_null.g" R{global.pythonResult}  	 Y{"No answer from Python"} 				F{var.CURRENT_FILE} E69313

; Load results ----------------------------------------------------------------
M98 P"/macros/variable/load.g" N{"gravity_vector_dev"} 
M98 P"/macros/assert/abort_if.g" R{!exists(global.savedValue)} Y{"Missing required global savedValue"}  					 F{var.CURRENT_FILE} E69314
M98 P"/macros/assert/abort_if_null.g" R{global.savedValue}     Y{"Calibration variable not found: gravity_vectors"} F{var.CURRENT_FILE} E69315
var G_VECTOR_DEVIATION = global.savedValue

; Check if orientation is within threshold ------------------------------------
var count = 0
while( #var.G_VECTOR_DEVIATION > var.count )
	; Dont abort for the moment, just output a message
	;M98 P"/macros/assert/abort_if.g" R{var.G_VECTOR_DEVIATION[var.count] > var.MAX_DEVIATION} 	Y{"Deviation of "^var.G_VECTOR_DEVIATION[var.count]^" is to big"} F{var.CURRENT_FILE} E69316
	if ( var.G_VECTOR_DEVIATION[var.count] > var.MAX_DEVIATION )
		M118 S{"[IMU] Deviation of "^var.G_VECTOR_DEVIATION[var.count]^" is to big"}
	set var.count = var.count + 1

; Check if stage is tilted
M98 P"/macros/variable/load.g" N{"stage_tilted"} 
M98 P"/macros/assert/abort_if.g" R{!exists(global.savedValue)} Y{"Missing required global savedValue"}  					 F{var.CURRENT_FILE} E69317
M98 P"/macros/assert/abort_if_null.g" R{global.savedValue}     Y{"Calibration variable not found: stage_tilted"} F{var.CURRENT_FILE} E69318
if( global.savedValue == 1 )
	M118 S{"[IMU] Looks like the stage is tilted!"}
else
	M118 S{"[IMU] Stage not tilted"}


M118 S{"------------------------------------------------------------------------------"}
M118 S{"[IMU] Deviation of g-vectors: "^var.G_VECTOR_DEVIATION}
M118 S{"------------------------------------------------------------------------------"}
; -----------------------------------------------------------------------------
M118 S{"[IMU] Done "^var.CURRENT_FILE}
M99 ; Proper exit