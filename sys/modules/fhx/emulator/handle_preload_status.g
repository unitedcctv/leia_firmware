; Description: 	
;	This will check the preload status
; Example:
;	M98 P"/sys/modules/fhx/emulator/handle_preload_status.g"
;------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/fhx/emulator/handle_preload_status.g"
M118 S{"[handle_preload_status.g]  Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; global state motors running
if (!exists(global.fhxMotorsRunning))
	global fhxMotorsRunning = null
else
	set global.fhxMotorsRunning = null

; create global variable for preload status-----------------------------------
if (!exists(global.fhxPreload))
    var leftRollT0 = false
    var rightRollT0 = false
    var leftRollT1 = false
    var rightRollT1 = false
    global fhxPreload = {{var.leftRollT0, var.rightRollT0}, {var.leftRollT1, var.rightRollT1}}

; setting preload to be true for available box
if (global.MODULE_FHX[param.T] != null)
    set global.fhxPreload[param.T][0] = true
    set global.fhxPreload[param.T][1] = true
;-----------------------------------------------------------------------
M118 S{"[handle_preload_status.g] Done "^var.CURRENT_FILE}
M99 ; Proper exit