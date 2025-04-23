; Description: 	
;	This will start nozzle cleaning 
; Input param.T for selected Tool
; Example:
;	M98 P"/macros/nozzle_cleaner/wipe.g"
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/nozzle_cleaner/wipe.g"
M118 S{"[wipe.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}
; checking for the parameter
if(exists(param.T))
	M98 P"/macros/assert/abort_if_null.g" R{param.T}  	  Y{"Input parameter T is null"} 			F{var.CURRENT_FILE} E71211
	M98 P"/macros/assert/abort_if.g" R{(param.T>=2||param.T<0)}  Y{"Unexpected tool value"} 		F{var.CURRENT_FILE} E71212

; Checking global variables and input parameters ------------------------------
if ((!exists(global.wiperPresent)) || (global.wiperPresent = false ))
	M118 S{"[wipe.g] Wiping station doesn't exist or is not enabled."}
	M99
; Setting the wiping tool------------------------------
var WIPE_TOOL = (exists(param.T) && param.T != null && param.T != -1) ? param.T : state.currentTool
if !exists(tools[var.WIPE_TOOL])
	M118 S{"[wipe.g] Tool T" ^var.WIPE_TOOL^" does not exist"}
	M99

if var.WIPE_TOOL < 0 || var.WIPE_TOOL > 1
	M118 S{"[wipe.g] No tool selected"}
	M99
M118 S{"[wipe.g] Wiping T" ^var.WIPE_TOOL}

var RESTORE_TOOL = state.currentTool

;setting variables-----------------------------------
var TOUCH_SENSOR_ID		= global.TOUCH_BED_SENSOR_IDS[var.WIPE_TOOL]  ; Sensor to use
var POSITION_THRESHOLD = 0.5
var loopCounter			= 2         ; iterations variable
var XY_RESTORE_POS		= {move.axes[0].userPosition, move.axes[1].userPosition}
var WIPE_SPEED			= 10000     ; moving speed
var WIPE_X_LENGTH 		= 60
var WIPE_Y_WIDTH		= 10
var MANUAL_WIPE 		= exists(global.manualWipe) && global.manualWipe
var flushMoveDistance		= 250	;[mm] distance travelled while flushing
var FLUSH_LENGTH		= 20	;[mm]
var FLUSH_SPEED			= 180	;[mm/min]
var FLUSH				= exists(param.F) && (param.F == 0) ? false : true

; checking if the tool is hot
var IS_TOOL_HOT = heat.heaters[tools[var.WIPE_TOOL].heaters[0]].current > heat.coldExtrudeTemperature
var TOOL_HEAT_UP_REQUESTED = heat.heaters[tools[var.WIPE_TOOL].heaters[0]].active > 0
var DO_FLUSH = var.IS_TOOL_HOT && var.TOOL_HEAT_UP_REQUESTED && var.FLUSH

; setting the wiping positions in X and Y
var WIPE_X_START		= global.WIPER_X_POSITIONS[var.WIPE_TOOL] + tools[var.WIPE_TOOL].offsets[0]
var WIPE_Y_START		= global.WIPER_Y_POSITIONS[var.WIPE_TOOL] + tools[var.WIPE_TOOL].offsets[1]
var MAX_X_POS		= global.printingLimitsX[1] + tools[var.WIPE_TOOL].offsets[0]

var FLUSH_X_END = var.WIPE_X_START + var.flushMoveDistance
set var.FLUSH_X_END	= var.FLUSH_X_END <= var.MAX_X_POS ? var.FLUSH_X_END : var.MAX_X_POS
set var.flushMoveDistance = var.FLUSH_X_END - var.WIPE_X_START

T{var.WIPE_TOOL} ; select the tool
M400
var WIPE_TOOL_LIFTER_MIN = move.axes[3+var.WIPE_TOOL].min
; ================ prepare for wiping ====================
if(var.WIPE_TOOL == 0)
	M208 U{global.TOOL_WIPING_POS[var.WIPE_TOOL]} S1
	M400
	G1 U{global.TOOL_WIPING_POS[var.WIPE_TOOL]} F3000
else
	M208 W{global.TOOL_WIPING_POS[var.WIPE_TOOL]} S1
	M400
	G1 W{global.TOOL_WIPING_POS[var.WIPE_TOOL]} F3000
M400
G4 S1
M400
var UWSensorPosition = sensors.analog[var.TOUCH_SENSOR_ID].lastReading
var UWPositionDiff = move.axes[3+var.WIPE_TOOL].userPosition - var.UWSensorPosition
M118 S{"[wipe.g] Initial position diff: "^var.UWPositionDiff}
if abs(var.UWPositionDiff) > var.POSITION_THRESHOLD
	T-1
	M400
	; restore tool minimums
	if(var.WIPE_TOOL == 0)
		M208 U{var.WIPE_TOOL_LIFTER_MIN} S1
	else
		M208 W{var.WIPE_TOOL_LIFTER_MIN} S1
	M400
	T-1
	M400
	M98 P"/macros/report/warning.g" Y{"T%s did not reach target position before wiping. Please clean wiping station"} A{var.WIPE_TOOL,} F{var.CURRENT_FILE} W71213
	M99
M400

M118 S{"[wipe.g] moving to wiping pos X"^var.WIPE_X_START^" Y"^var.WIPE_Y_START}
; move to the Wipe X and y positions
G0 X{var.WIPE_X_START} F{var.WIPE_SPEED}
G0 Y{var.WIPE_Y_START}

; FLUSH requested for wiping
if(var.DO_FLUSH)
	M83
	M400
	; to keep extrusion speed as FLUSH_SPEED we need to adjust the movement speed
	M118 S{"[wipe.g] Purging "^var.FLUSH_LENGTH^" mm of filament"}
	if var.flushMoveDistance > 10
		var feed = var.FLUSH_SPEED * (var.flushMoveDistance / var.FLUSH_LENGTH)
		G1 X{var.FLUSH_X_END} E{var.FLUSH_LENGTH} F{var.feed}
	else
		G1 E{var.FLUSH_LENGTH} F{var.FLUSH_SPEED}
	M400
	G4 S3
	M400
	G1 X{var.WIPE_X_START} F{var.WIPE_SPEED}
	M400
else
	M118 S{"[wipe.g] Wiping without purging"}
M400


; ================== wipe the nozzle ====================
G91 ; relative
; move in an 'X' pattern, with random Y offset each time
while (iterations < var.loopCounter)
	var randomOffset = random(var.WIPE_Y_WIDTH)
	; negate the offset for T1 because it is on the other side
	set var.randomOffset = var.WIPE_TOOL == 0 ? var.randomOffset : {-1 * var.randomOffset}
	G1 X{-var.WIPE_X_LENGTH} Y{var.randomOffset} F{var.WIPE_SPEED}
	G1 Y{-var.randomOffset}
	G1 X{var.WIPE_X_LENGTH} Y{var.randomOffset}
	G1 Y{-var.randomOffset}
	M400
M400
G90 ; absolute

;================= restore the tool and axes positions ====================
; restore tool minimums
if(var.WIPE_TOOL == 0)
	M208 U{var.WIPE_TOOL_LIFTER_MIN} S1
	M400
	if var.RESTORE_TOOL == var.WIPE_TOOL
		G1 U{var.WIPE_TOOL_LIFTER_MIN} F3000
else
	M208 W{var.WIPE_TOOL_LIFTER_MIN} S1
	M400
	if var.RESTORE_TOOL == var.WIPE_TOOL
		G1 W{var.WIPE_TOOL_LIFTER_MIN} F3000
M400

T{var.RESTORE_TOOL}
M400
; -----------------------------------------------------------------------------
M118 S{"[wipe.g] Done " ^var.CURRENT_FILE}
M99 ; Proper exit