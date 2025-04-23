; Description: 	
; 	The goal is to measure the same point at different hights in order to
; 	avoid alinearities of the sensor to affect the result.
; Input parameters:
;	- T : [sec] Sampling period (Default: 0.3 sec) 
;	- O : [] Amount of points per step (Default: 1)
; Output paramters:
;	- global.probeMeasuredValue : [mm] Distance to the bed.
; -----------------------------------------------------------------------------
var CURRENT_FILE 	= "/macros/probe/get_sample_single_z.g"

; Set global return variables -------------------------------------------------
if(!exists(global.probeMeasuredValue))
	global probeMeasuredValue = null
else 
	set global.probeMeasuredValue = null

; Definitions -----------------------------------------------------------------
var DEFAULT_DELAY_SAMPLING	= 0.3		; [sec] Delay between samples by
										; default.
var DEFAULT_SAMPLES_PER_POINT = 1		; [] Amount of samples per point in Z
										; by default.

; Getting the input parameters ------------------------------------------------
var DELAY_SAMPLING		= { (exists(param.T) && param.T != null) ? param.T : var.DEFAULT_DELAY_SAMPLING }
var SAMPLES_PER_POINT	= { (exists(param.O) && param.O != null) ? param.O : var.DEFAULT_SAMPLES_PER_POINT }

; Start sampling --------------------------------------------------------------
var accumValue = 0	; [mm] Accumulated values of the sensor
var valuesTaken = 0
G4 S{var.DELAY_SAMPLING} ; Getting a stable value
while (var.valuesTaken < var.SAMPLES_PER_POINT)
	set var.accumValue = var.accumValue + (( sensors.analog[global.PROBE_SENSOR_ID].lastReading) / 1000.0 ) ; [mm]
	set var.valuesTaken = var.valuesTaken + 1
	if(var.valuesTaken < var.SAMPLES_PER_POINT)
		G4 S{var.DELAY_SAMPLING}	; Making sure the next value changed.

; Return the value
set global.probeMeasuredValue = var.accumValue / var.SAMPLES_PER_POINT

; -----------------------------------------------------------------------------
M99 ; Proper exit