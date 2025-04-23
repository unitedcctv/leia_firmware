; Capturing Z loads
if exists(global.sensorLog) && global.sensorLog != null &&  global.sensorLog != ""
	var FILE = global.sensorLog
	var CSV_DELIMITER = ","
	if(!fileexists(var.FILE))
		echo >>>{var.FILE} {"Time" ^ var.CSV_DELIMITER}
		echo >>>{var.FILE} {"Line" ^ var.CSV_DELIMITER}
		var iNameSensor = 0
		while var.iNameSensor < #move.axes
			echo >>>{var.FILE} { move.axes[var.iNameSensor].letter ^ var.CSV_DELIMITER}
			set var.iNameSensor = var.iNameSensor + 1
		set var.iNameSensor = 0
		while var.iNameSensor < #sensors.analog
			echo >>>{var.FILE} { sensors.analog[var.iNameSensor].name ^ var.CSV_DELIMITER}
			set var.iNameSensor = var.iNameSensor + 1
		echo >>{var.FILE} ""
	var iSensor = 0
	echo >>>{var.FILE} { state.timeWithMs ^ var.CSV_DELIMITER}
	echo >>>{var.FILE} { inputs[2].lineNumber ^ var.CSV_DELIMITER}
	while var.iSensor < #move.axes
		echo >>>{var.FILE} { move.axes[var.iSensor].machinePosition ^ var.CSV_DELIMITER}
		set var.iSensor = var.iSensor + 1
	set var.iSensor = 0
	while var.iSensor < #sensors.analog
		echo >>>{var.FILE} { sensors.analog[var.iSensor].lastReading ^ var.CSV_DELIMITER}
		set var.iSensor = var.iSensor + 1
	echo >>{var.FILE} ""		
M99 ; Proper exit of a macro