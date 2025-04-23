; Description: 	
;   This macro is used to  call the xy_calibration.g
;   Requires temperatures active and standby for both extruders
;   T{activeTemps[0], standbyTemps[0],activeTemps[1],standbyTemps[1]}
;---------------------------------------------------------------------------------------------
var CURRENT_FILE		= "/macros/hmi/xy_calibration/start.g"
; Definitions--------------------------------------------------------------------
M118 S{"[start.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}
; Check files
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/printing/get_ready.g"} F{var.CURRENT_FILE} E88004
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/xy_calibration/xy_calibration.g"} 	F{var.CURRENT_FILE} E88000


; Check params
if #tools < 2 || !exists(tools[0]) || !exists(tools[1])
    M98 P"/macros/assert/abort.g" Y{"XY Calibration requires both tools installed"}     F{var.CURRENT_FILE} E88001

var extruderTemps = vector(4, null)
if (!exists(param.T) || param.T == null || #param.T != 4)
    if tools[0].active[0] <= 0 || tools[1].active[0] <= 0
        M98 P"/macros/assert/abort.g" Y{"XY Calibration requires both tools to be hot"}     F{var.CURRENT_FILE} E88002

    set var.extruderTemps = {tools[0].active[0], tools[0].standby[0], tools[1].active[0], tools[1].standby[0]}
else
    set var.extruderTemps = param.T

M98 P"/macros/printing/get_ready.g"

; Check whether the machine is homed x y z u w-------------------------------------------------------------
if(!move.axes[0].homed || !move.axes[1].homed || !move.axes[2].homed || !move.axes[3].homed || (exists(move.axes[4]) && !move.axes[4].homed)) 
	; home all the axes "/sys/homeall.g" checks which axes need to be homed -----------------------------------------------
	M98 P"/sys/homeall.g"
M400


; touch T1 first so that we do T0 last and start the calibration with T0
if var.extruderTemps[2] > 0
    M98 P"/macros/stage/detect_bed_touch.g" T1
M400
if var.extruderTemps[0] > 0
    M98 P"/macros/stage/detect_bed_touch.g" T0
M400

M98 P"/macros/xy_calibration/xy_calibration.g" T{var.extruderTemps}
M400

M98 P"/macros/report/event.g" Y{"XY Calibration successful"} F{var.CURRENT_FILE} V88002
; Checking the Call Id param for HMI
if exists(param.I)
	M118 S{"#I"^param.I^"#DONE"}
; -----------------------------------------------------------------------------
M118 S{"[start.g] Done "^var.CURRENT_FILE}
M99