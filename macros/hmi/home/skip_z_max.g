; Description: 	
;This is a HMI command macro to skip the home to Zmax
;--------------------------------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/hmi/home/skip_z_max.g"
M118 S{"[skip_z_max.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}
; setting the global variable to current time
if(exists(global.homedToZmax))
	set global.homedToZmax = state.time
else
	global homedToZmax = state.time
; ----------------------------------
; Checking the Call Id param for HMI
if exists(param.I)
	M118 S{"#I"^param.I^"#DONE"}
;--------------------------------------------------------------------------------
M118 S{"[skip_z_max.g] Done "^var.CURRENT_FILE}
M99		;Proper file exit