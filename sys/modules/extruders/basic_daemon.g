; Description:
;   This macro is used to control the Extruder idle cool down
; 	from the daemon script.
;   After 20 minutes if the machine is idle and extruders are hot it automatically
;	turns off the extruders.
;---------------------------------------------------------------------------------------------
var CURRENT_FILE		= "/sys/modules/extruders/basic_daemon.g"
; Definitions--------------------------------------------------------------------
var OPEN_CIRCUIT_TEMP	= 2000		;[°C]
var TURN_OFF_TEMP		= -273.1	;[°C]
var MIN_TEMP			= 0 		;[°C] Value to use when the tool is off
var	MAX_WAIT_TIME		= global.tooldleWaitTime ; [s]
var NOZZLE_TEMP_DELTA_TOLERANCE	= 15		;[°C] allowed difference between the two temperature sensors in both extruders
									;eg., temp_t0 - temp_aux_t0 should be +/- 15[°C]
									;temp_t1 - temp_aux_t1 should be +/- 15[°C]
; Check for the temperatures in both extruders if exists-------------------------
; only printing if we are processing gcode and not in a macro
var IS_PRINTING = (state.status == "processing") && (inputs[2].stackDepth == 0)
var IN_EMULATOR = (network.hostname == "emulator")

while true
	; --------------------------------------------------------------------------------
	; loop management
	; --------------------------------------------------------------------------------
	; main loop exit condition
	if iterations >= #tools
		break

	if tools[iterations] == null
		continue
	; --------------------------------------------------------------------------------
	; daemon task
	; --------------------------------------------------------------------------------
	var TOOL			= iterations
	var TOUCH_OBSTACLE_TOLERANCE = exists(global.touchBedObstacleThresholds) ? global.touchBedObstacleThresholds[var.TOOL] : null;[mV] or [mm]
	var TOOL_POSITIONED	= (state.currentTool == var.TOOL) && (abs(move.axes[3+var.TOOL].machinePosition - move.axes[3+var.TOOL].min) < 0.1 )
	var HEATER_ID		= tools[var.TOOL].heaters[0]
	var HEATER_ON		= heat.heaters[var.HEATER_ID].active > 0
	var TEMP_MAX 		= heat.heaters[var.HEATER_ID].max
	var TEMP_CUR_MAIN 	= heat.heaters[var.HEATER_ID].current
	var TEMP_CUR_AUX	= exists(global.toolAuxTempIDs[var.TOOL]) ? sensors.analog[global.toolAuxTempIDs[var.TOOL]].lastReading : null
	var TOUCH_SENS_ID			= (exists(global.TOUCH_BED_SENSOR_IDS[var.TOOL]) && (global.TOUCH_BED_SENSOR_IDS[var.TOOL] != null)) ? global.TOUCH_BED_SENSOR_IDS[var.TOOL] : null
	var CUR_VALUE_TOUCH_SENS 	= var.TOUCH_SENS_ID != null ? sensors.analog[var.TOUCH_SENS_ID].lastReading : null
	var CAL_VALUE_TOUCH_SENS 	= (exists(global.touchSensorPrintPosValues)&&(global.touchSensorPrintPosValues[var.TOOL] != null)) ? global.touchSensorPrintPosValues[var.TOOL]: null
	var touchSensDiff	= 0
	var TOOL_OFF_BUT_ACTIV_TEMP		= (heat.heaters[var.HEATER_ID].state == "off") && var.HEATER_ON
	; setting the active and standby temp to turn off temp
	if(var.TOOL_OFF_BUT_ACTIV_TEMP)
		M568 P{var.TOOL} S{var.MIN_TEMP} R{var.MIN_TEMP} A0 ;Setting extruder temp to 0 first
		M568 P{var.TOOL} S{var.TURN_OFF_TEMP} R{var.TURN_OFF_TEMP} A0 ;Setting extruder temp to off temp

	; --------------------------------------------------------------------------------
	;Tool positioning check
	;if(var.IS_PRINTING && global.toolPositioningFailed[var.TOOL])
	;	M98 P"/macros/report/warning.g" Y{"T%s positioning failed. Run lifter test. Pausing.."} A{var.TOOL,var.touchSensDiff} F{var.CURRENT_FILE} W12686
	;	set global.hmiStateDetail = "error_obstacle"
	;	M25
	; --------------------------------------------------------------------------------

	; --------------------------------------------------------------------------------
	;Obstacle detection
	if(var.IS_PRINTING && var.TOOL_POSITIONED && (var.TOUCH_OBSTACLE_TOLERANCE != null))

		if global.touchLinearInstalled[var.TOOL]
			; use the touch sensor as position encoder for obstacle detection if installed
			set var.touchSensDiff = abs(move.axes[3+var.TOOL].machinePosition - sensors.analog[global.TOUCH_BED_SENSOR_IDS[var.TOOL]].lastReading)
		elif ((var.CAL_VALUE_TOUCH_SENS != null) && (var.CUR_VALUE_TOUCH_SENS != null))
			set var.touchSensDiff = abs(var.CUR_VALUE_TOUCH_SENS - var.CAL_VALUE_TOUCH_SENS)

		if (var.touchSensDiff > var.TOUCH_OBSTACLE_TOLERANCE && !global.toolPositioningFailed[var.TOOL])
			; we have an obstacle
			M98 P"/macros/report/warning.g" Y{"T%s obstacle detected. Sensor diff: %s . Pausing.."} A{var.TOOL,var.touchSensDiff} F{var.CURRENT_FILE} W12687
			set global.hmiStateDetail = "error_obstacle"
			M25
	; --------------------------------------------------------------------------------

	; --------------------------------------------------------------------------------
	; checking the current temperature is within the allowed maximum limit
	; TODO : Have to define the behaviour for open circuit
	if((var.TEMP_CUR_MAIN > var.TEMP_MAX) && (var.TEMP_CUR_MAIN < var.OPEN_CIRCUIT_TEMP ))
		M98 P"/macros/report/warning.g" Y{"T%s nozzle over maximum allowed temperature"} A{var.TOOL,} F{var.CURRENT_FILE} W12681
		M957 E"heater_fault" D{var.HEATER_ID} B81 S{"heater_fault in T"^var.TOOL}
	; --------------------------------------------------------------------------------

	; --------------------------------------------------------------------------------
	; if we have 2 temp sensors and the heater is ON, check sensor difference
	if(var.HEATER_ON && (var.TEMP_CUR_AUX != null))
		; Definition for the safety tolerance temperature
		var TEMP_DELTA = var.TEMP_CUR_MAIN - var.TEMP_CUR_AUX
		; Raise heater fault when the temperature difference is out of tolerance limit
		if((abs(var.TEMP_DELTA) > var.NOZZLE_TEMP_DELTA_TOLERANCE))
			M98 P"/macros/report/warning.g" Y{"Temperature difference of %s for T%s exceeds allowed"} A{var.TEMP_DELTA,var.TOOL,var.NOZZLE_TEMP_DELTA_TOLERANCE} F{var.CURRENT_FILE} W12682
			M957 E"heater_fault" D{var.HEATER_ID} B81 S{"heater_fault in T"^var.TOOL}
	; --------------------------------------------------------------------------------

	; --------------------------------------------------------------------------------
	; Turn off the extruder heaters when the idle wait time is over
	if(var.HEATER_ON && ((state.status == "idle") || (state.status == "paused")))
		if((state.upTime - global.exTempLastSetTimes[var.TOOL]) > var.MAX_WAIT_TIME)
			M568 P{var.TOOL} S{var.MIN_TEMP} R{var.MIN_TEMP} A0 ;Setting extruder temp to 0 first
			M568 P{var.TOOL} S{var.TURN_OFF_TEMP} R{var.TURN_OFF_TEMP} A0 ;Setting extruder temp to off temp
			M98 P"/macros/report/warning.g" Y{"[SAFETY] Idle cool down wait time expired for T%s"} A{var.TOOL,}  F{var.CURRENT_FILE} W12683
	; --------------------------------------------------------------------------------

M99