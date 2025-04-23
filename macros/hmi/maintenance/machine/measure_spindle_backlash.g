;---------------------------------------------------------------------------------------------
; Description:
;	Repeat backlash test in all 4 corners to check for consistency
;---------------------------------------------------------------------------------------------
var CURRENT_FILE 	= "/macros/hmi/maintenance/machine/measure_spindle_backlash.g"
M118 S{"[measure_touch_grid.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; lock the door----------------------------------------------------------------
M98 P"/macros/doors/lock.g"

var AXES_HOMED = move.axes[0].homed && move.axes[1].homed && move.axes[2].homed && move.axes[3].homed && move.axes[4].homed
if (!var.AXES_HOMED)
	G28
M400

T-1

G1 Z3 F5000


var SAMPLE_MS = 500
var NUM_SAMPLES = 10
var PROBE_Z = global.PROBE_OFFSET_Z
var positions = {{global.printingLimitsX[0], global.printingLimitsY[1]}, {global.printingLimitsX[1], global.printingLimitsY[1]}, {global.printingLimitsX[1], global.printingLimitsY[0]}, {global.printingLimitsX[0], global.printingLimitsY[0]}}


var backlash = 0

while iterations < #var.positions
    var X = var.positions[iterations][0]
    var Y = var.positions[iterations][1]
    G1 X{var.X} Y{var.Y} F12000
    G1 Z{var.PROBE_Z} F3000
    G4 S2
    M400
    var valuePreBacklash = 0
    while iterations < var.NUM_SAMPLES
        set var.valuePreBacklash = var.valuePreBacklash + sensors.analog[global.PROBE_SENSOR_ID].lastReading
        G4 P{var.SAMPLE_MS}
    M400
    set var.valuePreBacklash = var.valuePreBacklash / var.NUM_SAMPLES

    G1 Z{var.PROBE_Z - 0.2} F3000
    M400
    G4 S0.2
    M400
    G1 Z{var.PROBE_Z} F3000
    M400
    G4 S2
    M400
    var valuePostBacklash = 0
    while iterations < var.NUM_SAMPLES
        set var.valuePostBacklash = var.valuePostBacklash + sensors.analog[global.PROBE_SENSOR_ID].lastReading
        G4 P{var.SAMPLE_MS}
    M400
    set var.valuePostBacklash = var.valuePostBacklash / var.NUM_SAMPLES

    set var.backlash = (var.valuePostBacklash - var.valuePreBacklash) / 1000 ; convert from um to mm

    M118 S{"[measure_spindle_backlash.g] Backlash "^var.backlash^" at X:"^var.X^" Y:"^var.Y}
    M400
    G1 Z0 F5000
M400

G1 Z5 F5000

; unlock the door----------------------------------------------------------------
M98 P"/macros/doors/unlock.g"

; Checking the Call Id param for HMI
if exists(param.I)
	M118 S{"#I"^param.I^"#DONE"}
;---------------------------------------------------------------------------------------------
M118 S{"[measure_spindle_backlash.g] Done "^var.CURRENT_FILE}
M99 ; Proper exit