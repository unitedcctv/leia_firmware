; Description:
;	Setting up the FHX Sensors
; Input Parameters:
;	- T: Tool 0 or 1 to configure               
;---------------------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/fhx/viio/v0/sensors.g"
M118 S{"[CONFIG]  Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{!exists(param.T)}  Y{"Missing required input parameter T"} F{var.CURRENT_FILE} E17637
M98 P"/macros/assert/abort_if_null.g" R{param.T}  	  Y{"Input parameter T is null"} F{var.CURRENT_FILE} E17638
M98 P"/macros/assert/abort_if.g" R{(param.T>=2||param.T<0)}  Y{"Unexpected tool value"} F{var.CURRENT_FILE} E17639

;Sensor DEFINITIONS --------------------------------------------------------------
var FHX_BOARD_CAN_ID		= {40 + param.T} 			 		; As a number
var FHX_CAN_ID_NAME			= {""^var.FHX_BOARD_CAN_ID} 		; As string

var FHX_SENSOR_PORT_0		= {"!"^var.FHX_CAN_ID_NAME^".io0.in"}	; Port where the sensor 0 is connected.
var FHX_SENSOR_PORT_1		= {"!"^var.FHX_CAN_ID_NAME^".io1.in"}	; Port where the sensor 1 is connected.
var FHX_SENSOR_PORT_2		= {"!"^var.FHX_CAN_ID_NAME^".io2.in"}	; Port where the sensor 2 is connected.
var FHX_SENSOR_PORT_3		= {"!"^var.FHX_CAN_ID_NAME^".io3.in"}	; Port where the sensor 3 is connected.

var FHX_TEMP_INPUT  		= {var.FHX_CAN_ID_NAME^".temp0"}	; Temperature sensor input board, port and pin

; Checking for board---------------------------------------------------------------------------------------------------------------------------
M98 P"/macros/assert/board_present.g" D{var.FHX_BOARD_CAN_ID} Y{"Board %s is required for FHX"} A{var.FHX_CAN_ID_NAME,} F{var.CURRENT_FILE} E17640

; Get the IDs -----------------------------------------------------------------
; Get the input ID
if(!exists(global.FHX_SENSOR_ID))
	M98 P"/macros/get_id/input.g"
	var FHX_S0_T0 = global.inputId		; ID FHX sensor 0 T0
	M98 P"/macros/get_id/input.g"
	var FHX_S1_T0 = global.inputId		; ID FHX sensor 1 T0
	M98 P"/macros/get_id/input.g"
	var FHX_S2_T0 = global.inputId		; ID FHX sensor 2 T0
	M98 P"/macros/get_id/input.g"
	var FHX_S3_T0 = global.inputId		; ID FHX sensor 3 T0
	M98 P"/macros/get_id/input.g"
	var FHX_S0_T1 = global.inputId		; ID FHX sensor 0 T1
	M98 P"/macros/get_id/input.g"
	var FHX_S1_T1 = global.inputId		; ID FHX sensor 1 T1
	M98 P"/macros/get_id/input.g"
	var FHX_S2_T1 = global.inputId		; ID FHX sensor 2 T1
	M98 P"/macros/get_id/input.g"
	var FHX_S3_T1 = global.inputId		; ID FHX sensor 3 T1
	global FHX_SENSOR_ID = {{var.FHX_S0_T0, var.FHX_S1_T0, var.FHX_S2_T0, var.FHX_S3_T0},{var.FHX_S0_T1, var.FHX_S1_T1, var.FHX_S2_T1, var.FHX_S3_T1}}


; Get the trigger ID
if (!exists(global.FHX_INPUTS_TRIGGER))
	M98 P"/macros/get_id/trigger.g"
	var TRIGGER_ID_OFF_00 = global.triggerId
	M98 P"/macros/get_id/trigger.g"
	var TRIGGER_ID_ON_00 = global.triggerId  
	M98 P"/macros/get_id/trigger.g"
	var TRIGGER_ID_OFF_02 = global.triggerId
	M98 P"/macros/get_id/trigger.g"
	var TRIGGER_ID_ON_02 = global.triggerId 
	M98 P"/macros/get_id/trigger.g"
	var TRIGGER_ID_OFF_10 = global.triggerId
	M98 P"/macros/get_id/trigger.g"
	var TRIGGER_ID_ON_10 = global.triggerId 
	M98 P"/macros/get_id/trigger.g"
	var TRIGGER_ID_OFF_12 = global.triggerId
	M98 P"/macros/get_id/trigger.g"
	var TRIGGER_ID_ON_12 = global.triggerId 
	global FHX_INPUTS_TRIGGER = { { var.TRIGGER_ID_ON_00, var.TRIGGER_ID_ON_02, var.TRIGGER_ID_OFF_00, var.TRIGGER_ID_OFF_02 }, { var.TRIGGER_ID_ON_10, var.TRIGGER_ID_ON_12, var.TRIGGER_ID_OFF_10, var.TRIGGER_ID_OFF_12}}

;--------------------------------------------------------------------------------------------------------------------------------------------
; Configuration & Initialization
;--------------------------------------------------------------------------------------------------------------------------------------------
; Configuring FHX Sensors as gpIn:
M950 J{global.FHX_SENSOR_ID[param.T][0]} C{var.FHX_SENSOR_PORT_0} 
M950 J{global.FHX_SENSOR_ID[param.T][1]} C{var.FHX_SENSOR_PORT_1}
M950 J{global.FHX_SENSOR_ID[param.T][2]} C{var.FHX_SENSOR_PORT_2}
M950 J{global.FHX_SENSOR_ID[param.T][3]} C{var.FHX_SENSOR_PORT_3}	

; Configuring Triggers
M581 P{global.FHX_SENSOR_ID[param.T][0]} T{global.FHX_INPUTS_TRIGGER[param.T][0]} S1	;Configure trigger event 
M98 P"/macros/assert/result.g" R{result} Y"Unable to config the analog OOF sensor to trigger an event on ON"  F{var.CURRENT_FILE} E17641
M581 P{global.FHX_SENSOR_ID[param.T][2]} T{global.FHX_INPUTS_TRIGGER[param.T][1]} S1	;Configure trigger event
M98 P"/macros/assert/result.g" R{result} Y"Unable to config the analog OOF sensor to trigger an event on ON"  F{var.CURRENT_FILE} E17642
M581 P{global.FHX_SENSOR_ID[param.T][0]} T{global.FHX_INPUTS_TRIGGER[param.T][2]} S0	;Configure trigger event 
M98 P"/macros/assert/result.g" R{result} Y"Unable to config the analog OOF sensor to trigger an event on OFF"  F{var.CURRENT_FILE} E17643
M581 P{global.FHX_SENSOR_ID[param.T][2]} T{global.FHX_INPUTS_TRIGGER[param.T][3]} S0	;Configure trigger event
M98 P"/macros/assert/result.g" R{result} Y"Unable to config the analog OOF sensor to trigger an event on OFF"  F{var.CURRENT_FILE} E17644

; TEMP Sensor:------------------------------------------------------------------------
M98 P"/macros/get_id/sensor.g"
M308 S{global.sensorId} Y"shttemp" P{var.FHX_CAN_ID_NAME^".dummy"} A{"temp_fhx_box"^param.T^"[°C]"} 	; FHX Temperature 
M98 P"/macros/assert/result.g" R{result} Y{"Unable to create the onboard temperature sensor of infinity box T%s"} A{param.T,} F{var.CURRENT_FILE} E17645

; Humidity sensor--------------------------------------------------------------------- 
M98 P"/macros/get_id/sensor.g"
M308 S{global.sensorId}  Y"shthumidity" P{var.FHX_CAN_ID_NAME^".dummy"}	A{"hum_fhx_box"^param.T^"[%]"}		
M98 P"/macros/assert/result.g" R{result} Y{"Unable to create the onboard humidity sensor of infinity box T%s"} A{param.T,} F{var.CURRENT_FILE} E17646

; creating global OOF for macros--------------------------------------------------------
if (!exists(global.oofFhxSensorID))
	global oofFhxSensorID = {null, null}

;creating trigger value
if (!exists(global.OOF_TRIGG_VALUE))
	global OOF_TRIGG_VALUE		= 1500 ; [mV]

; Update FHX sensor ID for this tool----------------------------------------------------
M98 P"/macros/sensors/find_by_name.g" N{"oof_t"^param.T^"[mV]"}
set global.oofFhxSensorID[param.T] = global.sensorIndex 

; setting up sensor status
if (!exists(global.fhxPreload))
	global fhxPreload = {{true, true}, {true, true}} ; global.fhxPreload[#Tool][#Roll]

; create links--------------------------------------------------------------------------
M98 P"/macros/files/link/create.g" L{"/sys/trigger" ^ global.FHX_INPUTS_TRIGGER[param.T][0] ^ ".g"} D{"/macros/fhx/control/trigger/mixratio/roll0_t"^param.T^".g"} I{null}
M98 P"/macros/files/link/create.g" L{"/sys/trigger" ^ global.FHX_INPUTS_TRIGGER[param.T][1] ^ ".g"} D{"/macros/fhx/control/trigger/mixratio/roll1_t"^param.T^".g"} I{null}
M98 P"/macros/files/link/create.g" L{"/sys/trigger" ^ global.FHX_INPUTS_TRIGGER[param.T][2] ^ ".g"} D{"/macros/fhx/control/trigger/preload/roll0_t"^param.T^".g"} I{null}
M98 P"/macros/files/link/create.g" L{"/sys/trigger" ^ global.FHX_INPUTS_TRIGGER[param.T][3] ^ ".g"} D{"/macros/fhx/control/trigger/preload/roll1_t"^param.T^".g"} I{null}
M98 P"/macros/files/link/create.g" L{"/sys/trigger" ^ global.OOF_INPUTS_TRIGGER[param.T][0] ^ ".g"} D{"/macros/fhx/control/oof_event/pause_t"^param.T^".g"} I{null}
M98 P"/macros/files/link/create.g" L{"/sys/trigger" ^ global.OOF_INPUTS_TRIGGER[param.T][1] ^ ".g"} D{"/macros/fhx/control/oof_event/pause_t"^param.T^".g"} I{null}

; -----------------------------------------------------------------------------
M118 S{"[Sensors] Configured "^var.CURRENT_FILE}
M99 ; Proper exit