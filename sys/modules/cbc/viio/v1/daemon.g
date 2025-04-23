; Description: 	
;   This daemon macro is used to control the CBC temperature
;---------------------------------------------------------------------------------------------
if(!exists(global.MODULE_CBC))
	M99 ; Exit
var CURRENT_FILE = "/sys/modules/cbc/viio/v1/daemon.g"
; Definitions--------------------------------------------------------------------

var cbcZ0CurrentTemp	= sensors.analog[global.CBC_TEMP_SENSOR_A].lastReading
var cbCZ0LastTemp 		= 0
var doorClosed 			= {(exists(global.emergencyDoorIsTriggered) && (!global.emergencyDoorIsTriggered)) ? true : false}
var cbcOn 				= {fans[global.CBC_HEATER].requestedValue > 0.0}
var cbcFansOn 			= {fans[global.FAN_EXHAUST_A].requestedValue > 0.0 || fans[global.FAN_EXHAUST_B].requestedValue > 0.0}
var	MAX_WAIT_TIME		= global.cbcIdleWaitTime
var HEATER_ON			= global.cbcTargetTemperature > 0.0
var CBC_HEATER_PERIOD 	= 5	; [s] arbitrary value to delay execution of heater control to every n-th second
var cbcSBLastTemp		= 0

; PID control parameter
var K_P				= 0.6
var K_I				= 1.2
var K_D				= 0.075

; Safety check -----------------------------------------------------------------------
; Turn off the cbc heaters when the idle wait time is over
if(var.HEATER_ON && (state.status == "idle"))
	if(((state.upTime - global.cbcLastSetTime) > var.MAX_WAIT_TIME))
		M98 P"/macros/cbc/set_temperature.g" T0
		M98 P"/macros/report/warning.g" Y{"[SAFETY] Idle cool down wait time expired for the cbc "}  F{var.CURRENT_FILE} W11191
	; --------------------------------------------------------------------------------
; If CBC temperature measured on top- or at stageboard-level is above global.CBC_HAZARDOUS_TEMP, perform emergency restart
if((var.cbcZ0CurrentTemp > global.CBC_HAZARDOUS_TEMP) || (var.cbcSBLastTemp > global.CBC_HAZARDOUS_TEMP))
	set global.hmiStateDetail = "error_cbc_overtemp"
	M98 P"/macros/report/event.g" Y{"Build Chamber Temperature > %s°C. Machine Halted. Please restart"} A{global.CBC_HAZARDOUS_TEMP,} F{var.CURRENT_FILE} V11191
	M42 P{global.EMERGENCY_DISABLE_CTRL} S0 ; trip safety relay
	M112

; CBC Temperature Control----------------------------------------------------------
if(exists(global.cbcTargetTemperature))

	; if CBC is turned off...
	if(global.cbcTargetTemperature <= 0.0 || !var.doorClosed)

		; Make sure heaters are turned off
		if(var.cbcOn)
			M106 P{global.CBC_HEATER} S0.0
		if(var.cbcFansOn)
			M106 P{global.FAN_EXHAUST_A} S0.0
			M106 P{global.FAN_EXHAUST_B} S0.0

		; if max_temp is overshot or forceFansOn is triggered, ...
		if((var.cbcZ0CurrentTemp > global.CBC_MAX_TEMP) || global.cbcForceFansOn) 
			; turn on exhaust fans to evacuate hot air
			if(!var.cbcFansOn)
				M106 P{global.FAN_EXHAUST_A} S1.0
				M106 P{global.FAN_EXHAUST_B} S1.0

	; if CBC is turned on...
	else
		; calculate PID values
		var PID_ERROR	= global.cbcTargetTemperature - var.cbcZ0CurrentTemp
		var PID_DT		= state.upTime - global.cbcHeaterLastUpdate + (state.msUpTime/1000.0)
		var PID_D_ERROR	= (var.PID_ERROR - global.cbcPIDPrevError) / var.PID_DT

		set global.cbcPIDPrevErrorInt = global.cbcPIDPrevErrorInt + var.PID_ERROR * var.PID_DT

		var PID_PROP	= var.K_P * var.PID_ERROR	; e
		var PID_DIFF	= var.K_D * var.PID_D_ERROR  ; calculate gradient of error
		var PID_INT		= var.K_I * global.cbcPIDPrevErrorInt
		var pIDCorrection = var.PID_PROP + var.PID_DIFF + var.PID_INT
		; normalize pIDCorrection to [0,1] to use as PWM value for fan control
		set var.pIDCorrection = max(0, min(1.0, var.pIDCorrection))

		; make sure doors are closed
		if(var.doorClosed)
			; execute every CBC_HEATER_PERIOD'th cycle only
			if( (global.cbcHeaterLastUpdate + var.CBC_HEATER_PERIOD) <= state.upTime )
				; if current temp >= target temp...
				if(var.cbcZ0CurrentTemp >= global.cbcTargetTemperature)	
					; turn off heater
					M106 P{global.CBC_HEATER} S0
				else 
					; turn on heater
					M106 P{global.CBC_HEATER} S1
					
				; regulate exhaustfans between [0.1 - 1.0] to avoid turning off fans
				M106 P{global.FAN_EXHAUST_A} S{1.0 - 0.9 * var.pIDCorrection}
				M106 P{global.FAN_EXHAUST_B} S{1.0 - 0.9 * var.pIDCorrection}

				; update lastUpdate with current time
				set global.cbcHeaterLastUpdate 	= state.upTime + (state.msUpTime/1000.0)

			; update lastTemp with current temperature & PID control
			set global.cbcZ0LastTemp 		= var.cbcZ0CurrentTemp
			set global.cbcPIDPrevError		= var.PID_ERROR

M99 ; Exit