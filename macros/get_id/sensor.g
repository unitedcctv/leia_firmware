;; Description: 	
;	Returns a new sensor ID using the global variable sensorId.
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/get_id/sensor.g"

; Generate the new ID ---------------------------------------------------------
if(!exists(global.sensorId))
	global sensorId = 0
else
	set global.sensorId = global.sensorId + 1

; Checking for out of limits
M98 P"/macros/assert/abort_if.g" R{(global.sensorId >= limits.sensors)} Y{"Current sensorId overflowed"} F{var.CURRENT_FILE} E60400
; -----------------------------------------------------------------------------
M99 ; Exit current macro