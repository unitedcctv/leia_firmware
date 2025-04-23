; Capturing Z loads
if exists(global.sensorLog) && global.sensorLog != ""
	var toPrint	  	 = {""^{state.timeWithMs}^","}
	set var.toPrint  = {{var.toPrint}^{sensors.analog[19].lastReading}^","}
	set var.toPrint  = {{var.toPrint}^{sensors.analog[20].lastReading}^","}
	set var.toPrint  = {{var.toPrint}^{sensors.analog[21].lastReading}^","}
	set var.toPrint  = {{var.toPrint}^{sensors.analog[22].lastReading}^","}
	echo >>{global.sensorLog} var.toPrint
M99 ; Proper exit of a macro