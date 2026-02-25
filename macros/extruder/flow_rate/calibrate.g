; Description:
;   Calibrate the flowrate for the specified extruder. The calibration will extrude a length of filament and measure the actual extrusion.
; Input Parameters:
;   - L (optional): [mm] Length of filament to extrude for calibration (default decided by extruder team = 500mm)
;	- F (optional): [mm/min] Extrusion speed (default decided by extruder team 100mm/min)
;   - T : tool index (only T0 supported - single extruder)
; Example:
;	M98 P"/macros/extruder/flow_rate/calibrate.g" L500 F150 T0
;	M98 P"/macros/extruder/flow_rate/calibrate.g" T0
; With standad values (no param.L and param.F) the calibration takes 6min and 11s
;------------------------------------------------------------------------------
; Mandatory check before starting the file to sync all the input channels
if !inputs[state.thisInput].active
	M99

var CURRENT_FILE = "/macros/extruder/flow_rate/calibrate.g"
M118 S{"[calibrate.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Check files
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/generic/reset_idle_timer.g"} 	F{var.CURRENT_FILE} E57651
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/extruder/flow_rate/save.g"} 	F{var.CURRENT_FILE} E57652

; Checking global variables and input parameters ------------------------------
M98 P"/macros/assert/abort_if.g"	R{!exists(param.T)}			Y{"Missing Tool index param T"}	F{var.CURRENT_FILE} E57653
M98 P"/macros/assert/abort_if.g"	R{param.T != 0}				Y{"Only T0 supported - single extruder setup"} F{var.CURRENT_FILE} E57654

if (exists(param.L))
	M98 P"/macros/assert/abort_if_null.g"	R{param.L}			Y{"Extrusion length param L is null"} F{var.CURRENT_FILE} E57655
	M98 P"/macros/assert/abort_if.g"		R{param.L <= 0}		Y{"Extrusion length is 0 or negative"} F{var.CURRENT_FILE} E57656
M400

if (exists(param.F))
	M98 P"/macros/assert/abort_if_null.g"	R{param.F}			Y{"Feedrate param F is null"} F{var.CURRENT_FILE} E57657
	M98 P"/macros/assert/abort_if.g"		R{param.F <= 0}		Y{"Feedrate param F is 0 or negative"} F{var.CURRENT_FILE} E57658
M400

; select tool
T{param.T}
M400

; Check if we are in the emulator. If yes, we will generate random values
if (network.hostname == "emulator")
	M118 S{"[calibrate.g] Flowrate calibration is not supported in emulator, generating values"}
	var randomMultiplier = (1000 + random(20)) / 1000
	G4 S10
	M98 P"/macros/extruder/flow_rate/save.g" T{param.T} K{var.randomMultiplier*100}
	M99

; Check if we have a filamentMonitor
var MONITOR_ID = tools[param.T].extruders[0]
M98 P"/macros/assert/abort_if.g" R{!exists(sensors.filamentMonitors[var.MONITOR_ID])} Y{"Tool %s does not have a flow sensor, please calibrate manually."} A{param.T,} F{var.CURRENT_FILE} E57642

; Definitions------------------------------------------------------------------
var MAX_EX 				= 2000			; [mm] maximum extrusion length
var MAX_F  				= 200			; [mm/min] maximum feed rate
var FEEDRATE			= (exists(param.F) && (param.F != null)) ? param.F : 100 ; [mm/min]
var LENGTH_CALIBRATE	= (exists(param.L) && (param.L != null)) ? param.L : 500 ; [mm]
var LENGTH_FLUSH		= 25			; [mm] Length that will be flushed bofore measuring the extrusion
var LENGTH_VERIFY		= 100			; [mm] Length that will be extruded to check
var EXTR_TOLERANCE	 	= {90,120}		; [%] Extrusion tolerance
var VERI_TOLERANCE 		= 2				; [%] Tolerance for the verification
var flowRateMultipliers = {null, null}

; reset idle time
M98 P"/macros/generic/reset_idle_timer.g"
;reset Flow to 100%
M221 S100
M221

; Check tool temperature
var TOOL_TEMP = tools[param.T].active[0]
var MIN_EX_TEMP = heat.coldExtrudeTemperature
M98 P"/macros/assert/abort_if.g" R{var.TOOL_TEMP < var.MIN_EX_TEMP} Y{"Extruder too cold, please heat up above %s"} A{var.MIN_EX_TEMP,} F{var.CURRENT_FILE} E57634

;saving encoder sensor index to a variable
M98 P"/macros/sensors/find_by_name.g" N{"fila_accu_t"^param.T^"[mm]"}
var SENSOR_INDEX = global.sensorIndex

;Measure Flowrate------------------------------------------------------
M83 ; set relative extrusion mode

; Flush hotend
M98 P"/macros/report/event.g" Y{"Flushing hotend"} F{var.CURRENT_FILE} V57635
G1 E{var.LENGTH_FLUSH} F{var.FEEDRATE}
M400
G4 S 3 ;wait 3s

; Measure extrusion
var totalExtrusion = sensors.analog[var.SENSOR_INDEX].lastReading
if (var.totalExtrusion == 0 || var.totalExtrusion == null)
	M98 P"/macros/assert/abort.g" Y{"Flowrate sensor is misconfigured or 0"} F{var.CURRENT_FILE} E57639

var measuredExtrusionMm = sensors.analog[var.SENSOR_INDEX].lastReading
M98 P"/macros/report/event.g" Y{"Extruding %smm with %smm/min"} A{var.LENGTH_CALIBRATE,var.FEEDRATE} F{var.CURRENT_FILE} V57636
G1 E{var.LENGTH_CALIBRATE} F{var.FEEDRATE}
M400
G4 S 2 ;wait
set var.measuredExtrusionMm = sensors.analog[var.SENSOR_INDEX].lastReading - var.measuredExtrusionMm

; Calculate flowrate multiplier
var flowrateMultiplier = var.LENGTH_CALIBRATE / var.measuredExtrusionMm
var flowrateMultiplierPerc = var.flowrateMultiplier*100
M118 S{"[calibrate.g] Measured "^var.measuredExtrusionMm^"mm. Flowrate multiplier is "^var.flowrateMultiplierPerc^"%"}
var inTolerance = (var.flowrateMultiplierPerc >= var.EXTR_TOLERANCE[0]) && (var.flowrateMultiplierPerc <= var.EXTR_TOLERANCE[1])
if !var.inTolerance
	M98 P"/macros/assert/abort.g" Y{"Flowrate multiplier %s% outside tolerance, please check extruder and repeat calibration"} A{var.flowrateMultiplierPerc,} F{var.CURRENT_FILE} E57638

;Verification------------------------------------------------------------------------
; initialize measured value
set var.measuredExtrusionMm = sensors.analog[var.SENSOR_INDEX].lastReading
M98 P"/macros/report/event.g" Y{"Starting verification %smm with %smm/min"} A{var.LENGTH_VERIFY,var.FEEDRATE} F{var.CURRENT_FILE} V57637
G1 E{var.LENGTH_VERIFY * var.flowrateMultiplier} F{var.FEEDRATE}
M400
G4 S 2 ;wait

;Measure extrusion
set var.measuredExtrusionMm = sensors.analog[var.SENSOR_INDEX].lastReading - var.measuredExtrusionMm
var verificationRatio = var.measuredExtrusionMm / var.LENGTH_VERIFY
var verificationRatioPerc = var.verificationRatio * 100
M118 S{"[calibrate.g] Measured "^var.measuredExtrusionMm^"mm. Verification ratio is "^var.verificationRatioPerc^"%"}

var tooSmall = var.verificationRatioPerc < var.verificationRatioPerc - var.VERI_TOLERANCE
var tooBig = var.verificationRatioPerc > var.verificationRatioPerc + var.VERI_TOLERANCE

M98 P"/macros/assert/abort_if.g" R{var.tooSmall || var.tooBig} Y{"Flowrate verification %s% outside tolerance, please repeat calibration."} A{var.verificationRatioPerc,} F{var.CURRENT_FILE} E57640

M98 P"/macros/report/event.g" Y{"Flowrate calibration successful. Flowrate multiplier for T%s is %s%"} A{param.T,var.flowrateMultiplierPerc} F{var.CURRENT_FILE} V57641

;Save new flowrate ------------------------------------------------------
M98 P"/macros/extruder/flow_rate/save.g" T{param.T} K{var.flowrateMultiplierPerc}
M98 P"/macros/extruder/flow_rate/load.g"

;------------------------------------------------------------------------
M118 S{"[calibrate.g] Done "^var.CURRENT_FILE}
M99 ; Proper exit 