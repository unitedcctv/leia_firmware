; Description: 	
;	   Chamber heater:
; 				The Heater installed in the CBC can be controlled as Chamber device or as a fan with 
;				the inverted output. If the useChamber variable is defined it will use the chamber an 
;				set it up as a "heater", if it is not it will be a fan.
;				It can't be set as a heater because Duet is failing all the time as the temperature is 
;				not stable.
;		CBC Output Fans:
;				These fans will blow air from the chamber to the ambient. There are two of them and
;				they are placed on the top of the machine.
;-------------------------------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/cbc/viio/v1/config.g"
M118 S{"[CONFIG] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{exists(global.MODULE_CBC)} Y{"A previous CBC configuration exists"} F{var.CURRENT_FILE} E11199

; DEFINITIONS --------------------------------------------------------------------------------
var HEATER_OUT			= "0.fan1"		; Heater output
global CBC_MAX_TEMP	 	= 50			; [ºC] Maximum allowed set temperature
global CBC_HAZARDOUS_TEMP   = 60        ; [°C] Emergency shutoff cbc temp
global cbcHeaterLastUpdate = state.upTime	; Counter acts as divider to call temp ctrl. every n-th cycle only
global cbcZ0LastTemp 	= 0				; Variable to log previous cbc temperature
global cbcPIDPrevError	= 0				; Previous CBC PID error value
global cbcPIDPrevErrorInt	= 0			; Previous CBC PID integral of error value
var FAN_OUT_A		 	= "30.out1"	   	; Output Fan A will blow air from the chamber to the ambient
var FAN_OUT_B		 	= "31.out1"	   	; Output Fan B will blow air from the chamber to the ambient
var FAN_CIRCULATION_A 	= "30.out0"	   	; Circulation Fan A that will be always ON
var FAN_CIRCULATION_B 	= "31.out0"	   	; Circulation Fan B that will be always ON
var CBC_TEMP_INPUT_A  	= "30.temp1"	; Temperature sensor A input board, port and pin

M98 P"/macros/get_id/fan.g"
global CBC_HEATER = global.fanId		; ID of the Heater of the Chamber that is configured and controlled as a FAN!

M98 P"/macros/get_id/sensor.g"
global CBC_TEMP_SENSOR_A = global.sensorId	; ID of the temperature Sensor of the CBC on the Z0 motor board

M98 P"/macros/get_id/sensor.g"
global CBC_TEMP_SENSOR_SB_P = global.sensorId	; ID of the stageboard onboard temperature sensor

; CBC Output Fans:
; These fans will blow air from the chamber to the ambient. There are two of them and
; they are placed on the top of the machine.
M98 P"/macros/get_id/fan.g"
global FAN_EXHAUST_A = global.fanId		; ID of the fan out on one side of the CBC
M98 P"/macros/get_id/fan.g"
global FAN_EXHAUST_B = global.fanId		; ID of the fan out  on the other side of the CBC

if (!exists(global.cbcLastSetTime))
	; hardcoded for maximum 2 extruders
	global cbcLastSetTime = 0
else
	set global.cbcLastSetTime = 0

if (!exists(global.cbcIdleWaitTime))
	global cbcIdleWaitTime = 120 * 60 ;[sec] 2 hours

;--------------------------------------------------------------------------------------------------------------------------------------------
; Configuration & Initialization
;--------------------------------------------------------------------------------------------------------------------------------------------

; Checking for board
M98 P"/macros/assert/board_present.g" D10 Y"X axis motor board is required for CBC" F{var.CURRENT_FILE} E11200
M98 P"/macros/assert/board_present.g" D20 Y"Y axis motor board is required for CBC" F{var.CURRENT_FILE} E11201
M98 P"/macros/assert/board_present.g" D30 Y"Z axis left motor board is required for CBC" F{var.CURRENT_FILE} E11202
M98 P"/macros/assert/board_present.g" D31 Y"Z axis right motor board is required for CBC" F{var.CURRENT_FILE} E11203

; Sensor:
; External temperature sensor
M308 S{global.CBC_TEMP_SENSOR_A} Y"pt1000" P{var.CBC_TEMP_INPUT_A} A"temp_cbc_z0[°C]" 	; CBC Temperature on the Z0 motor board
M98 P"/macros/assert/result.g" R{result} Y"Unable to create CBC Temperature on the Z axis left motor board" F{var.CURRENT_FILE} E11205

; Onboard temperature sensor
M98 P"/macros/get_id/sensor.g"							; Temperature sensor on the Z0 motor board
M308 S{global.sensorId}  Y"shttemp" 	 P"30.dummy"	A"temp_cbc_z0_p[°C]"
M98 P"/macros/assert/result.g" R{result} Y"Unable to create onboard temperature sensor  of the Z axis left motor board" F{var.CURRENT_FILE} E11210

M98 P"/macros/get_id/sensor.g"							; Temperature sensor on the Z1 motor board
M308 S{global.sensorId}  Y"shttemp" 	 P"31.dummy"	A"temp_cbc_z1_p[°C]"
M98 P"/macros/assert/result.g" R{result} Y"Unable to create onboard temperature sensor  of the Z axis right motor board" F{var.CURRENT_FILE} E11211

M98 P"/macros/get_id/sensor.g"
M308 S{global.sensorId}  Y"shttemp" 	 P"20.dummy"	A"temp_cbc_y_p[°C]"		; Temperature sensor on the Y motor board
M98 P"/macros/assert/result.g" R{result} Y"Unable to create onboard temperature sensor  of the Y motor board" F{var.CURRENT_FILE} E11212

M98 P"/macros/get_id/sensor.g"
M308 S{global.sensorId}  Y"shttemp"   	 P"10.dummy"	A"temp_cbc_x_p[°C]"		; Temperature sensor on the X motor board
M98 P"/macros/assert/result.g" R{result} Y"Unable to create onboard temperature sensor  of the X motor board" F{var.CURRENT_FILE} E11213

; Onboard humidity sensor
M98 P"/macros/get_id/sensor.g"
M308 S{global.sensorId}  Y"shthumidity" P"30.dummy"	A"hum_pcb_z0[%]"		; Humidity sensor on the Z0 motor board
M98 P"/macros/assert/result.g" R{result} Y"Unable to create Board Humidity of the Z axis left motor board" F{var.CURRENT_FILE} E11220

M98 P"/macros/get_id/sensor.g"
M308 S{global.sensorId}  Y"shthumidity" P"31.dummy"	A"hum_pcb_z1[%]"		; Humidity sensor on the Z1 motor board
M98 P"/macros/assert/result.g" R{result} Y"Unable to create Board Humidity of the Z axis right motor board" F{var.CURRENT_FILE} E11221

M98 P"/macros/get_id/sensor.g"
M308 S{global.sensorId}  Y"shthumidity" P"20.dummy"	A"hum_pcb_y[%]"			; Humidity sensor on the Y motor board
M98 P"/macros/assert/result.g" R{result} Y"Unable to create Board Humidity of the Y motor board" F{var.CURRENT_FILE} E11222

M98 P"/macros/get_id/sensor.g"
M308 S{global.sensorId}  Y"shthumidity" P"10.dummy"	A"hum_pcb_x[%]"			; Humidity sensor on the X motor board
M98 P"/macros/assert/result.g" R{result} Y"Unable to create Board Humidity of the X motor board" F{var.CURRENT_FILE} E11223

; Heater as FAN (exception for this case)
M950 F{global.CBC_HEATER} 	 C{var.HEATER_OUT} Q1
M98 P"/macros/assert/result.g" R{result} Y"Unable to create the HEATER as a Fan" F{var.CURRENT_FILE} E11225
M106 P{global.CBC_HEATER} 	 S0.0 ; Making sure it is OFF
M98 P"/macros/assert/result.g" R{result} Y"Unable to turn off the HEATER" F{var.CURRENT_FILE} E11226

; Fans: Output and circulation
M950 F{global.FAN_EXHAUST_A} C{var.FAN_OUT_A} Q1
M98 P"/macros/assert/result.g" R{result} Y"Unable to create the out FAN at Z axis left motor board" F{var.CURRENT_FILE} E11227
M106 P{global.FAN_EXHAUST_A} S0.0 C"fan_exhaust_a" ; Making sure it is OFF
M98 P"/macros/assert/result.g" R{result} Y"Unable to turn off the FAN at Z axis left motor board" F{var.CURRENT_FILE} E11228

M950 F{global.FAN_EXHAUST_B} C{var.FAN_OUT_B} Q1
M98 P"/macros/assert/result.g" R{result} Y"Unable to create the out FAN at Z axis right motor board" F{var.CURRENT_FILE} E11229
M106 P{global.FAN_EXHAUST_B} S0.0 C"fan_exhaust_b" ; Making sure it is OFF
M98 P"/macros/assert/result.g" R{result} Y"Unable to turn off the FAN at Z axis right motor board" F{var.CURRENT_FILE} E11230

M98 P"/macros/get_id/output.g"
M950 P{global.outputId} C{var.FAN_CIRCULATION_A} Q400					; Circulation FAN on the Z0 board
M98 P"/macros/assert/result.g" R{result} Y"Unable to create circulation fan at Z axis left motor board" F{var.CURRENT_FILE} E11231
M42 P{global.outputId} S1												; This output is always ON!
M98 P"/macros/assert/result.g" R{result} Y"Unable to turn on the FAN at Z axis right motor board" F{var.CURRENT_FILE} E11232

M98 P"/macros/get_id/output.g"
M950 P{global.outputId} C{var.FAN_CIRCULATION_B} Q400					; Circulation FAN on the Z1 board
M98 P"/macros/assert/result.g" R{result} Y"Unable to create circulation fan at Z axis right motor board" F{var.CURRENT_FILE} E11233
M42 P{global.outputId} S1												; This output is always ON!
M98 P"/macros/assert/result.g" R{result} Y"Unable to turn on the FAN at Z axis right motor board" F{var.CURRENT_FILE} E11234

; Creating links:
; 	(!) Using viio/v0 as there are no changes
M98 P"/macros/files/link/create.g" L"/macros/cbc/set_temperature.g" D"/sys/modules/cbc/viio/v1/set_temperature.g"
; Adding to daemon:
;	(!) Using viio/v0 as there are no changes
global cbcForceFansOn = false ; This is needed to test the fans
M98 P"/macros/files/daemon/add.g" F"/sys/modules/cbc/viio/v1/daemon.g"

; Sanity check of the sensors
var HUM_SENS_LOW_RANGE = 0.0
var HUM_SENS_UPPER_RANGE = 100.0
var PCB_TEMP_LOW_RANGE = -40.0
var PCB_TEMP_UPPER_RANGE = 125.0	
M98 P"/macros/sensors/sanity_check.g" N"hum_pcb_z0[%]" A{var.HUM_SENS_LOW_RANGE} B{var.HUM_SENS_UPPER_RANGE}
M598
M98 P"/macros/sensors/sanity_check.g" N"hum_pcb_z1[%]" A{var.HUM_SENS_LOW_RANGE} B{var.HUM_SENS_UPPER_RANGE}
M598
M98 P"/macros/sensors/sanity_check.g" N"hum_pcb_x[%]" A{var.HUM_SENS_LOW_RANGE}  B{var.HUM_SENS_UPPER_RANGE}
M598
M98 P"/macros/sensors/sanity_check.g" N"hum_pcb_y[%]" A{var.HUM_SENS_LOW_RANGE}  B{var.HUM_SENS_UPPER_RANGE}
M598
M98 P"/macros/sensors/sanity_check.g" N"temp_cbc_z0_p[°C]" A{var.PCB_TEMP_LOW_RANGE} B{var.PCB_TEMP_UPPER_RANGE}
M598
M98 P"/macros/sensors/sanity_check.g" N"temp_cbc_z1_p[°C]" A{var.PCB_TEMP_LOW_RANGE} B{var.PCB_TEMP_UPPER_RANGE}
M598
M98 P"/macros/sensors/sanity_check.g" N"temp_cbc_x_p[°C]" A{var.PCB_TEMP_LOW_RANGE} B{var.PCB_TEMP_UPPER_RANGE}
M598
M98 P"/macros/sensors/sanity_check.g" N"temp_cbc_y_p[°C]" A{var.PCB_TEMP_LOW_RANGE} B{var.PCB_TEMP_UPPER_RANGE}

; CBC circulation fans:
; (!) These Fans are configured as normal outputs and they will stay always on.

; DONE !
global MODULE_CBC = 0.1									; Setting the current version of this module

; Init - CBC Heater and Output Fans
M98 P"/macros/cbc/set_temperature.g"						; Turn off the CBC

M118 S{"[CONFIG] Configured "^var.CURRENT_FILE}

M99 ; Proper exit