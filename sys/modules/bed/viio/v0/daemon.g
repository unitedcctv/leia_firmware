; Description: 	
;   This macro is used to control the bed idle cool down
; 	from the daemon script.
;   After 120 minutes if the machine is idle and bed is hot it automatically
;	turns off the bed heater.
;---------------------------------------------------------------------------------------------
var CURRENT_FILE		= "/sys/modules/bed/viio/v0/daemon.g"
; Definitions--------------------------------------------------------------------
var TURN_OFF_TEMP		= -273.1	;[°C]
var MIN_TEMP			= 0 		;[°C] temperature to turn off the bed
var	MAX_WAIT_TIME		= global.bedIdleWaitTime
if(exists(global.MODULE_BED) && exists(global.bedTempLastSetTime))
	var bedTempSet = heat.heaters[heat.bedHeaters[0]].active
	var bedTempLastSetTime	= global.bedTempLastSetTime
	var useCooldownTimer	= state.status == "idle"
	if((var.useCooldownTimer) && (var.bedTempSet > 0))				
		if((state.upTime - var.bedTempLastSetTime) > var.MAX_WAIT_TIME)
			; need to set to 0 first, otherwise the display temperature will not be updated
			M140 S{var.MIN_TEMP} R{var.MIN_TEMP}
			M98  P"/macros/assert/result.g" R{result} Y"Unable to set the bed temperature to var.MIN_TEMP" F{var.CURRENT_FILE} E10610
			M140 S{var.TURN_OFF_TEMP}
			M98  P"/macros/assert/result.g" R{result} Y"Unable to set the bed temperature to var.OFF_TEMP" F{var.CURRENT_FILE} E10611
			M118 S{"[SAFETY] Bed was ON for "^global.bedIdleWaitTime^" seconds: Turned off the bed heater"}
M99