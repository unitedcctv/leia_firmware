; Description: 	
;	Returns a new general purpose input ID using the global variable fanId.
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/get_id/input.g"

; Generate the new ID ---------------------------------------------------------
if(!exists(global.inputId))
	global inputId = 0 
else
	set global.inputId = global.inputId + 1

; Checking for out of limits
M98 P"/macros/assert/abort_if.g" R{(global.inputId >= limits.gpInPorts)}  	Y{"Current inputId overflowed"} F{var.CURRENT_FILE} E60200
; -----------------------------------------------------------------------------
M99 ; Exit current macro