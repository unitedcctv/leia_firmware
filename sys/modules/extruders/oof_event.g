; Description: 	
;	Process the event of a filament sensor for T0
; Input Parameters:
;	None - hardcoded for T0
; Example:
;	M98 P"/sys/modules/extruders/oof_event.g"
; TODO:
;	In the pausing condition, we should check if it is paused.
;------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/extruders/oof_event.g"
M118 S{"[OOF] Starting " ^var.CURRENT_FILE}
; -----------------------------------------------------------------------------
; Definitions--------------------------------------------------------------------
var MIN_TEMP = 0 		; [dC] Min value before turning the tool off
var OFF_TEMP = -273.1 	; [dC] Value to use when the tool is off

; Checking global variables and input parameters ------------------------------
var TOOL = 0

; Reading the OOF input 
var NO_FILAMENT = (sensors.gpIn[global.OOF_INPUTS_ID[var.TOOL]].value == 0)
if(exists(global.oofMonitoringActive) && !global.oofMonitoringActive)
	M99
if(var.NO_FILAMENT)
	if ( var.TOOL == state.currentTool )
		if(state.status == "processing" )
			; our tool is currently printing, so we need to pause it
			M98 P"/macros/report/event.g" Y{"Pausing due to out-of-filament"}  		F{var.CURRENT_FILE} V12834
			M25	; Pausing
			set global.hmiStateDetail = "error_fila_oof"
			M400
			; Saving the tool temperature for the next tool to take over
			M568 P{var.TOOL} S{var.MIN_TEMP} R{var.MIN_TEMP} A0 ;Setting extruder temp to 0 first [SAFETY]
			M98 P"/macros/assert/result.g" R{result} Y"Unable to set the target temperature to zero first" F{var.CURRENT_FILE} E12835
			M568 P{var.TOOL} S{var.OFF_TEMP} R{var.OFF_TEMP} A0 ;Setting extruder temp to off temp [SAFETY]
			M98 P"/macros/assert/result.g" R{result} Y"Unable to set the target temperature for the extruder in off state" F{var.CURRENT_FILE} E12836
			M118 S{"[SAFETY] Turned off the extruder"}
			M598	
	else
		M98 P"/macros/report/event.g" Y{"No filament detected in T0"} F{var.CURRENT_FILE} V12827
else
	M98 P"/macros/report/event.g" Y{"Filament detected in T0"} F{var.CURRENT_FILE} V12828
; -----------------------------------------------------------------------------
M118 S{"[OOF] Done " ^var.CURRENT_FILE}
M99 ; Proper exit