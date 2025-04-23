; Description: 	
;	Returns a new fan ID using the global variable fanId.
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/get_id/fan.g"

; Generate the new ID ---------------------------------------------------------
if(!exists(global.fanId))
	global fanId = 0 
else
	set global.fanId = global.fanId + 1

; Checking for out of limits
M98 P"/macros/assert/abort_if.g" R{(global.fanId >= limits.fans)} Y{"Current fanId overflowed"} F{var.CURRENT_FILE} E60000
; -----------------------------------------------------------------------------
M99 ; Exit current macro