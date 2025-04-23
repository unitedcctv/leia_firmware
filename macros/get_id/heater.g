; Description:
;	Returns a new heater ID using the global variable heaterId.
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/get_id/fan.g"

; Generate the new ID ---------------------------------------------------------
if(!exists(global.heaterId))
	global heaterId = 0
else
	set global.heaterId = global.heaterId + 1

; Checking for out of limits
M98 P"/macros/assert/abort_if.g" R{(global.heaterId >= limits.heaters)} Y{"Current heaterId overflowed"} F{var.CURRENT_FILE} E60100
; -----------------------------------------------------------------------------
M99 ; Exit current macro