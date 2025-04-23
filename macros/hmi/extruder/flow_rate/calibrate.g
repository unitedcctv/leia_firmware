; Description:
;   This is a HMI command macro to perfrome a flow calibration
;   current selected tool with material specific temperature will be used for calibration
; Input Parameters:
;   - L (optional): [mm] Length of filament to extrude for calibration (default decided by extruder team = 500mm)
;	- F (optional): [mm/s] Extrusion speed in mm/s (default decided by extruder team 100mm/min)
;   - S (optional): Temperature for the tool
;   - T : tool index, Extruder to calibrate (error if not provided)
;   - I : Call Id for HMI
; Output Parameters:
; none, var.flowrateMultipier is the resulting value 
; Example:
;	M98 P"/macros/hmi/extruder/flow_rate/calibrate.g" L{500.0} F{1.667} T{0}
;	M98 P"/macros/hmi/extruder/flow_rate/calibrate.g" T{0}
; With standad values (no param.L and param.F) the calibration takes 6min and 11s
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/hmi/extruder/flow_rate/calibrate.g"
M118 S{"[calibrate.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
;M98 P"/macros/emergency/is_ready_to_operate.g"
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/extruder/flow_rate/calibrate.g"} F{var.CURRENT_FILE} E84300

; Check that parameters are present and not null
M98 P"/macros/assert/abort_if.g"		R{!exists(param.T)}     	Y{"Missing Tool index param T"}    	F{var.CURRENT_FILE} E84301
M98 P"/macros/assert/abort_if_null.g" 	R{param.T}              	Y{"Tool index param.T is null"} 	F{var.CURRENT_FILE} E84302
M98 P"/macros/assert/abort_if.g" R{(!exists(tools[param.T]))} Y{"Tool param T=%s outside range of available tools %s"} A{param.T,#tools}    F{var.CURRENT_FILE} E84303

if (exists(param.S))
	M98 P"/macros/assert/abort_if_null.g" 	R{param.S}              	Y{"Temperature param S is null"} F{var.CURRENT_FILE} E84305

if (exists(param.L))
	M98 P"/macros/assert/abort_if_null.g" 	R{param.L}              	Y{"Extrusion length param L is null"} F{var.CURRENT_FILE} E84304

if (exists(param.F))
	M98 P"/macros/assert/abort_if_null.g" 	R{param.F}              	Y{"Feedrate param F is null"} F{var.CURRENT_FILE} E84307

; Definitions -------------------------------------------------------------------
var Z_HOMED		=  exists(move.axes[2].homed) && (move.axes[2].homed == true)
var X_HOMED		=  exists(move.axes[0].homed) && (move.axes[0].homed == true)
var Y_HOMED		=  exists(move.axes[1].homed) && (move.axes[1].homed == true)

var Z_LIFT_POS = (move.axes[2].machinePosition > 100) ? 0 : 100
var Z_LIFT_SPEED = 900					; [mm/min] Speed to move in Z
var XY_SPEED	= 6000

if (exists(param.S))
	M98 P"/macros/hmi/extruder/set_temperature.g" T{param.T} S{param.S}
M400
M98 P"/macros/report/event.g" Y{"Preparing flowrate Calibration.."}  F{var.CURRENT_FILE} V84308
; checking for the axes homing status
if(!var.X_HOMED || !var.Y_HOMED)	
	M98 P"/macros/hmi/home/xy.g"
M400
; Moving to the safe parking position
G90									 	; absolute positioning
M400
if( var.Z_HOMED)
	if( move.axes[2].machinePosition < (move.axes[2].max - var.Z_LIFT_POS))
		G1 Z{ move.axes[2].machinePosition + var.Z_LIFT_POS} F{var.Z_LIFT_SPEED}	; lift Z by Z_LIFT_POS
	else
		G1 Z{move.axes[2].max} F{var.Z_LIFT_SPEED}  ;lift Z to Z_MAX
	M400
else
	G91 ; Relative move
	G1 Z{var.Z_LIFT_POS} F{var.Z_LIFT_SPEED} H4
	M400
	G90
M400
; park_xy to its minimum
G1 F{var.XY_SPEED} X{move.axes[0].min} Y{move.axes[1].min} H4
M400

if (exists(param.S))
    M98 P"/macros/report/event.g" Y{"Waiting for extruder to heat up.."}  F{var.CURRENT_FILE} V84309
    M116 P{param.T}
M400

; calibrate flow  
M98 P"/macros/extruder/flow_rate/calibrate.g" T{param.T}
M400

; Checking the Call Id param for HMI
if exists(param.I)
	M118 S{"#I"^param.I^"#DONE"}
;--------------------------------------------------------------------------------------------------------
M118 S{"[calibrate.g] Done "^var.CURRENT_FILE}
M99 ; Proper exit 