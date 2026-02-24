; Description: 	
;	We set the tool offset to the print head reference point.
; Input Parameters:
;	- X: Offset in X
;	- Y: Offset in Y
;------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/extruders/basic_set_offset.g"
M118 S{"Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}
; Checking global variables and input parameters ------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{!exists(param.X)}  Y{"Missing required input parameter X"} F{var.CURRENT_FILE} E12643
M98 P"/macros/assert/abort_if_null.g" R{param.X}  	  Y{"Input parameter X is null"} F{var.CURRENT_FILE} E12644
M98 P"/macros/assert/abort_if.g" R{!exists(param.Y)}  Y{"Missing required input parameter Y"} F{var.CURRENT_FILE} E12645
M98 P"/macros/assert/abort_if_null.g" R{param.Y}  	  Y{"Input parameter Y is null"} F{var.CURRENT_FILE} E12646

; Changing the tool offset for T0
G10 P0 X{param.X} Y{param.Y}
M98 P"/macros/assert/result.g" R{result} Y"Unable to set the tool offset" F{var.CURRENT_FILE} E12647

; -----------------------------------------------------------------------------
M118 S{"Done "^var.CURRENT_FILE}
M99 ; Proper exit