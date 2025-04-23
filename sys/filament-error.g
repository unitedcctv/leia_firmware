; Description:
;	This file is automatically executed on a filament error event.
;	File required by Duet3D.
;	Default parameters:
;		param.D: Extruder number
;		param.P: Filament error type code
;		param.B: CAN address of the board hosting the filament monitor
;		param.S: Full text string describing the fault
; -----------------------------------------------------------------------------
var CURRENT_FILE = "/sys/filament-error.g"
M118 S{"[filament-error.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Definitions--------------------------------------------------------------------
var MIN_TEMP = 0 		; [dC] Min value before turning the tool off
var OFF_TEMP = -273.1 	; [dC] Value to use when the tool is off
var FILA_ERROR_TIME_WINDOW = 30 ; [s] how many seconds as a window for triggering filament error if crossed threshold
var FILA_ERROR_EVENT_THRESHOLD = 10 ; [n] how many error events within the window to trigger the error
var ACTIVE_TOOL = (param.B) == 81.0 ? 0 : 1 ; identifying the tool number using CAN address
if !exists(global.filaErrorEvents)
	; initialize with length threshold -1 because if the array is full and we have another event, we need to pause
	global filaErrorEvents = vector(var.FILA_ERROR_EVENT_THRESHOLD-1,0)

; Let's process the filament sensor -------------------------------------------

; Reading the OOF input;
var SENSOR_STATUS = sensors.filamentMonitors[param.D].status
if (var.SENSOR_STATUS == "sensorError" || var.SENSOR_STATUS == "noDataReceived")
	M98 P"/macros/report/warning.g" Y{"Detected error state in the filament monitor of the tool %s: %s"} A{param.D, var.SENSOR_STATUS} F{var.CURRENT_FILE} W31000
	M118 S{"[filament-error.g] Done " ^var.CURRENT_FILE}
	M99

M118 S{"[filament-error.g] T"^param.D^ " sensor status: "^var.SENSOR_STATUS^" - "^param.S}

if(state.status != "processing")
	M118 S"Not printing, ignoring filament error"
	M118 S{"[filament-error.g] Done " ^var.CURRENT_FILE}
	M99

; handle time window for filament error events
if (param.P == 4 || param.P == 5)
	; if we have too little or too much movement, we check if the threshold is crossed
	while iterations <= #global.filaErrorEvents
		if iterations >= #global.filaErrorEvents
			; we have reached the end of the array, so we need to pause
			; we continue with error handling as usual
			break

		var currentIndexAvailable = (state.upTime - global.filaErrorEvents[iterations]) > var.FILA_ERROR_TIME_WINDOW
		if var.currentIndexAvailable
			; we have an old event, we can use this slot
			set global.filaErrorEvents[iterations] = state.upTime
			M98 P"/macros/report/warning.g" Y{"Possible filament flow issue detected, continuing monitoring."} F{var.CURRENT_FILE} W31004
			M118 S{"[filament-error.g] Done " ^var.CURRENT_FILE}
			M99
	M400

if (param.P == 4)
	set global.hmiStateDetail = "error_fila_little"
elif (param.P == 5)
	set global.hmiStateDetail = "error_fila_much"
elif(param.P == 3)
	set global.hmiStateDetail = "error_fila_oof"
elif(param.P == 6)
	set global.hmiStateDetail = "error_fila_sensor"
elif(param.P == 2)
	set global.hmiStateDetail = "error_fila_nodata"
else
	set global.hmiStateDetail = "error_fila_unknown"

if ((param.P == 4) || (param.P == 3))
	var CURRENT_TOOL = state.currentTool
	if (exists(global.MODULE_FHX) && (global.MODULE_FHX[var.CURRENT_TOOL] != null))
		if (sensors.analog[global.oofFhxSensorID[var.CURRENT_TOOL]].lastReading >= (global.OOF_TRIGG_VALUE))
			M98 P"/macros/fhx/control/oof_event/pause.g" T{var.CURRENT_TOOL}	; calling pause instead of stopping print
			M598
			M118 S{"[filament-error.g] Done " ^var.CURRENT_FILE}
			M99
M598

if (param.P > 0)
	M118 S{"[filament-error.g] Pausing print"}
	M25 ; pause the print
	M400
	M568 P{var.ACTIVE_TOOL} S{var.MIN_TEMP} R{var.MIN_TEMP} A0 ;Setting extruder temp to 0 first [SAFETY]
	M568 P{var.ACTIVE_TOOL} S{var.OFF_TEMP} R{var.OFF_TEMP} A0 ;Setting extruder temp to off temp [SAFETY]
	M118 S{"[filament-error.g] Turned off the extruder"}
M400

M118 S{"[filament-error.g] Done " ^var.CURRENT_FILE}
M99 