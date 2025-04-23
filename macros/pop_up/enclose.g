; Description: 
;	This gcode should be use only in macro files inside the folder:
;		/macros/pop_up/
;	It should not be used directly from other gcode. This script is adding by
;	default a "CANCEL" button in order to support (J1) timeout. You may want
;	your own cancel button if you need it.
; Input parameters:
;	- (optional) H: Header of the pop-up.
;	- W: Message of the pop-up.
;	- C: Choices. Example {"YES":"NO"}
;	- (optional) T: Timeout in seconds. The default value is 60 sec.
; Return values:
;	
; TODO:
; 	Support general array expressions and don't create a new array
;	that actually depends on the size of the input param.
; Related Issue:
;	https://github.com/Duet3D/RepRapFirmware/issues/873
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/pop_up/enclose.g"

; Checking global variables and input parameters ------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{!exists(param.W)} Y{"Missing required input parameter W"} F{var.CURRENT_FILE} E63000
M98 P"/macros/assert/abort_if_null.g" R{param.W}  	 Y{"Input parameter W is null"} 		 F{var.CURRENT_FILE} E63001	
M98 P"/macros/assert/abort_if.g" R{!exists(param.C)} Y{"Missing required input parameter C"} F{var.CURRENT_FILE} E63002
M98 P"/macros/assert/abort_if_null.g" R{param.C}  	 Y{"Input parameter C is null"} 		 F{var.CURRENT_FILE} E63003	

; Definitions -----------------------------------------------------------------
var TIMEOUT_DEFAULT = 60 	; [sec] As default the timeout is 60 sec
var HEADER_DEFAULT 	= ""	; No header as default.
var CHOICES_MAX  	= 5		; See related issue 873 (RepRapFirmware)

; Checking the amount of choises
var CHOICES = #param.C
; The next error is related to: https://github.com/Duet3D/RepRapFirmware/issues/873
; TODO: Remove this once it is supported
M98 P"/macros/assert/abort_if.g" R{(var.CHOICES > var.CHOICES_MAX)} Y{"Too many choices."} F{var.CURRENT_FILE} 	E63004

; Getting input parameters
var timeout = var.TIMEOUT_DEFAULT ; [sec] Default timeout value
if( exists(param.T) && param.T != null ) 
	if( param.T == 0 ) 
		M98 P"/macros/report/warning.g" Y{"The timeout must be at least 1. Using default value."} F{var.CURRENT_FILE} W63000
	else 
		set var.timeout = param.T

var HEADER = { (exists(param.H) && param.H != null) ? param.H : var.HEADER_DEFAULT }

; Creating or seeting global variables.
if(!exists(global.popUpResult))
	global popUpResult = null
else
	set global.popUpResult = null

if   var.CHOICES == 1
	if(var.HEADER == "")
		M291 P{param.W} T{var.timeout} S4 J1 K{param.C[0],}
	else
		M291 P{param.W} R{var.HEADER} T{var.timeout} S4 J1 K{param.C[0],}
elif var.CHOICES == 2
	if(var.HEADER == "")
		M291 P{param.W} T{var.timeout} S4 J1 K{param.C[0],param.C[1]}
	else
		M291 P{param.W} R{var.HEADER} T{var.timeout} S4 J1 K{param.C[0],param.C[1]}
elif var.CHOICES == 3
	if(var.HEADER == "")
		M291 P{param.W} T{var.timeout} S4 J1 K{param.C[0],param.C[1],param.C[2]}
	else
		M291 P{param.W} R{var.HEADER} T{var.timeout} S4 J1 K{param.C[0],param.C[1],param.C[2]}
elif var.CHOICES == 4
	if(var.HEADER == "")
		M291 P{param.W} T{var.timeout} S4 J1 K{param.C[0],param.C[1],param.C[2],param.C[3]}
	else
		M291 P{param.W} R{var.HEADER} T{var.timeout} S4 J1 K{param.C[0],param.C[1],param.C[2],param.C[3]}
elif var.CHOICES == 5
	if(var.HEADER == "")
		M291 P{param.W} R{var.HEADER} T{var.timeout} S4 J1 K{param.C[0],param.C[1],param.C[2],param.C[3],param.C[4]}
	else
		M291 P{param.W} T{var.timeout} S4 J1 K{param.C[0],param.C[1],param.C[2],param.C[3],param.C[4]}

var RESPONSE = input
var RESPONSE_NOT_VALID = (var.RESPONSE >= var.CHOICES || 0 > var.RESPONSE)
M98 P"/macros/assert/abort_if.g" R{var.RESPONSE_NOT_VALID} Y{"Returned response is not valid."} F{var.CURRENT_FILE} E63005

set global.popUpResult = param.C[input]

; -----------------------------------------------------------------------------
M99 ; Proper exit