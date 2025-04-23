; Description: 	
;	called if oof triggered while printing
;
; Input Parameters:
;	- T: Tool 0 or 1 to configure
; Example:
;	M98 P"/macros/fhx/control/oof_event/pause.g"
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/fhx/control/oof_event/pause.g"
M118 S{"[OOF] Starting " ^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking for files first
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/fhx/material/load/feed_spool.g"} F{var.CURRENT_FILE} E71003
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/nozzle_cleaner/wipe.g"} F{var.CURRENT_FILE} E71004
M98 P"/macros/assert/abort_if_file_missing.g" R{"/sys/modules/extruders/oof/v0/event.g"} F{var.CURRENT_FILE} E71005
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/printing/recover_tool_temp.g"} F{var.CURRENT_FILE} E71006
; Checking global variables and parameters
M98 P"/macros/assert/abort_if.g" R{!exists(param.T)}  Y{"Missing required input parameter T"} 	F{var.CURRENT_FILE} E71007
M98 P"/macros/assert/abort_if_null.g" R{param.T}  	  Y{"Input parameter T is null"} 			F{var.CURRENT_FILE} E71008
M98 P"/macros/assert/abort_if.g" R{(param.T>=2||param.T<0)}  Y{"Unexpected tool value"} 		F{var.CURRENT_FILE} E71009
M98 P"/macros/assert/abort_if.g" R{!exists(global.oofFhxSensorID)}  Y{"Missing required input parameter T"} 	F{var.CURRENT_FILE} E71010
M98 P"/macros/assert/abort_if.g" R{!exists(global.fhxPreload)}  Y{"Missing required input parameter T"} 	F{var.CURRENT_FILE} E71011
M98 P"/macros/assert/abort_if.g" R{!exists(global.FHX_SENSOR_ID)}  Y{"Missing required input parameter T"} 	F{var.CURRENT_FILE} E71012
M98 P"/macros/assert/abort_if.g" R{!exists(global.OOF_TRIGG_VALUE)}  Y{"Missing required input parameter T"} 	F{var.CURRENT_FILE} E71013

; Reading the OOF input
var NO_FILAMENT = (sensors.analog[global.oofFhxSensorID[param.T]].lastReading >= (global.OOF_TRIGG_VALUE))
var sensor = null

; calling oof or load------------------------------------------------------------
if(state.status == "processing" )
	if ((global.fhxPreload[param.T][0] = false) && (global.fhxPreload[param.T][1] = false))
		M98 P"/sys/modules/extruders/oof/v0/event.g" T{param.T}  ; fhx oof call event
	elif((var.NO_FILAMENT) && (param.T == state.currentTool))
		M25	; Pausing
		M400 ; finishing moves
		if ((global.fhxPreload[param.T][0] = true) && (global.fhxPreload[param.T][1] = true))
			if (sensors.gpIn[global.FHX_SENSOR_ID[param.T][3]].value == 0)
				set var.sensor = 1
			else
				set var.sensor = 0
		else
			if (global.fhxPreload[param.T][0] = true)
				set var.sensor = 0
			elif  (global.fhxPreload[param.T][1] = true)
				set var.sensor = 1
		M98 P"/macros/printing/recover_tool_temp.g"
		M598
		M98 P"/macros/fhx/material/load/feed_spool.g" T{param.T} S{var.sensor}	; load extruder
		M598
		M98 P"/macros/nozzle_cleaner/wipe.g" T{param.T}
		M598
		M24
		M400

; -----------------------------------------------------------------------------
M118 S{"[OOF] Done " ^var.CURRENT_FILE}
M99 ; Proper exit
