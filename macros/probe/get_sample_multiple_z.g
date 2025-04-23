; Description: 	
; 	The goal is to measure the same point at different hights in order to
; 	avoid alinearities of the sensor to affect the result.
; Input parameters:
; 	- Z : Amount of points in Z (Default: 1)
; 	- A : Avoid first point (Default: true)
;	- S : [mm] Step size (Default: 0.025 mm) 
;	- T : [sec] Sampling period (Default: 0.3 sec) 
;	- O : [] Amount of points per step (Default: 1)
; Output parameters:
;	- global.probeMeasuredValue: [mm] Measured value or null (if there was a 
;			problem).
;------------------------------------------------------------------------------
var CURRENT_FILE 	= "/macros/probe/get_sample_multiple_z.g"
; M118 S{"[PROBE] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Set global return variables -------------------------------------------------
M598
if(!exists(global.probeMeasuredValue))
	global probeMeasuredValue = null
else
	set global.probeMeasuredValue = null

; Definitions -----------------------------------------------------------------
var STEP_SPEED = move.axes[2].speed*0.9	; [mm/min] 90% of the max speed of Z
var DEFAULT_Z_AMOUNT_POINTS = 1			; [] Amount of points to measure in Z 
										; by default.
var DEFAULT_AVOID_FIRST_Z_POINT = true  ; [] The first point is not considered
										; in the samples by default. Consider
										; using it when there is lot of 
										; backlash
var DEFAULT_Z_STEP_SIZE	= 0.025			; [mm] Step size of the move in Z by
										; default.
var DEFAULT_DELAY_SAMPLING	= 0.3		; [sec] Delay between samples by
										; default.
var DEFAULT_SAMPLES_PER_POINT = 1		; [] Amount of samples per point in Z
										; by default.

; Getting the input parameters ------------------------------------------------
var Z_AMOUNT_POINTS 	= { (exists(param.Z) && param.Z != null) ? param.Z : var.DEFAULT_Z_AMOUNT_POINTS }
var AVOID_FIRST_Z_POINT = { (exists(param.A) && param.A != null) ? param.A : var.DEFAULT_AVOID_FIRST_Z_POINT }
var Z_STEP_SIZE 		= { (exists(param.S) && param.S != null) ? param.S : var.DEFAULT_Z_STEP_SIZE }
var DELAY_SAMPLING		= { (exists(param.T) && param.T != null) ? param.T : var.DEFAULT_DELAY_SAMPLING }
var SAMPLES_PER_POINT	= { (exists(param.O) && param.O != null) ? param.O : var.DEFAULT_DELAY_SAMPLING }

; Start sampling --------------------------------------------------------------
var zMoves 		= { (var.AVOID_FIRST_Z_POINT) ? -1 : 0} ; Skeep or not the first move.
var accumValue	= 0	; [mm] Accumulated values of the sensor
var accumOffset = 0 ; [mm] Accumulated offset due to the move in Z
while ( var.zMoves < var.Z_AMOUNT_POINTS )
	if ( var.zMoves >= 0 )
		G4 S{var.DELAY_SAMPLING} ; Getting a stable value
		var valuesTaken = 0
		while (var.valuesTaken < var.SAMPLES_PER_POINT)
			set var.accumValue = var.accumValue + (( sensors.analog[global.PROBE_SENSOR_ID].lastReading) / 1000.0 ) ; [mm]
			set var.valuesTaken = var.valuesTaken + 1
			if(var.valuesTaken < var.SAMPLES_PER_POINT)
				G4 S{var.DELAY_SAMPLING}	; Making sure the next value changed.
	set var.zMoves = var.zMoves + 1
	;Moving up to next measurement position if it is necessary.
	if( var.zMoves < var.Z_AMOUNT_POINTS ) ; If it is not the last move
		; Moving down to the next point
		G91
		G1 Z{-var.Z_STEP_SIZE} F{var.STEP_SPEED}
		M400
		G90
		set var.accumOffset = var.accumOffset - var.Z_STEP_SIZE 

; Calculate the final result --------------------------------------------------
set var.accumValue = var.accumValue - var.accumOffset ; Removing the accumulated offset
; Return the value
set global.probeMeasuredValue = var.accumValue / (var.Z_AMOUNT_POINTS * var.SAMPLES_PER_POINT)

; -----------------------------------------------------------------------------
M118 S{"[PROBE] Done "^var.CURRENT_FILE}
M99 ; Proper exit