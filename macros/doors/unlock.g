; Description:
;	This macro will unlock the doorlock if it is deemed safe to do so.
; Example:
;	M98 P"/macros/doors/unlock.g"
; -----------------------------------------------------------------------------
var CURRENT_FILE = "/macros/doors/unlock.g"
M118 S{"[unlock.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking for files first
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/doors/control.g"} F{var.CURRENT_FILE} E55200

; Checking global variables
M98 P"/macros/assert/abort_if.g"		R{!exists(global.MODULE_EMERGENCY)} 			Y{"Missing required module EMERGENCY"} 			  		F{var.CURRENT_FILE} E55201

M98 P"/macros/assert/abort_if.g"		R{!exists(global.emergencyDoorIsTriggered)} 	Y{"Missing global variable emergencyDoorIsTriggered"}	F{var.CURRENT_FILE} E55202
M98 P"/macros/assert/abort_if_null.g"	R{global.emergencyDoorIsTriggered} 				Y{"Global variable emergencyDoorIsTriggered is null"} 	F{var.CURRENT_FILE} E55203

M98 P"/macros/assert/abort_if.g"		R{!exists(global.doorIsLocked)} 				Y{"Missing global variable doorIsLocked"} 		  		F{var.CURRENT_FILE} E55204
M98 P"/macros/assert/abort_if_null.g"	R{global.doorIsLocked} 							Y{"Global variable doorIsLocked is null"} 		  		F{var.CURRENT_FILE} E55205

M98 P"/macros/assert/abort_if.g"		R{!exists(global.BED_HAZARD_TEMP)}				Y{"Missing global variable BED_HAZARD_TEMP"}			F{var.CURRENT_FILE}	E55206
M98 P"/macros/assert/abort_if_null.g"	R{global.BED_HAZARD_TEMP}						Y{"Global variable BED_HAZARD_TEMP is null"}			F{var.CURRENT_FILE}	E55207

M98 P"/macros/assert/abort_if.g"		R{!exists(global.BED_WARNING_TEMP)}				Y{"Missing global variable BED_WARNING_TEMP"}				F{var.CURRENT_FILE} E55208
M98 P"/macros/assert/abort_if_null.g"	R{global.BED_WARNING_TEMP}						Y{"Global variable BED_WARNING_TEMP is null"}				F{var.CURRENT_FILE} E55209

; -----------------------------------------------------------------------------
if(heat.heaters[0].current >= global.BED_HAZARD_TEMP)
	M98 P"/macros/report/warning.g" Y{"The bed temperature is above the hazardous bed temperature threshold. Door cannot be unlocked."} F{var.CURRENT_FILE} W55210
elif(heat.heaters[0].active < global.BED_HAZARD_TEMP)
	if((heat.heaters[0].current >= global.BED_WARNING_TEMP) && (heat.heaters[0].current < global.BED_HAZARD_TEMP))
		M98 P"/macros/report/warning.g" Y"The bed is hot (>80°C). Advice: Keep the door closed" F{var.CURRENT_FILE} W55200
		M98 P"/macros/doors/control.g" D0 ; Opening the door
		M118 S{"[unlock.g] Opened"}
	elif(heat.heaters[0].current < global.BED_WARNING_TEMP)
		M98 P"/macros/doors/control.g" D0 ; Opening the door
		M118 S{"[unlock.g] Opened"}
elif(heat.heaters[0].active >= global.BED_HAZARD_TEMP)
	M98 P"/macros/report/warning.g" Y{"The bed target temperature is above the hazardous bed temperature threshold. Door cannot be unlocked."} F{var.CURRENT_FILE} W55211

; -----------------------------------------------------------------------------
M118 S{"[unlock.g] Done "^var.CURRENT_FILE}
M99 ; Proper exit
