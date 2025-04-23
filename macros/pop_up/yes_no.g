; Description: 	
;	Macro to call a pop-up with YES/NO options.
; Input Parameters:
;	- param.W: Message
;	- param.H: Header.  Default value is defined by enclose.g
;	- param.T: Timeout in sec. Default value is defined by enclose.g
; Output parameters:
;	- global.popUpResult ()
;		+ null:  	Errors (timeout, retries)
;		+ "YES": The HMI should change this value to "YES" before timeout.
;		+ "NO": The HMI should change this value to "NO" before timeout.
; Example:
;		M98 P"/macros/pop_up/yes_no.g" W"Are the circulation fans working?" H"Fans" T10
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/pop_up/yes_no.g"
M118 S{"[POPUP] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking for files first
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/pop_up/enclose.g"} F{var.CURRENT_FILE} E63300
; Checking input parameters
M98 P"/macros/assert/abort_if.g" R{!exists(param.W)}  Y{"Missing required input parameter W"}	F{var.CURRENT_FILE} E63301

; Getting input parameters if available ---------------------------------------
var HEADER =  { (exists(param.H)) ? param.H : null }
var TIMEOUT = { (exists(param.T)) ? param.T : null }

; Creating the pop up with the OK and ABORT options
M98 P"/macros/pop_up/enclose.g" W{param.W} H{var.header} T{var.timeout} C{"YES","NO"}

; -----------------------------------------------------------------------------
M118 S{"[POPUP] Done "^var.CURRENT_FILE}
M99 ; Exit