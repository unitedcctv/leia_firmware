; Description:
;			This macro will be called whenever the door is opened
;---------------------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/emergency/trigger_emergency_door.g"
M118 S{"[trigger_emergency_door.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking for files first-------------------------------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{!exists(global.EMERGENCY_INPUTS)}  Y{"Missing required global EMERGENCY_INPUTS"}	F{var.CURRENT_FILE} E12130
; Definitions -------------------------------------------------------------------
var emergencyState = 0
var BED_MIN_TEMP = 0 		; [dC] Min value before turning the bed off
var BED_OFF_TEMP = -273.1 	; [dC] Value to use when the bed is off
var BED_TOO_HOT = exists(global.BED_WARNING_TEMP) && (heat.heaters[heat.bedHeaters[0]].active > global.BED_WARNING_TEMP)
var IN_PRINTJOB = ((job.filePosition != null) && (job.filePosition > 0))
var PRINT_PAUSED = state.status == "paused"
var MOVING = move.currentMove.requestedSpeed > 0
var doorOpened = false

; checking the emergency inputs
while iterations < #global.EMERGENCY_INPUTS
	; cumulative emergency state
	set var.emergencyState = var.emergencyState + sensors.gpIn[global.EMERGENCY_INPUTS[iterations]].value

; if cumulative emergency state is 0 that means that the emergency system is not triggered
if( var.emergencyState > 0.5 )
	set global.emergencyDoorIsTriggered = false
else 
	set global.emergencyDoorIsTriggered = true
	set var.doorOpened = true

set var.emergencyState = var.emergencyState / #global.EMERGENCY_INPUTS

if(var.doorOpened)
	M118 S{"[trigger_emergency_door.g] Door opened"}
	; if the door is locked and we open it regardless, we need to warn and in certain cases abort the print or reset the boards
	if( exists(global.doorIsLocked) && global.doorIsLocked )
		; set global.hmiStateDetail = "error_door_opened"
		if(var.IN_PRINTJOB && !var.PRINT_PAUSED)
			M98 P"/macros/report/warning.g" Y"Door forced open while locked and printing. Please check the door locking mechanism and restart machine" F{var.CURRENT_FILE} W12131
			M42 P{global.EMERGENCY_DISABLE_CTRL} S0 ; trip safety relay
			M112

		if(var.MOVING)
			M98 P"/macros/report/warning.g" Y"Door forced open while locked and moving. Please check the door locking mechanism and restart machine" F{var.CURRENT_FILE} W12132
			M42 P{global.EMERGENCY_DISABLE_CTRL} S0 ; trip safety relay
			M112

		M98 P"/macros/report/warning.g" Y"Door forced open while locked. Please check the door locking mechanism" F{var.CURRENT_FILE} W12133
		M98 P"/macros/doors/unlock.g"
	M400

	; deal with z axis
	if( move.axes[2].homed )
		if(!exists(global.lastZPosition))
			global lastZPosition = move.axes[2].machinePosition
		else
			set global.lastZPosition = move.axes[2].machinePosition
		M118 S{"[trigger_emergency_door.g] Saved Z Position: "^global.lastZPosition}
	elif (exists(global.lastZPosition))
		set global.lastZPosition = null

	if(var.BED_TOO_HOT)
		M140 S{var.BED_MIN_TEMP} R{var.BED_MIN_TEMP}
		M140 S{var.BED_OFF_TEMP}
		M98 P"/macros/report/warning.g" Y"Bed above safety temperature: Cooling down!" F{var.CURRENT_FILE} W12134
	M400

	M18 X Y Z U W ; Turn off the motors
	M118 S{"[trigger_emergency_door.g] Motors Disabled"}

else
	M118 S{"[trigger_emergency_door.g] Door closed"}
	if (exists(global.lastZPosition) && global.lastZPosition != null )
		M118 S{"[trigger_emergency_door.g] Recovering Z Position: "^global.lastZPosition}
		M17 Z ; Enable Z motors
		M400
		G92 Z{global.lastZPosition}
	M400
	; clear printbed
	if(!var.IN_PRINTJOB && exists(global.printingLimitsX))
		set global.printingLimitsX[1] = 1000
M400
; -----------------------------------------------------------------------------
M118 S{"[trigger_emergency_door.g] Done "^var.CURRENT_FILE}
M99 