; Description: 	
;	We set the tool offset to the print head reference point (the ball sensor).
; Input Parameters:
;	- T: Tool 0 or 1 to change the offset
;	- X: Offset in X
;	- Y: Offset in Y
;------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/extruders/basic/set_offset.g"
M118 S{"Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}
; Checking global variables and input parameters ------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{!exists(param.T)}  Y{"Missing required input parameter T"} F{var.CURRENT_FILE} E12640
M98 P"/macros/assert/abort_if_null.g" R{param.T}  	  Y{"Input parameter T is null"} F{var.CURRENT_FILE} E12641
M98 P"/macros/assert/abort_if.g" R{(param.T>=2||param.T<0)}  Y{"Unexpected tool value"} F{var.CURRENT_FILE} E12642
M98 P"/macros/assert/abort_if.g" R{!exists(param.X)}  Y{"Missing required input parameter X"} F{var.CURRENT_FILE} E12643
M98 P"/macros/assert/abort_if_null.g" R{param.X}  	  Y{"Input parameter X is null"} F{var.CURRENT_FILE} E12644
M98 P"/macros/assert/abort_if.g" R{!exists(param.Y)}  Y{"Missing required input parameter Y"} F{var.CURRENT_FILE} E12645
M98 P"/macros/assert/abort_if_null.g" R{param.Y}  	  Y{"Input parameter Y is null"} F{var.CURRENT_FILE} E12646

; Changing the tool offset
G10 P{param.T} X{param.X} Y{param.Y}
M98 P"/macros/assert/result.g" R{result} Y"Unable to set the tool offset" F{var.CURRENT_FILE} E12647

; -----------------------------------------------------------------------------
M118 S{"Done "^var.CURRENT_FILE}
M99 ; Proper exit