; Description: 	
;	This will start nozzle cleaning 
; Input parameter :
;					T - (optional) for specified Tool
;					no parameter - Wipe the currently active tool
;				  	F - (optional) FLUSH before wiping . 0 - Dont FLUSH.
;						1- FLUSH , default is 1
; Example:
;	M98 P"/macros/hmi/nozzle_cleaner/wipe.g" T0 F0
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/nozzle_cleaner/wipe.g"
M118 S{"[wipe.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Definitions----------------------------------------
; creating the global variable
if(!exists(global.manualWipe))
	global manualWipe = true
else
	set global.manualWipe = true
var FLUSH				= exists(param.F) && (param.F == 0) ? 0 : 1
; checking if the printer is printing
if (state.status == "processing")
	M25
M400
; calling the wipe macro
if(exists(param.T))
	M98 P"/macros/nozzle_cleaner/wipe.g" T{param.T} F{var.FLUSH}
else
	M98 P"/macros/nozzle_cleaner/wipe.g" F{var.FLUSH}
M400
set global.manualWipe = false
; Checking the Call Id param for HMI
if exists(param.I)
	M118 S{"#I"^param.I^"#DONE"}
;----------------------------------------------------
M118 S{"[wipe.g]Done "^var.CURRENT_FILE}
M99
