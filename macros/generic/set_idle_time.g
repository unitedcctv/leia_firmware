; Description: 	
;   This macro is used to  the Extruder and bed idle cool down timer.
;   By default ,after 20 minutes if the machine is idle and extruders are hot it automatically
;	turns off the extruders.
;   Input Parameter , T: Idle cool down Waiting time in minutes for the extruders
;                     B: Idle cool down Waiting time in minutes for the bed
;					  C: Idle cool down Waiting time in minutes for the cbc
;               Example : M98 P"/macros/generic/set_idle_time.g" T12 B20 C10
;---------------------------------------------------------------------------------------------
var CURRENT_FILE		= "/macros/generic/set_idle_time.g"
; Definitions--------------------------------------------------------------------
M118 S{"[set_idle_time.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

if(exists(param.T))
	M98 P"/macros/assert/abort_if.g" 	R{(!exists(global.tooldleWaitTime))} 		Y{"Missing global.tooldleWaitTime"} F{var.CURRENT_FILE} E59001
	M98 P"/macros/assert/abort_if_null.g" 	R{param.T} 		Y{"Entered waiting time is null"} F{var.CURRENT_FILE} E59002
	M98 P"/macros/assert/abort_if.g" 	R{(param.T < 1)} 		Y{"Entered waiting time is invalid"} F{var.CURRENT_FILE} E59003
if(exists(param.B))
	M98 P"/macros/assert/abort_if.g" 	R{(!exists(global.bedIdleWaitTime))} 		Y{"Missing global.bedIdleWaitTime"} F{var.CURRENT_FILE} E59004
	M98 P"/macros/assert/abort_if_null.g" 	R{param.B} 		Y{"Entered waiting time is null"} F{var.CURRENT_FILE} E59005
	M98 P"/macros/assert/abort_if.g" 	R{(param.B < 1)} 		Y{"Entered waiting time is invalid"} F{var.CURRENT_FILE} E59006
if(exists(param.C))
	M98 P"/macros/assert/abort_if.g" 	R{(!exists(global.cbcIdleWaitTime))} 		Y{"Missing global.cbcIdleWaitTime"} F{var.CURRENT_FILE} E59007
	M98 P"/macros/assert/abort_if_null.g" 	R{param.C} 		Y{"Entered waiting time is null"} F{var.CURRENT_FILE} E59008
	M98 P"/macros/assert/abort_if.g" 	R{(param.C < 1)} 		Y{"Entered waiting time is invalid"} F{var.CURRENT_FILE} E59009

if (!exists(param.T) && !exists(param.B) && !exists(param.C))
	M98 P"/macros/assert/abort.g" Y{"please enter atleast one parameter T, B or C"} F{var.CURRENT_FILE} E59014
	M99
; Reset the timer-------------------------------------------------------------
set global.tooldleWaitTime = (exists(param.T) ? ((param.T) * 60): global.tooldleWaitTime)
set global.bedIdleWaitTime = (exists(param.B) ? ((param.B) * 60) : global.bedIdleWaitTime)
set global.cbcIdleWaitTime = (exists(param.C) ? ((param.C) * 60) : global.cbcIdleWaitTime)
; -----------------------------------------------------------------------------
M118 S{"[set_idle_time.g] Done "^var.CURRENT_FILE}
M99