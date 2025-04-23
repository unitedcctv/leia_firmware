; Description: 
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/xy_calibration/scan.g"
M118 S{"[scan.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}
; Checking global variables and input parameters ------------------------------

; Check machine conditions
var IS_HOMED = (move.axes[0].homed && move.axes[1].homed && move.axes[2].homed)
if !var.IS_HOMED
    M118 S{"[scan.g] Machine is not homed!"}
    M99


; Definitions -----------------------------------------------------------------
var SPEED_FAST_MOVE 		= 3000							  	; [mm/min] Fast move speed
var Z_PROBE_POS 			= global.PROBE_OFFSET_Z				; [mm] Z height for measurement
var Z_SAFE_HEIGHT			= 5									; [mm] Safe height for Z axis
var LIFTING_Z 				= var.Z_PROBE_POS + 1								; lift to this position after measurement
var MARKER_Z_HEIGHT			= var.Z_PROBE_POS + 0.5								; lift by this amount to signal signal change

var BUFFER_SECONDS			= 1									; [s] Buffer time for the filament to cool down
var SAMPLE_FREQUENCY		= 250								; [1/s] Sample frequency of the ball sensor

var SCAN_X_START			= 0		; [mm] Starting position of X line measurement
var SCAN_Y_START			= 0		; [mm] Starting position of Y line measurement

; Calculate amount of samples needed to measure whole distance-----------------
var DISCARD_SAMPLES = 184
var NUM_SAMPLES			=  3 * var.BUFFER_SECONDS * var.SAMPLE_FREQUENCY
var DISCARD_TIME_S = var.DISCARD_SAMPLES / var.SAMPLE_FREQUENCY

var DISCARD_DISTANCE = 1

;Configure filenaming ---------------------------------------------------------
; (!) This path is shared between others xy_calibration g-codes
var CALIBRATION_PATH = {"/macros/xy_calibration/testscan/"^+state.time^".csv"} ; Path where the files are saved

; Deselecting the tool --------------------------------------------------------
if(state.currentTool >= 0)
	T{-1}
M400

G1 Z{var.Z_SAFE_HEIGHT} F{var.SPEED_FAST_MOVE}
G1 X{var.SCAN_X_START} Y{var.SCAN_Y_START}
G1 Z{var.LIFTING_Z}
M400

G4 S{var.DISCARD_TIME_S}
M400
; make a move that's exactly the number of samples long that we need to discard, otherwise the first samples might be erratic

; G91 ; Relative positioning
; G1 Y{var.DISCARD_DISTANCE/2 * var.DISCARD_TIME_S} F60
; G1 Y{-var.DISCARD_DISTANCE/2 * var.DISCARD_TIME_S} F60
; G90 ; Absolute positioning
M400
; Graph should look like this:
;
;  --------     -------- <- LIFTING_Z
;          \   /
;           \ /
;            . <- Z_PROBE_POS
;            ^
;            this should be the center of recording, as the timing should be symmetrical
;
; use https://quickplotter.com/ and paste csv values


; Start recording -------------------------------------------------------------
M956 P70.1 S{var.NUM_SAMPLES} Z A0 F{var.CALIBRATION_PATH} ; Start recording
G4 S{var.BUFFER_SECONDS - var.DISCARD_TIME_S}
M400
G1 Z{var.Z_PROBE_POS}
M400
G4 S{var.BUFFER_SECONDS}
M400
G1 Z{var.LIFTING_Z}
M400
G4 S{var.BUFFER_SECONDS}
M400
; Should stop recording about here --------------------------------------------
G1 Z{var.Z_SAFE_HEIGHT} F{var.SPEED_FAST_MOVE}
M400

M99