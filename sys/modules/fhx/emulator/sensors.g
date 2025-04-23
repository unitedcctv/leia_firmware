; Description:
;	Setting up the FHX Sensors
; Input Parameters:
;	- T: Tool 0 or 1 to configure               
;---------------------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/fhx/emulator/sensors.g"
M118 S{"[CONFIG]  Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{!exists(param.T)}  Y{"Missing required input parameter T"} F{var.CURRENT_FILE} E17707
M98 P"/macros/assert/abort_if_null.g" R{param.T}  	  Y{"Input parameter T is null"} F{var.CURRENT_FILE} E17708
M98 P"/macros/assert/abort_if.g" R{(param.T>=2||param.T<0)}  Y{"Unexpected tool value"} F{var.CURRENT_FILE} E17709

;Sensor DEFINITIONS --------------------------------------------------------------
; not enough pins for all sensors

global FHX_SENSOR_ID = {{null, null, null, null}, {null, null, null, null}}
global oofFhxSensorID = {null, null}
global OOF_TRIGG_VALUE = 1500 ;[mv]

; TEMP Sensor:
M98 P"/macros/get_id/sensor.g"
M308 S{global.sensorId} Y"emu-sensor" R100 F1000 C450 A{"temp_fhx_box"^param.T^"[°C]"} 	; FHX Temperature 
M98 P"/macros/assert/result.g" R{result} Y{"Unable to create FHXC Temperature BOX"^param.T} F{var.CURRENT_FILE} E17710

; Humidity sensor 
M98 P"/macros/get_id/sensor.g"
M308 S{global.sensorId}  Y"emu-sensor" R100 F1000 C450 A{"hum_fhx_box"^param.T^"[%]"}		
M98 P"/macros/assert/result.g" R{result} Y{"Unable to create Board Humidity of box"^param.T} F{var.CURRENT_FILE} E17711

; -----------------------------------------------------------------------------
M118 S{"[Sensors] Configured "^var.CURRENT_FILE}
M99 ; Proper exit