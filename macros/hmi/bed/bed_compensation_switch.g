; Description: 	
;	This will enable or disable the bed compensation.
;		it is a toggle macro. 
; ; Example:
;	M98 P"/macros/hmi/bed/bed_compensation_switch.g"
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/hmi/bed/bed_compensation_switch.g"
M118 S{"[bed_compensation_switch.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
;creating the global variables----------------------------------------------
if(!exists(global.bedCompensationActive))
	global bedCompensationActive = true
set global.bedCompensationActive = !global.bedCompensationActive ;toggling the value
; checking the status of the bed compensation------------------------------------------
if(global.bedCompensationActive)
	set global.bedCompensationActive = false
	M98 P"/macros/report/event.g" Y{"Bed compensation is disabled "} F{var.CURRENT_FILE} V81120
else
	set global.bedCompensationActive = true
	M98 P"/macros/report/event.g" Y{"Bed compensation is enabled "} F{var.CURRENT_FILE} V81121
M400
; Checking the Call Id param for HMI
if exists(param.I)
	M118 S{"#I"^param.I^"#DONE"}
; -------------------------------------------------------------------------------------------
M118 S{"[bed_compensation_switch.g]Done "^var.CURRENT_FILE}
M99
