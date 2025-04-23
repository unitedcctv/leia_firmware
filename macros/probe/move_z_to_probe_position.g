; Description: 	
;   We will use the probe to go to probe position in Z.
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/probe/move_z_to_probe_position.g"
M118 S{"[PROBE] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking global variables
M598
M98 P"/macros/assert/abort_if.g" R{!exists(global.MODULE_PROBES)}  		Y{"Missing required module PROBES"}			 F{var.CURRENT_FILE} E65300
M98 P"/macros/assert/abort_if.g" R{!exists(global.PROBE_MAXIMUM)}  		Y{"Missing global variable PROBE_MAXIMUM"}   F{var.CURRENT_FILE} E65301
M98 P"/macros/assert/abort_if_null.g" R{global.PROBE_MAXIMUM} 			Y{"PROBE_MAXIMUM is null"} 					 F{var.CURRENT_FILE} E65302
M98 P"/macros/assert/abort_if.g" R{!exists(global.PROBE_VALUE_AT_Z)}  	Y{"Missing global variable PROBE_START_Y"}   F{var.CURRENT_FILE} E65303
M98 P"/macros/assert/abort_if_null.g" R{global.PROBE_VALUE_AT_Z} 		Y{"PROBE_VALUE_AT_Z is null"} 				 F{var.CURRENT_FILE} E65304

; Definitions -----------------------------------------------------------------
var OFFSET_TO_MAX 			= 300							; [um] Ofsset to the minimum target value
var VALUE_STOP_FIRST_MOVE 	= 800							; [um] Min value to stop moving down.
; var VALUE_STOP_FIRST_MOVE = global.PROBE_MAXIMUM - var.OFFSET_TO_MAX 	; [um] Min value to stop moving down.
var VALUE_HOMED 			= 0 							; [um] Distance to bed to do the bed leveling
var VALUE_START_FINE_TUNING = global.PROBE_VALUE_AT_Z-50	; [um] A value smaller than VALUE_HOMED to always move from the bottom.
var TOLERANCE_HOME 			= 7 							; [um] Maximum distance to the target.
var TOLERANCE_FINE_TUNING 	= 50 							; [um] Maximum distance to the target.

var BIG_STEP_DISTANCE 		= 0.02							; [mm] Minimum Step (for fast move down)
var BIG_STEP_SPEED 			= 200							; [mm/sec] Fast move speed. (for fast move down)
var SMALL_STEP_DISTANCE 	= 0.005 						; [mm] Minimum Step
var SMALL_STEP_SPEED 		= 150							; [mm/sec] Fast move speed.

var DELAY_LONG 				= 1.5							; [sec] Long sleep to wait a value to be stable
var DELAY_MEDIUM 			= 1								; [sec] Medium sleep to wait a value to be stable
var DELAY_SHORT 			= 0.75							; [sec] Short sleep to wait a value to be stable

; Making sure we are far enought from the bed ---------------------------------
if(sensors.analog[global.PROBE_SENSOR_ID].lastReading < global.PROBE_MAXIMUM_RANGE[0])
	; We lift
	G91
	G1 Z10 H1
	M400
	G90
	G4 S0.5
	; If the sensor is still to low we have a fatal error
	M598
	var IS_OUT_OF_RANGE = (sensors.analog[global.PROBE_SENSOR_ID].lastReading < global.PROBE_MAXIMUM_RANGE[0])
	M98 P"/macros/assert/abort_if.g" R{var.IS_OUT_OF_RANGE}	Y{"Probe value is too low to start"} F{var.CURRENT_FILE} E65320

; Prepare the machine position ------------------------------------------------
G90
M400
G92 Z{move.axes[2].max} ; Changing the current position
G4 S{var.DELAY_SHORT}

; Changing the reference in the emulated sensor
if( network.name == "EMULATOR" )
	; (!) 	This is needed for the emulated ball-sensor. We may not need it, once we can remove the previous 
	;		G92 and be able to home with relative moves and the ball sensor.
	M18 Z ; Turn off Z motor to remove the "homed"
	G4 S{var.DELAY_SHORT}
	M17 Z ; Turn the motor again.
	G92 Z{move.axes[2].max} ; Changing the current position
	G4 S{var.DELAY_SHORT}
	M308 S{global.PROBE_SENSOR_ID} ; Make sure the sensor zOffset is reloaded
	G4 S1
	M400


; Loading first values --------------------------------------------------------
var zPosition = move.axes[2].machinePosition
var lastReading = sensors.analog[global.PROBE_SENSOR_ID].lastReading

; Move down until the VALUE_STOP_FIRST_MOVE is triggered ----------------------
M118 S{"[PROBE] Moving down in X"^move.axes[0].userPosition^" Y"^move.axes[1].userPosition}
M595 P5	; Reducing the queue length
while ( var.lastReading > var.VALUE_STOP_FIRST_MOVE )
	set var.zPosition = {var.zPosition - var.BIG_STEP_DISTANCE}
	G1 Z{var.zPosition} F{var.BIG_STEP_SPEED}
	set var.lastReading = sensors.analog[global.PROBE_SENSOR_ID].lastReading
M595 P60	; Recovering the queue length

; Record the current value
G4 S{var.DELAY_LONG} ; Some time so the value is stable
set var.lastReading = sensors.analog[global.PROBE_SENSOR_ID].lastReading
M118 S{"[PROBE] Stopped at: " ^ {var.lastReading} ^ "um"}
M598
M98 P"/macros/printing/abort_if_forced.g" Y{"Before moving to VALUE_START_FINE_TUNING"} F{var.CURRENT_FILE} L{inputs[state.thisInput].lineNumber}
; Let's move below the VALUE_HOMED (to the VALUE_START_FINE_TUNING)
set var.zPosition = var.zPosition - ( ( var.lastReading - var.VALUE_START_FINE_TUNING ) / 1000.0 )
G1 Z{var.zPosition} F{var.SMALL_STEP_SPEED}
M400
G4 S{var.DELAY_LONG} ; Some time so the value is stable
set var.lastReading = sensors.analog[global.PROBE_SENSOR_ID].lastReading
; M118 S{"[PROBE] Diff to VALUE_START_FINE_TUNING: " ^ (var.lastReading-var.VALUE_START_FINE_TUNING) ^ " um"}


while ( abs(var.lastReading - var.VALUE_START_FINE_TUNING) > var.TOLERANCE_FINE_TUNING )
	M598
	M98 P"/macros/printing/abort_if_forced.g" Y{"In the VALUE_START_FINE_TUNING loop"} F{var.CURRENT_FILE} L{inputs[state.thisInput].lineNumber}
	set var.zPosition = var.zPosition - ( ( var.lastReading - var.VALUE_START_FINE_TUNING ) / 1000.0 )
	G1 Z{var.zPosition} F{var.SMALL_STEP_SPEED}
	M400
	G4 S{var.DELAY_MEDIUM} ; Some time so the value is stable
	set var.lastReading = sensors.analog[global.PROBE_SENSOR_ID].lastReading
	; M118 S{"[PROBE] Diff to StartValue: " ^ (var.lastReading-var.VALUE_START_FINE_TUNING) ^ " um"}

; Start fine tuning
; M118 S{"[PROBE] Doing fine tuning"}
while ( abs(var.lastReading - var.VALUE_HOMED) > var.TOLERANCE_HOME )
	M598
	M98 P"/macros/printing/abort_if_forced.g" Y{"During fine tunning"} F{var.CURRENT_FILE} L{inputs[state.thisInput].lineNumber}
	if( var.lastReading > var.VALUE_HOMED )
		set var.zPosition = var.zPosition - var.SMALL_STEP_DISTANCE
	else
		set var.zPosition = var.zPosition + var.SMALL_STEP_DISTANCE
	G1 Z{var.zPosition} F{var.SMALL_STEP_SPEED}
	M400
	while( var.lastReading == sensors.analog[global.PROBE_SENSOR_ID].lastReading )
		G4 P50
	if (abs(sensors.analog[global.PROBE_SENSOR_ID].lastReading - var.VALUE_HOMED) <= (3*var.TOLERANCE_HOME))
		G4 S{var.DELAY_LONG} ; More time to be stable
	set var.lastReading = sensors.analog[global.PROBE_SENSOR_ID].lastReading

M118 S{"[PROBE] Final Position: " ^ {var.zPosition} ^ "mm with an error of: "^(abs(sensors.analog[global.PROBE_SENSOR_ID].lastReading - global.PROBE_VALUE_AT_Z)/1000)^"mm"}

; -----------------------------------------------------------------------------
M118 S{"[PROBE] Done "^var.CURRENT_FILE}
M99 ; Done