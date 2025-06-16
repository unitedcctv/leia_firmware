; Configure OOF sensors for extruder
; Input Parameters:
;	- T: Tool 0 or 1 where the filament monitor is connected
; Example:
;	M98 P"/sys/modules/extruders/oof/v0/config.g" T0
;------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/extruders/oof/v0/config.g"

; Checking global variables and input parameters ------------------------------
M98 P"/macros/assert/abort_if.g" R{!exists(param.T)}  Y{"Missing required input parameter T"} 	F{var.CURRENT_FILE} E12650
M98 P"/macros/assert/abort_if_null.g" R{param.T}  	  Y{"Input parameter T is null"} 			F{var.CURRENT_FILE} E12651
M98 P"/macros/assert/abort_if.g" R{(param.T>=2||param.T<0)}  Y{"Unexpected tool value"} 		F{var.CURRENT_FILE} E12652

; DEFINITIONS -----------------------------------------------------------------
var SENSOR_TYPE 	= "linear-analog"				; Type of sensor used
var SENSOR_INPUT 	= "io2.in"						; Analog input used in the OOF
var SENSOR_INPUT_RETMOD = "detect"					; Analog input used in the retraction module
; CAN-FD ID related to the board.
var BOARD_CAN_ID		= {20 + param.T} 			 	; As a number
var CAN_ID_NAME			= {""^var.BOARD_CAN_ID} 		; As a string
var SENSOR_PORT_OOF		= {var.CAN_ID_NAME^"."^var.SENSOR_INPUT}	; OOF Sensor port
var SENSOR_NAME_OOF 	= {"oof_t"^param.T^"[mV]"}		; Name used to idenfity the OOF sensor

var SENSOR_PORT_RETMOD	= {var.CAN_ID_NAME^"."^var.SENSOR_INPUT_RETMOD}	; Retraction module sensor port
var SENSOR_NAME_RETMOD 	= {"retract_mod_t"^param.T^"[mV]"}		; Name used to idenfity the retraction module sensor
; Range
var SENSOR_MAX_VALUE = 4000	; [mV] Max value in the input
var TRIGGERING_VALUE = 1500	; [mV] Point where the sensor triggers
; toggle oof monitoring
if(!exists(global.oofMonitoringActive))
	global oofMonitoringActive = true

; (!) 	We don't check for the board as this is called from the Extruder 
;		configuration and the board should be there.

; Getting the trigger points -----------------------------------------
M98 P"/macros/sensors/adc/target_counts_from_range.g" B0 T{var.SENSOR_MAX_VALUE} D{var.TRIGGERING_VALUE}
M98 P"/macros/assert/abort_if_null.g" R{global.adcTargetCounts} Y{"Failed getting the range"}  	F{var.CURRENT_FILE} E12653
var TRIGGERING_POINT = global.adcTargetCounts ; ADC endstop point

; Get the IDs -----------------------------------------------------------------
; Get the input ID
if(!exists(global.OOF_INPUTS_ID))
	; We create both inputs at once
	M98 P"/macros/get_id/input.g"
	var INPUT_ID_T0 = global.inputId					
	M98 P"/macros/get_id/input.g"
	var INPUT_ID_T1 = global.inputId					
	global OOF_INPUTS_ID = { var.INPUT_ID_T0, var.INPUT_ID_T1 }

if(!exists(global.OOF_INPUTS_ID_RETMOD))
	; We create both inputs at once
	M98 P"/macros/get_id/input.g"
	var INPUT_ID_RETMOD_T0 = global.inputId					
	M98 P"/macros/get_id/input.g"
	var INPUT_ID_RETMOD_T1 = global.inputId					
	global OOF_INPUTS_ID_RETMOD = { var.INPUT_ID_RETMOD_T0, var.INPUT_ID_RETMOD_T1 }

; Get the trigger ID
if(!exists(global.OOF_INPUTS_TRIGGER))
	; We do it this way to keep the same links even if there are 
	; different extruder setups
	M98 P"/macros/get_id/trigger.g"
	var TRIGGER_ID_OFF_0 = global.triggerId
	M98 P"/macros/get_id/trigger.g"
	var TRIGGER_ID_ON_0 = global.triggerId 
	M98 P"/macros/get_id/trigger.g"
	var TRIGGER_ID_OFF_1 = global.triggerId
	M98 P"/macros/get_id/trigger.g"
	var TRIGGER_ID_ON_1 = global.triggerId 
	global OOF_INPUTS_TRIGGER = { { var.TRIGGER_ID_OFF_0, var.TRIGGER_ID_ON_0}, { var.TRIGGER_ID_OFF_1, var.TRIGGER_ID_ON_1 } }

; retraction modules are not used yet, but we prepare the trigger IDs
if(!exists(global.OOF_INPUTS_RETMOD_TRIGGER))
	; We do it this way to keep the same links even if there are 
	; different extruder setups
	M98 P"/macros/get_id/trigger.g"
	var TRIGGER_ID_RETMOD_OFF_0 = global.triggerId
	M98 P"/macros/get_id/trigger.g"
	var TRIGGER_ID_RETMOD_ON_0 = global.triggerId 
	M98 P"/macros/get_id/trigger.g"
	var TRIGGER_ID_RETMOD_OFF_1 = global.triggerId
	M98 P"/macros/get_id/trigger.g"
	var TRIGGER_ID_RETMOD_ON_1 = global.triggerId 
	global OOF_INPUTS_RETMOD_TRIGGER = { { var.TRIGGER_ID_RETMOD_OFF_0, var.TRIGGER_ID_RETMOD_ON_0}, { var.TRIGGER_ID_RETMOD_OFF_1, var.TRIGGER_ID_RETMOD_ON_1 } }

; Create the sensor -----------------------------------------------------------
M98 P"/macros/get_id/sensor.g"
M308 S{global.sensorId} P{var.SENSOR_PORT_OOF} Y{var.SENSOR_TYPE} F1 B0 C{var.SENSOR_MAX_VALUE} A{var.SENSOR_NAME_OOF}
M98 P"/macros/assert/result.g" R{result} Y"Unable to create probe sensor" F{var.CURRENT_FILE} E12654
M98 P"/macros/get_id/sensor.g"
M308 S{global.sensorId} P{var.SENSOR_PORT_RETMOD} Y{var.SENSOR_TYPE} F1 B0 C{var.SENSOR_MAX_VALUE} A{var.SENSOR_NAME_RETMOD}
M98 P"/macros/assert/result.g" R{result} Y"Unable to create OOF retraction module" F{var.CURRENT_FILE} E12655

; Create the input ------------------------------------------------------------
M950 J{global.OOF_INPUTS_ID[param.T]} C{"!"^var.SENSOR_PORT_OOF} T{var.TRIGGERING_POINT}
M98 P"/macros/assert/result.g" R{result} Y"Unable to create the analog OOF input" F{var.CURRENT_FILE} E12656
;M950 J{global.OOF_INPUTS_ID_RETMOD[param.T]} C{"!"^var.SENSOR_PORT_RETMOD} T{var.TRIGGERING_POINT}
;M98 P"/macros/assert/result.g" R{result} Y"Unable to create the analog OOF retraction module" F{var.CURRENT_FILE} E12657

; Create the trigger event ----------------------------------------------------
M581 P{global.OOF_INPUTS_ID[param.T]} T{global.OOF_INPUTS_TRIGGER[param.T][0]} S1	;Configure the emergency trigger event
M98 P"/macros/assert/result.g" R{result} Y"Unable to config the analog OOF sensor to trigger an event on OFF"  F{var.CURRENT_FILE} E12658
M581 P{global.OOF_INPUTS_ID[param.T]} T{global.OOF_INPUTS_TRIGGER[param.T][1]} 	S0	;Configure the emergency trigger event
M98 P"/macros/assert/result.g" R{result} Y"Unable to config the analog OOF sensor to trigger an event on ON"   F{var.CURRENT_FILE}	E12659
;M581 P{global.OOF_INPUTS_ID_RETMOD[param.T]} T{global.OOF_INPUTS_RETMOD_TRIGGER[param.T][0]} S1	;Configure the emergency trigger event
;M98 P"/macros/assert/result.g" R{result} Y"Unable to config the retraction module analog trigger event OFF"  F{var.CURRENT_FILE} E12660
;M581 P{global.OOF_INPUTS_ID_RETMOD[param.T]} T{global.OOF_INPUTS_RETMOD_TRIGGER[param.T][1]} S0	;Configure the emergency trigger event
;M98 P"/macros/assert/result.g" R{result} Y"Unable to config the retraction module analog trigger event ON"   F{var.CURRENT_FILE} E12661

; Create the links ------------------------------------------------------------
M98 P"/macros/files/link/create.g" L{"/sys/trigger" ^ global.OOF_INPUTS_TRIGGER[param.T][0] ^ ".g"} D{"/sys/modules/extruders/oof/v0/event_t"^param.T^".g"} I{null}
M98 P"/macros/files/link/create.g" L{"/sys/trigger" ^ global.OOF_INPUTS_TRIGGER[param.T][1] ^ ".g"} D{"/sys/modules/extruders/oof/v0/event_t"^param.T^".g"} I{null}
M118 S{"Configured OOF sensor for tool "^param.T}

; M98 P"/macros/files/link/create.g" L{"/sys/trigger" ^ global.OOF_INPUTS_RETMOD_TRIGGER[param.T][0] ^ ".g"} D{"/sys/modules/extruders/oof/v0/event_t"^param.T^".g"} I{null}
; M98 P"/macros/files/link/create.g" L{"/sys/trigger" ^ global.OOF_INPUTS_RETMOD_TRIGGER[param.T][1] ^ ".g"} D{"/sys/modules/extruders/oof/v0/event_t"^param.T^".g"} I{null}
; M118 S{"Configured OOF retraction module for tool "^param.T}
; -----------------------------------------------------------------------------
M118 S{"Configured: "^var.CURRENT_FILE}
M99 ; Proper exit
