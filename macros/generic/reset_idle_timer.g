; Description: 	
;   This macro is used to reset the bed and the Extruder idle cool down timer.
;               Example : M98 P"/macros/generic/reset_idle_timer.g"
;---------------------------------------------------------------------------------------------
var CURRENT_FILE		= "/macros/generic/reset_idle_timer.g"
M118 S{"[GENERIC] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}
; Definitions--------------------------------------------------------------------
M98 P"/macros/assert/abort_if.g" R{(!exists(global.bedTempLastSetTime))} Y{"Missing global.bedTempLastSetTime"} F{var.CURRENT_FILE} E59010
M98 P"/macros/assert/abort_if.g" R{(!exists(global.exTempLastSetTimes))} Y{"Missing global.exTempLastSetTimes"} F{var.CURRENT_FILE} E59011
M98 P"/macros/assert/abort_if.g" R{(!exists(global.cbcLastSetTime))} Y{"Missing global.exTempLastSetTimes"} F{var.CURRENT_FILE} E59012

; Flag to reset the timer------------------------------------------------------
; (!)Default is to wait until 20 mins------------------------------------------
; Reset the timer-------------------------------------------------------------
set global.bedTempLastSetTime = state.upTime
set global.cbcLastSetTime = state.upTime
if(exists(global.MODULE_EXTRUDER_0))
    set global.exTempLastSetTimes[0] = {state.upTime}
if(exists(global.MODULE_EXTRUDER_1))
    set global.exTempLastSetTimes[1] = {state.upTime}
M118 S{"Reset all the idle wait timers"}
; -----------------------------------------------------------------------------
M118 S{"[GENERIC] Done "^var.CURRENT_FILE}
M99