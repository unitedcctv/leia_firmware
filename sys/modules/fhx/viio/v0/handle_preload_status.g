; Description: 	
;	This will check the preload status by checking the oof sensor values in the
;       fhx box of both rolls. Sensor value 1 means no filament and 0 means
;           filament present.
; Example:
;	M98 P"/sys/modules/fhx/viio/v0/handle_preload_status.g"
;------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/fhx/viio/v0/handle_preload_status.g"
M118 S{"[handle_preload_status.g]  Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking for files first ----------------------------------------------------------------------------------
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/fhx/material/load/automatic_preload.g"} F{var.CURRENT_FILE} E17647

; global state motors running
if (!exists(global.fhxMotorsRunning))
	global fhxMotorsRunning = null
else
	set global.fhxMotorsRunning = null
; Definitions----------------------------------------------------------
var FILAMENT_LEFT_TOP = sensors.gpIn[global.FHX_SENSOR_ID[param.T][0]].value == 0
var FILAMENT_LEFT_BOTTOM= sensors.gpIn[global.FHX_SENSOR_ID[param.T][1]].value == 0
var FILAMENT_RIGHT_TOP = sensors.gpIn[global.FHX_SENSOR_ID[param.T][2]].value == 0
var FILAMENT_RIGHT_BOTTOM = sensors.gpIn[global.FHX_SENSOR_ID[param.T][3]].value == 0

; set preload status-----------------------------------

; could be simplified to this, but explicit is more readable
; if (var.FILAMENT_LEFT_TOP && !var.FILAMENT_LEFT_BOTTOM)
;     M98 P"/macros/fhx/material/load/automatic_preload.g" T{param.T} S0
; else
;     set global.fhxPreload[param.T][0] = {(var.FILAMENT_LEFT_TOP || var.FILAMENT_LEFT_BOTTOM)}
; M400

; checking and setting the left spool preload status
if (var.FILAMENT_LEFT_TOP && var.FILAMENT_LEFT_BOTTOM)
    set global.fhxPreload[param.T][0] = true
elif (var.FILAMENT_LEFT_TOP && !var.FILAMENT_LEFT_BOTTOM)
    M98 P"/macros/fhx/material/load/automatic_preload.g" T{param.T} S0
elif (!var.FILAMENT_LEFT_TOP && var.FILAMENT_LEFT_BOTTOM)
    set global.fhxPreload[param.T][0] = true
elif (!var.FILAMENT_LEFT_TOP && !var.FILAMENT_LEFT_BOTTOM)
    set global.fhxPreload[param.T][0] = false
M400

; checking and setting the right spool preload status
if (var.FILAMENT_RIGHT_TOP && var.FILAMENT_RIGHT_BOTTOM)
    set global.fhxPreload[param.T][1] = true
elif (var.FILAMENT_RIGHT_TOP && !var.FILAMENT_RIGHT_BOTTOM)
    M98 P"/macros/fhx/material/load/automatic_preload.g" T{param.T} S1
elif (!var.FILAMENT_RIGHT_TOP && var.FILAMENT_RIGHT_BOTTOM)
    set global.fhxPreload[param.T][1] = true
elif (!var.FILAMENT_RIGHT_TOP && !var.FILAMENT_RIGHT_BOTTOM)
    set global.fhxPreload[param.T][1] = false
M400
;-----------------------------------------------------------------------
M118 S{"[handle_preload_status.g] Done "^var.CURRENT_FILE}
M99 ; Proper exit