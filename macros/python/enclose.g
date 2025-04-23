; Description: 
;	This gcode should be use only in macro files inside the folder:
;		/macros/python/
;	It should not be used directly from other gcode. This script is adding by
;	default a "CANCEL" button in order to support (J1) timeout. You may want
;	your own cancel button if you need it.
; Input parameters:
;	- W: Message of the pop-up.
;	- (optional) T: Timeout in seconds. The default value is 60 sec.
; TODO:
;	Warning if there is a timeout.
;------------------------------------------------------------------------------
var CURRENT_FILE 	= "/macros/python/call_function.g"

; Checking global variables and input parameters ------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{!exists(param.W)} 			Y{"Missing input parameter W"} 	F{var.CURRENT_FILE} E66110
M98 P"/macros/assert/abort_if_null.g" R{param.W} 				Y{"Input parameter W is null"} 	F{var.CURRENT_FILE} E66111

; Creating or setting global variables ----------------------------------------
if(!exists(global.pythonResult))
	global pythonResult = null
else
	set global.pythonResult = null

M598
; Definitions -----------------------------------------------------------------
var TIMEOUT_DEFAULT = 60 	 ; [sec] As default the timeout is 60 sec
var CALL_HEADER = "[PY]" 	 ; Header used by ComMQTT to know it is a python call
var MAX_CHARS_RESPONSE = 100 ; Max amount of characters accepted by the response.

; Getting input parameters
var timeout = var.TIMEOUT_DEFAULT ; [sec] Default timeout value
if( exists(param.T) && param.T != null ) 
	if( param.T == 0 ) 
		M98 P"/macros/report/warning.g" Y{"The timeout must be at least 1. Using default value."} F{var.CURRENT_FILE} W66120
	else 
		set var.timeout = param.T

; Creating a pop-up with the python call header -------------------------------
M291 P{param.W} R{var.CALL_HEADER} T{var.timeout} S7 J1 H{var.MAX_CHARS_RESPONSE} L0
M598
; Recording the final result --------------------------------------------------
set global.pythonResult = input ; Recording the result

; -----------------------------------------------------------------------------
M99 ; Proper exit