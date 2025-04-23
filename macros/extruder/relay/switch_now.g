; Description: 	
;   This macro will 
;       - select the other extruder 
;       - and resume the print
;   when the current printing tool triggers oof and continue the printing.
;--------------------------------------------------------------------------------------------------
; Mandatory check before starting the file to sync all the input channels
if !inputs[state.thisInput].active
	M99
;----------------------------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/extruder/relay/switch_now.g"
M118 S{"[switch_now.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}
; checking for the variables
var ACTIVATE_EXTRUDER_RELAY = (exists(global.activateExtruderRelay) && global.activateExtruderRelay == true)
if(!var.ACTIVATE_EXTRUDER_RELAY )
	M98 P"/macros/report/warning.g"   Y{"Extruder Relay is not activated"}    F{var.CURRENT_FILE} W57623
	M99
; variables to store the tool numbers
var IS_PAUSED =(state.status == "paused")
var MIN_TEMP = 0
var TURN_OFF_TEMP = -273.1

; checking if the printee is paused before---------------------------------------------------------------
if(var.ACTIVATE_EXTRUDER_RELAY)
	if(!var.IS_PAUSED)
		M118 S{"[switch_now.g] Pausing the print to switch the tools"}
		M25	; pausing
	M598
	; Swapping the temperature of the tools 
	var TEMP_T0 = global.lastPrintingTemps[0]
	var TEMP_T1 = global.lastPrintingTemps[1]
	set global.lastPrintingTemps = {var.TEMP_T1 , var.TEMP_T0}	
	; Switching the tool now-----------------------------------------------------------------------------------
	if(global.lastPrintingTool == 0)
		set global.lastPrintingTool = 1
	elif(global.lastPrintingTool == 1)
		set global.lastPrintingTool = 0
	M118 S{"[switch_now.g] switched to the tool "^global.lastPrintingTool}

	; continue if it is an emulator
	if (network.hostname == "emulator")
		M24	; resuming
		M118 S{"[switch_now.g] Done "^var.CURRENT_FILE}
		M99
	; resuming the print if there is filament loaded	
	var HAS_FILAMENT = (exists(global.OOF_INPUTS_ID) && sensors.gpIn[global.OOF_INPUTS_ID[global.lastPrintingTool]].value == 1 )  ? true : false
	if(var.HAS_FILAMENT)		
		M24	; resuming
		if(global.lastPrintingTool == 0)
			G0 U{move.axes[3].min} W{move.axes[4].max}
		elif(global.lastPrintingTool == 1)
			G0 U{move.axes[3].max} W{move.axes[4].min}
		M400
	else
		M98 P"/macros/report/warning.g"   Y{"No filament in the switched tool %s"} A{global.lastPrintingTool,}    F{var.CURRENT_FILE} W57624
M400	
;--------------------------------------------------------------------------------------------------------
M118 S{"[switch_now.g] Done "^var.CURRENT_FILE}
M99
