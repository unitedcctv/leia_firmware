; Description: 	
;   this macro moves to all 6 screws and emits an event with the current state of the adjustment for display in the HMI
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/hmi/bed/start_manual_adjustment.g"
M118 S{"[start_manual_adjustment.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking files
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/probe/get_sample_single_z.g"} 			F{var.CURRENT_FILE} E81201
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/doors/lock.g"}							F{var.CURRENT_FILE} E81203
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{!exists(global.BED_SCREW_POINTS)} 	Y{"Missing required global.BED_SCREW_POINTS"} 		F{var.CURRENT_FILE} E81202

; Definitions -----------------------------------------------------------------
var Z_POSITION_START =	 0			; [mm] Position where the ball-sensor is not
									; touching the bed.
var Z_MOVE_SPEED		= 600		; [mm/min]
var XY_MOVE_SPEED		= 12000		; [mm/min]
var Z_BACKLASH			= 0.5

; Lock the door ---------------------------------------------------------------
M98 P"/macros/doors/lock.g"

; Homing ----------------------------------------------------------------------
; Deselecting the current tool
T-1
M400
var NOT_HOMED = ( !move.axes[0].homed || !move.axes[1].homed || !move.axes[2].homed || (exists(move.axes[3].homed) && !move.axes[3].homed) || (exists(move.axes[4].homed) && !move.axes[4].homed) )
if(var.NOT_HOMED)
	M118 S"[start_manual_adjustment.g] Homing all first"
	G28
M400

M118 S{"[start_manual_adjustment.g] Disabling bed mesh"}
G29 S2			; Disable mesh compensation
M400

G1 Z{var.Z_POSITION_START} F{var.Z_MOVE_SPEED}
M400

; Start measuring -------------------------------------------------------------
; Start moving around the points
var previousValues = vector(#global.BED_SCREW_POINTS, null)
var point = 0
while (var.point < #global.BED_SCREW_POINTS)
	; Move to the point
	var CURRENT_POINT = global.BED_SCREW_POINTS[var.point]
	G1 X{var.CURRENT_POINT[0]} Y{var.CURRENT_POINT[1]} F{var.XY_MOVE_SPEED}
	M400
	if (var.point == 0)
		; First point, move down to probe position
		G1 Z{global.PROBE_OFFSET_Z-var.Z_BACKLASH} F{var.Z_MOVE_SPEED}
		G1 Z{global.PROBE_OFFSET_Z} F{var.Z_MOVE_SPEED}
		G4 S{0.5}
	M400
	M98 P"/macros/probe/get_sample_single_z.g"
	set var.previousValues[var.point] = -global.probeMeasuredValue
	
	; Always send the full list of points
	var iPrev = 0
	var message = ""
	while (var.iPrev < #var.previousValues)
		var DATA = { global.BED_SCREW_POINTS[var.iPrev][0], global.BED_SCREW_POINTS[var.iPrev][1], var.previousValues[var.iPrev]}
		var DATA_MESSAGE = { "("^var.DATA[0]^","^var.DATA[1]^","^var.DATA[2]^")"}
		if(var.iPrev == 0)
			set var.message = {"#H00001#~ref:"^var.DATA_MESSAGE^"|points:"}
		else 
			set var.message = {var.message^{((var.iPrev)==1) ? "" : ","}^var.DATA_MESSAGE}
		set var.iPrev = var.iPrev + 1
	set var.message = {var.message ^"~ Bed adj points"}
	; Report
	M118 S{var.message}
	
	set var.point = var.point + 1

; Unlock the door once we are done --------------------------------------------
M98 P"/macros/doors/unlock.g"

; Checking the Call Id param for HMI
if exists(param.I)
	M118 S{"#I"^param.I^"#DONE"}
; -----------------------------------------------------------------------------
M118 S{"[start_manual_adjustment.g] Done "^var.CURRENT_FILE}
M99 ; Proper exit
