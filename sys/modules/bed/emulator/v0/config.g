; Description: 	
;   Bed emulation. This includes an emulated sensor and heater
;---------------------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/bed/emulator/v0/config.g"
M118 S{"[CONFIG] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{exists(global.MODULE_BED)}  Y{"A previous BED configuration exists"} F{var.CURRENT_FILE}  E10620

; DEFINITIONS --------------------------------------------------------------------------------
var HEATER_OUT		  		= "0.bed0"		; Heater output
var BED_MAX_TEMP			= 120			; [ºC] Max. temperature to heat the bed
var BED_PWM_FREQ            = 5             ; [Hz] Relay control switching frequency, max is 10Hz
global BED_HAZARD_TEMP		= 99			; [°C] Hazardous temperature threshold for safety features
global BED_WARNING_TEMP		= 80			; [°C] Warning temperature threshold
global bedIdleWaitTime 		= 120 * 60 		; [sec] time to wait in idle state before cooling down the bed
global bedTempLastSetTime 	= 0				; [sec] Last time bed temperature was set
global bedCompensationActive = true			; variable to enable and disable the bed compensation
; locations of the bed screws
global BED_SCREW_POINTS 	= { {-20,0}, {470, 0}, {1000, 0} , {1000, 500} , {470, 500}, {-20, 500} }

; CONFIGURATION ------------------------------------------------------------------------------
M98 P"/macros/get_id/sensor.g"
var BED_SENSOR_ID = global.sensorId

M98 P"/macros/get_id/heater.g"
var BED_HEATER_ID = global.heaterId

M98 P"/macros/assert/abort_if.g" R{var.BED_SENSOR_ID != 0}  Y{"BED_SENSOR_ID must be zero"} F{var.CURRENT_FILE}  E10621
M98 P"/macros/assert/abort_if.g" R{var.BED_HEATER_ID != 0}  Y{"BED_HEATER_ID must be zero"} F{var.CURRENT_FILE}  E10622

; CONFIGURATION ------------------------------------------------------------------------------
M308 S{var.BED_SENSOR_ID}  Y"emu-sensor" R850 F1000 C220 A"temp_bed[°C]"	  ; emulated Bed Temperature
M98 P"/macros/assert/result.g" R{result} Y"Unable to create emulated bed temperature sensor" F{var.CURRENT_FILE}  E10623

M950 H{var.BED_HEATER_ID} C{var.HEATER_OUT} T{var.BED_SENSOR_ID} Q{var.BED_PWM_FREQ}
M98 P"/macros/assert/result.g" R{result} Y"Unable to create Bed heater" F{var.CURRENT_FILE} E10624

M143 H{var.BED_HEATER_ID} S{var.BED_MAX_TEMP}	; Max. Temperature of the Bed
M98 P"/macros/assert/result.g" R{result} Y"Unable to set max temperature" F{var.CURRENT_FILE} E10625

; From PID auto-tuning: M303 H0 S80 Y3
M307 H{var.BED_HEATER_ID} R0.054 K0.049:0.000 D27.40 E1.35 S1.00 B0
M98 P"/macros/assert/result_accept_warning.g" R{result}  Y"Unable to set heating parameters" F{var.CURRENT_FILE} E10626 ; It is normal to get warning with M307

M140 H{var.BED_HEATER_ID}							; map heated bed to heater 0
M98 P"/macros/assert/result.g" R{result} Y"Unable to map heater with the Bed" F{var.CURRENT_FILE} E10627

; Register daemon task
M98 P"/macros/files/daemon/add.g" F"/sys/modules/bed/viio/v0/daemon.g"

global MODULE_BED = 0.1	; Setting the current version of this module
M118 S{"[CONFIG] Configured "^var.CURRENT_FILE}
M99 ; Proper exit