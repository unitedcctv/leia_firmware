
; Description:
;	This macro records a linear measurement using the ball sensor and saves the results to a CSV file.
;   SAFETY: The macro disregards machine limits so know what you are doing. Only relative moves are used.
;   There is a 3 second grace period to abort the macro before it starts moving.
;   The macro will move the ball sensor to the specified distance in X or Y and up in Z and back.
;
;   It can be used with only door closed, not locked, for easy measurement.
; Parameters:
; 	- D: Distance to measure in mm, positive or negative as array for {X, Y}, e.g. {0, 490}. Both directions are not allowed.
; 	- L: Label for the measurement, will be used in the filename
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/hmi/maintenance/machine/record_linear.g"
M118 S{"[record_linear.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking input parameters ---------------------------------------------------
var MEASURE_MOVE = param.D
var LABEL = param.L

; abort if both directions are used
if (var.MEASURE_MOVE[0] != 0 && var.MEASURE_MOVE[1] != 0)
	M118 S{"[record_linear.g] Both directions are set, exiting"}
	M99

var MEASURE_LENGTH = 0

var axis = ""

if (var.MEASURE_MOVE[0] == 0)
	set var.MEASURE_LENGTH = abs(var.MEASURE_MOVE[1])
	set var.axis = "Y"^var.MEASURE_MOVE[1]
else
	set var.MEASURE_LENGTH = abs(var.MEASURE_MOVE[0])
	set var.axis = "X"^var.MEASURE_MOVE[0]

; Definitions -----------------------------------------------------------------
var SPEED_FAST_MOVE 		= 12000							  	; [mm/min] Fast move speed
var SPEED_MEASUREMENT 		= 3000							   	; [mm/min] Measurement move speed
var SCAN_DISTANCE			= 450									; [mm] Spread range for the scan lines
var SAMPLE_FREQUENCY		= 250								; [1/s] Sample frequency of the ball sensor
var SAMPLES_TO_DISCARD		= 128							; [1] Amount of samples to discard, duet to stream being delayed in FW

var TRAVEL_HEIGHT_Z			= 10									; [mm] Travel height of the Z axis (relative to measurement) when travelling back
var MACHINE_SERIAL = exists(global.machineSerialNumber) ? global.machineSerialNumber : ""

M118 S{"[record_linear.g] LABEL: "^param.L^" S/N: "^var.MACHINE_SERIAL}
; example
; M98 P"/macros/hmi/maintenance/machine/record_linear.g" N"XYZ" M{0, 490}


var FILE_PATH = {"/sys/logs/streamer/"^var.LABEL^"_"^var.axis^".csv"}
M118 S{"[record_linear.g] File: "^var.FILE_PATH}

; Calculate amount of samples needed to measure whole distance-----------------
var AMOUNT_SAMPLES	= ceil((var.MEASURE_LENGTH / (var.SPEED_MEASUREMENT/60)) * var.SAMPLE_FREQUENCY)

if var.AMOUNT_SAMPLES < 1
	M118 S{"[record_linear.g] Measurement distance is too short, exiting"}
	M99


; How much does the correction need to be corrected, based on the discarded samples
var DISCARD_LENGTH   = var.SAMPLES_TO_DISCARD / var.SAMPLE_FREQUENCY * var.SPEED_MEASUREMENT / 60
var DISCARD_TIME_S = var.SAMPLES_TO_DISCARD / var.SAMPLE_FREQUENCY

M118 S{"[record_linear.g] Discarding "^var.SAMPLES_TO_DISCARD^" samples: "^var.DISCARD_LENGTH^" mm"}


M118 S{"[record_linear.g] Measuring "^var.MEASURE_LENGTH^" mm in "^var.AMOUNT_SAMPLES^" samples"}
M118 S{"[record_linear.g] File: "^var.FILE_PATH}

M118 S{"[record_linear.g] SAFETY: 3 seconds to abort, moving without axis limits!!"}
G4 S3
M564 H0 S0

; Deselecting the tool --------------------------------------------------------
if(state.currentTool >= 0)
	T-1
M400

G91 ; relative

; run measurement -------------------------------------------------------------

M400
G4 S{var.DISCARD_TIME_S}
M400
M956 P70.1 S{var.AMOUNT_SAMPLES} Z A1 F{var.FILE_PATH}
G1 X{var.MEASURE_MOVE[0]} Y{var.MEASURE_MOVE[1]} F{var.SPEED_MEASUREMENT}
M400
G4 S{var.DISCARD_TIME_S}
M400

; restore position ------------------------------------------------------------
G1 Z{var.TRAVEL_HEIGHT_Z} F{var.SPEED_FAST_MOVE}
M400
G1 X{-var.MEASURE_MOVE[0]} Y{-var.MEASURE_MOVE[1]} F{var.SPEED_FAST_MOVE}
M400
G1 Z{-var.TRAVEL_HEIGHT_Z} F{var.SPEED_FAST_MOVE}
M400
G90 ; absolute

M564 H1 S1
M400
M118 S{"[record_linear.g] Done "^var.CURRENT_FILE}
M99