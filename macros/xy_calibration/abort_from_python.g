if !inputs[state.thisInput].active
	M99
; Description:  
;	Report error that is send from HMI  
; Input parameters: 
;	- C: Folder name
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/xy_calibration/abort_from_python.g"
M98 P"/macros/assert/abort_if.g" R{!exists(param.C)} 		Y{"Missing required input parameter C"} F{var.CURRENT_FILE} E70400
M98 P"/macros/assert/abort_if_null.g" R{param.C}  	 		Y{"Input parameter C is null"} 		 	F{var.CURRENT_FILE} E70401
; report event for the user that the calibration failed
; report the error code to the HMI
if(param.C == -400)
	M98 P"/macros/assert/abort.g" Y{"XY calibration failed: No line was detected.Please repeat the calibration."}  F{var.CURRENT_FILE} E70410
elif(param.C == -401)
	M98 P"/macros/assert/abort.g" Y{"XY calibration failed: More then one peak detected. Please repeat the calibration."}  F{var.CURRENT_FILE} E70411
elif(param.C == -402)
	M98 P"/macros/assert/abort.g" Y{"XY calibration failed: Position deviation is to large. Please repeat the calibration."}  F{var.CURRENT_FILE} E70412
elif(param.C == -403)
	M98 P"/macros/assert/abort.g" Y{"XY calibration failed: Detected peak is to small. Please repeat the calibration."}  F{var.CURRENT_FILE} E70413
elif(param.C == -404)
	M98 P"/macros/assert/abort.g" Y{"XY calibration failed: No valid position found. Please repeat the calibration."}  F{var.CURRENT_FILE} E70414

; -----------------------------------------------------------------------------
M118 S{"[abort_from_python.g] Done "^var.CURRENT_FILE} 
M99
