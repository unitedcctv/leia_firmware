; Description:
;	The goal is to move down with the nozzle until the bed it touch and set
;	this value as the default position of the extruder.
; 	NOTE(!): Set the tool temperature before starting the process
;
; Input parameters:
;	- T: Tool to use
; -----------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/stage/emulator/v0/detect_bed_touch.g"
M118 S{"[TOUCH T"^param.T^"] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{!exists(global.MODULE_STAGE)} Y{"Missing required module STAGE"} F{var.CURRENT_FILE} E16230
M98 P"/macros/assert/abort_if.g" R{!exists(global.touchBedCalibrations)} Y{"Missing global variable touchBedCalibrations"} F{var.CURRENT_FILE} E16231
M98 P"/macros/assert/abort_if.g" R{#global.touchBedCalibrations<2} Y{"Global variable touchBedCalibrations needs to have length 2"} F{var.CURRENT_FILE} E16232
M98 P"/macros/assert/abort_if.g" R{(!exists(param.T)||(exists(param.T)&&param.T == null))} Y{"Parameter T is missing or it is null"} F{var.CURRENT_FILE} E16233
M98 P"/macros/assert/abort_if.g" R{(param.T>2||param.T<0)} Y{"Parameter T out of range"} F{var.CURRENT_FILE} E16234
M98 P"/macros/assert/abort_if.g" R{(!exists(tools[param.T].active[0]))} Y{"Missing tool configuration"} F{var.CURRENT_FILE} E16235

var bed_position = {2.5 + random(10) * 0.1}

T-1
G4 S2 ; wait 2 seconds

; save the calibration value as minimum value of the UW axes
if(param.T == 0)
	set global.touchBedCalibrations[0] = var.bed_position
	M208 U{var.bed_position} S1

elif(param.T == 1)
	set global.touchBedCalibrations[1] = var.bed_position
	M208 W{var.bed_position} S1

M400

M118 S{"[TOUCH T"^param.T^"] Bed at "^var.bed_position^"mm (Backlash comp 0.0mm)"}

; Persist the calibration values
M98 P"/macros/variable/save_number.g" N"global.touchBedCalibrations" V{global.touchBedCalibrations} C1 

; override the touch calibs at job start
if (exists(global.touchBedJobstartValues))
	set global.touchBedJobstartValues = global.touchBedCalibrations
else
	global touchBedJobstartValues = global.touchBedCalibrations

M400
T{param.T}

M99 ; Proper exit

