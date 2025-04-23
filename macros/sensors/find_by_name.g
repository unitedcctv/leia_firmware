; Description: 	
;	We will find the index of a sensor based on the name of it.
; Input parameters:
; 	- N : Name of the target sensor. The unit may need to be included.
; Output paramters:
;	- global.sensorIndex: null if not found, or a valid index from 0.
; Example:
; 	M98 P"/macros/sensors/find_by_name.g" N"power_ac[W]"
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/sensors/find_by_name.g"
M118 S{"[SENSORS] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Getting global variables prepared -------------------------------------------
if(!exists(global.sensorIndex))
	global sensorIndex = null
else 
	set global.sensorIndex = null

; Checking global variables and input parameters ------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if.g" 	  R{!exists(sensors.analog)}  Y{"Missing sensors.analog"}  	 F{var.CURRENT_FILE} E67100
M98 P"/macros/assert/abort_if.g" 	  R{!exists(param.N)}  		  Y{"Missing input parameter N"} F{var.CURRENT_FILE} E67101
M98 P"/macros/assert/abort_if_null.g" R{param.N}				  Y{"Parameter N is null"}  	 F{var.CURRENT_FILE} E67102
M98 P"/macros/assert/abort_if.g" 	  R{param.N == ""}  		  Y{"Parameter N is empty"}  	 F{var.CURRENT_FILE} E67103

; Looking for the sensor ------------------------------------------------------
var index = 0
while( (var.index < #sensors.analog) && ((sensors.analog[var.index] == null) || (sensors.analog[var.index].name != param.N)) )
	set var.index = var.index + 1

if( var.index < #sensors.analog )
	set global.sensorIndex = var.index
else
	M98 P"/macros/report/warning.g" Y{"Coundn't find a sensor with name: %s"} A{param.N,} F{var.CURRENT_FILE} W67110

; -----------------------------------------------------------------------------
M118 S{"[SENSORS] Done "^var.CURRENT_FILE}
M99