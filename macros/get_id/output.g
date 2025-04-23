; Description: 	
;	Returns a new general purpose output ID using the global variable outputID.
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/get_id/output.g"

; Generate the new ID ---------------------------------------------------------
if(!exists(global.outputId))
	global outputId = 0 
else
	set global.outputId = global.outputId + 1

; Checking for out of limits
M98 P"/macros/assert/abort_if.g" R{(global.outputId >= limits.gpOutPorts)} Y{"Current outputId overflowed"} F{var.CURRENT_FILE} E60300
; -----------------------------------------------------------------------------
M99 ; Exit current macro