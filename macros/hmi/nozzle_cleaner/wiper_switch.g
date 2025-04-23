; Description: 	
;	This will enable or disable the wiping station.
;		it is a toggle macro. 
; ; Example:
;	M98 P"/macros/hmi/nozzle_cleaner/wiper_switch.g"
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/hmi/nozzle_cleaner/wiper_switch.g"
M118 S{"[wiper_check.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
;creating the global variables----------------------------------------------
if(!exists(global.wiperPresent))
	global wiperPresent = false
; checking for the status the wiper------------------------------------------
if(global.wiperPresent)
	set global.wiperPresent = false
	M98 P"/macros/report/event.g" Y{"Nozzle wiper disabled for the tools "} F{var.CURRENT_FILE} V71200
else
	set global.wiperPresent = true
	M98 P"/macros/report/event.g" Y{"Nozzle wiper enabled for the tools "} F{var.CURRENT_FILE} V71201
M400
M98 P"/macros/variable/save_number.g" N{"global.wiperPresent"} V{global.wiperPresent}
M400
; Checking the Call Id param for HMI
if exists(param.I)
	M118 S{"#I"^param.I^"#DONE"}
; -------------------------------------------------------------------------------------------
M118 S{"[wiper_switch.g]Done "^var.CURRENT_FILE}
M99
