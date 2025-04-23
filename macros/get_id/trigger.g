; Description: 	
;	Returns a new trigger ID using the global variable triggerId.
;	NOTE: The triggers 0 and 1 are reserved:
;		Trigger number 0 causes an emergency stop as if M112 had been received.
;		Trigger number 1 causes the print to be paused as if M25 had been 
;		received. Any trigger number # greater than 1 causes the macro file 
;		/sys/trigger#.g to be executed.
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/get_id/trigger.g"

; Generate the new ID ---------------------------------------------------------
if(!exists(global.triggerId))
	global triggerId = 2 ; 0 and 1 are reserved for emergency and pause.
else
	set global.triggerId = global.triggerId + 1

; Checking for out of limits
M98 P"/macros/assert/abort_if.g" R{(global.triggerId >= limits.triggers)} Y{"Current triggerId overflowed"} F{var.CURRENT_FILE} E60500

; -----------------------------------------------------------------------------
M99 ; Exit current macro