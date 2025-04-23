; Description: 	
;	To check whether the values of sensors available are in the valid range or not
; Input parameters:
; 	- N : Name of the target sensor. The unit may need to be included.
;	- A : Minimum allowed value of the specified sensor
;	- B : Maximum allowed value of the specified sensor
; Example:
; 	M98 P"/macros/sensors/sanity_check.g" N"power_ac[W]" A{lowerlimit} B{upperlimit}
;------------------------------------------------------------------------------
; Mandatory check before starting the file to sync all the input channels
if !inputs[state.thisInput].active
	M99

var CURRENT_FILE = "/macros/sensors/sanity_check.g"
M118 S{"[SENSORS] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}
; Checking global variables and input parameters ------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if.g" 	  R{!exists(sensors.analog)}  Y{"Missing sensors.analog"}  	 F{var.CURRENT_FILE} E67110
M98 P"/macros/assert/abort_if.g" 	  R{!exists(param.N)}  		  Y{"Please provide the sensor name, param N"} F{var.CURRENT_FILE} E67111
M98 P"/macros/assert/abort_if_null.g" R{param.N}				  Y{"Parameter N is null"}  	 F{var.CURRENT_FILE} E67112
M98 P"/macros/assert/abort_if.g" 	  R{param.N == ""}  		  Y{"Parameter N is empty"}  	 F{var.CURRENT_FILE} E67113
M98 P"/macros/assert/abort_if.g" 	  R{!exists(param.A)}  		  Y{"Please provide the minimum range, param A"} F{var.CURRENT_FILE} E67114
M98 P"/macros/assert/abort_if_null.g" R{param.A}				  Y{"Parameter A is null"}  	 F{var.CURRENT_FILE} E67115
M98 P"/macros/assert/abort_if.g" 	  R{!exists(param.B)}  		  Y{"Please provide the maximum range, param B"} F{var.CURRENT_FILE} E67117
M98 P"/macros/assert/abort_if_null.g" R{param.B}				  Y{"Parameter B is null"}  	 F{var.CURRENT_FILE} E67118
; Looking for the sensor ------------------------------------------------------
M98 P"/macros/sensors/find_by_name.g" N{param.N}
var sensorIndex = global.sensorIndex
; Storing  the value range in an array
var validRange = {param.A, param.B}
var sensorReading = sensors.analog[var.sensorIndex].lastReading
; Comparing the current value with the minimum and the maximum range
if((var.sensorReading <  var.validRange[0]) || (var.sensorReading > var.validRange[1]))
	M98 P"/macros/assert/abort.g" Y{"Sensor %s = %s is outside permitted range. Check connection"} A{param.N,var.sensorReading,var.validRange} F{var.CURRENT_FILE} E67119
else
	M118 S{"[SENSORS] Sensor "^param.N^" = "^var.sensorReading^" is in the valid range"^var.validRange}
; -----------------------------------------------------------------------------
M118 S{"[SENSORS] Done "^var.CURRENT_FILE}
M99