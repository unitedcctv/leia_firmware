if(exists(global.sensorLog))
	if(global.sensorLog != "")
		set global.sensorLog = ""
		G4 S2 ; Wait to make sure the previous file is closed
	set global.sensorLog = "/sys/records/sensors_" ^ {+state.time} ^ ".csv"
else
	global sensorLog = "/sys/records/sensors_" ^ {+state.time} ^ ".csv"
M118 S{ "[SENSORS] Started recording in file: " ^ global.sensorLog }
M99 ; Proper exit