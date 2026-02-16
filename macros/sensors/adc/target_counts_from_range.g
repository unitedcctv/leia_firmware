; Description: 	
; 	Based on a target distance [um] (param.D), the adc range value will be 
;	calculated. The target distance param.D should be in the range delimited by 
;	param.B and param.T. 
; 	The resulting value will be returned in global.adcTargetCounts and 
;	it should be in the range: [0..(global.ADC_MAXIMUM_RANGE - 1)], but
;	if there is an error, null will be returned instead. 
; Input parameters:
; 	- D : [] target value 
;	- B	: [] Min value in um when the ADC is reporting 0.
;	- T : [] Max value in um when the ADC is reporting var.ADC_MAXIMUM_RANGE.
; Output parameters:
;	- global.adcTargetCounts: [] it should be in the range: 
;		[0..var.ADC_MAXIMUM_RANGE], but if there is an error, 
;		null will be returned instead. 
; Example:
; 	M98 P"/macros/sensors/adc/target_counts_from_range.g" T6000 B-5000 D-1500
; 	M98 P"/macros/assert/abort_if_null.g" R{global.adcTargetCounts} Y{"Failed getting the range"}  	F{var.CURRENT_FILE} E12345
;------------------------------------------------------------------------------
var CURRENT_FILE 	= "/macros/sensors/adc/target_counts_from_range.g"
; M118 S{"[PROBE] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Set global return variables -------------------------------------------------
if(!exists(global.adcTargetCounts))
	global adcTargetCounts = null
else
	set global.adcTargetCounts = null

; Checking global variables and input parameters ------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if.g" 	  R{!exists(param.D)}  	Y{"Missing parameter D"}  			F{var.CURRENT_FILE} E67400
M98 P"/macros/assert/abort_if_null.g" R{param.D}  			Y{"Input parameter D is null"}  	F{var.CURRENT_FILE} E67401
M98 P"/macros/assert/abort_if.g" 	  R{!exists(param.B)}  	Y{"Missing parameter B"}  			F{var.CURRENT_FILE} E67402
M98 P"/macros/assert/abort_if_null.g" R{param.B}  			Y{"Input parameter B is null"}  	F{var.CURRENT_FILE} E67403
M98 P"/macros/assert/abort_if.g" 	  R{!exists(param.T)}  	Y{"Missing parameter T"}  			F{var.CURRENT_FILE} E67404
M98 P"/macros/assert/abort_if_null.g" R{param.T}  			Y{"Input parameter T is null"}  	F{var.CURRENT_FILE} E67405

M98 P"/macros/assert/abort_if.g" 	  R{(param.T == param.B)}  	Y{"Input parameters T and B are equal"}  			F{var.CURRENT_FILE} E67406
M98 P"/macros/assert/abort_if.g" 	  R{(param.D > param.T)}  	Y{"Input parameters D is bigger than T"}  			F{var.CURRENT_FILE} E67407
M98 P"/macros/assert/abort_if.g" 	  R{(param.D < param.B)}  	Y{"Input parameters D is smaller than B"}  			F{var.CURRENT_FILE} E67408
; Definitions -----------------------------------------------------------------
var FULL_RANGE 			= (param.T - param.B) 	; [] Full range 
; Get the linear increase per count of the ADC.
var ADC_MAXIMUM_RANGE 	= (pow(2,16)-1)	; The readings we pass in should be
										; in range:
										;	[0..ADC_MAXIMUM_RANGE]
var LINEAR_INCREASE_PER_COUNT = ( var.ADC_MAXIMUM_RANGE / var.FULL_RANGE )

; Doing the math --------------------------------------------------------------
var range = floor((param.D - param.B) * var.LINEAR_INCREASE_PER_COUNT)
; This should not occure but let's limit in case there is an error
set var.range = max(0, var.range)
set var.range = min(var.range, var.ADC_MAXIMUM_RANGE)
; Return the value
set global.adcTargetCounts = var.range

M118 S{"[SENSORS] For a analog input with range ("^param.B^","^param.T^") the point "^param.D^" corresponds to "^global.adcTargetCounts}

; -----------------------------------------------------------------------------
; M118 S{"[PROBE] Done "^var.CURRENT_FILE}
M99 ; Proper exit