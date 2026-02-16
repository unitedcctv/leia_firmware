; Description: 	
;		The cancel.g will be called every time a job is finished or cancelled 
;		in between.
;		   In this
;		   -  The bed heater will be switched off
;		   -  All the tool heaters will be turned off
;		   -  all the event logging will be closed
; TODO:
;	- Remove the pop-up.
;	- Check if we have a power meter module, otherwise, disable the power read.
;------------------------------------------------------------------------------
; Mandatory check before starting the file to sync all the input channels
if !inputs[state.thisInput].active
	M99
;------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/cancel.g"
M118 S{"[cancel.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking for files first
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/sensors/read_power.g"}				F{var.CURRENT_FILE} E33000
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/axes/part_removal_position.g"} 			F{var.CURRENT_FILE} E33001
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/files/logs/open_default.g"} 		F{var.CURRENT_FILE} E33002
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/doors/unlock.g"} 					F{var.CURRENT_FILE} E33003
;M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/generic/turn_off_everything.g"} 	F{var.CURRENT_FILE} E33004
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/generic/reset_idle_timer.g"} 		F{var.CURRENT_FILE} E33005
; Definitions -----------------------------------------------------------------
var TURN_OFF_TEMP							= -273.1 	; [°C]
var TIMEOUT_TURN_OFF						= 120		; [sec] Waiting for the user response before turn everything off
var AUTO_PLACEMENT_SAFETY_MARGIN			= 100		; [mm] Safety margin when shrinking printing area so that the extruder does not hit the last print
; Disable the forceAbort as we are canceling ----------------------------------
if(exists(global.forceAbort) && global.forceAbort)
	set global.forceAbort = false

; Getting the power meter data ------------------------------------------------
if(!exists(global.powerMeterValueStart) || global.powerMeterValueStart == null)
	M98 P"/macros/report/warning.g" Y{"Missing information about the power meter"} F{var.CURRENT_FILE} W23000
else
	var START_VALUE = global.powerMeterValueStart
	M98 P"/macros/sensors/read_power.g"
	if(global.powerMeterValueStart == null)
		M98 P"/macros/report/warning.g" Y{"Unable to read the power meter"} F{var.CURRENT_FILE} W23001
	else
		M118 S{"[cancel.g] Print cancelled with power meter at "^global.powerMeterValueStart^"kWh"}
		M98 P"/macros/report/event.g" Y{"Power meter ended at: %s kWh"} A{(global.powerMeterValueStart-var.START_VALUE),} F{var.CURRENT_FILE} V23000
		M118 S{"[cancel.g] Total consumption was "^(global.powerMeterValueStart-var.START_VALUE)^"kWh"}
M400
; Check for the doors before starting the print -------------------------------
M98 P"/macros/doors/unlock.g"

; Reset the idle cool down timers for bed and the tools------------------------
M98 P"/macros/generic/reset_idle_timer.g"

; checking if the tool fans are ON and then turn it off
if(exists(global.toolFanId))
	if((global.toolFanId[0]!= null) && (fans[global.toolFanId[0]].actualValue > 0))
		M106 P{global.toolFanId[0]} S0
		M118 S{"[cancel.g] Turned off the Tool 0 fan"}
	if((global.toolFanId[1]!= null) && (fans[global.toolFanId[1]].actualValue > 0))
		M106 P{global.toolFanId[1]} S0
		M118 S{"[cancel.g] Turned off the Tool 1 fan"}

var JOB_NAME 		= { (exists(global.jobUUID) && global.jobUUID != null && #global.jobUUID > 0) ? global.jobUUID : "UNKNOWN" }

; Changing the coordinate system 
G54
M400
var nextPrintingLimitX = exists(global.activatePrintAreaManagement) && global.activatePrintAreaManagement && exists(global.homingDone) && global.homingDone
; Moving the maximum printing area back by the safety margin
if var.nextPrintingLimitX
	; setting the next x max limit
	if exists(global.jobBBOX) && global.jobBBOX != null && #global.jobBBOX == 6
		var NEXT_X_MAX_LIMIT = global.jobBBOX[0] - var.AUTO_PLACEMENT_SAFETY_MARGIN
		; reset bbox after printing
		set global.jobBBOX = null
		; checking for the printing limit variable and setting the used up area
		if(exists(global.printingLimitsX))
			set global.printingLimitsX[1] = var.NEXT_X_MAX_LIMIT > 0 ? var.NEXT_X_MAX_LIMIT : 0

; Reverting the status of the auto placement flag
if(exists(global.autoPlacementActive))
	set global.autoPlacementActive = false
; clear the override extruder number
if(exists(global.overrideExtruderNum))
	set global.overrideExtruderNum = null
; Run the diagnostic test for all the existing boards
M98 P"/macros/printing/log_diagnostics.g"
; Close the event logging and open the default log file -----------------------
M118 S"[cancel.g] Properly closing log file"
M98 P"/macros/files/logs/open_default.g"
M118 S{"[cancel.g] Cancelled printing file " ^ var.JOB_NAME }
if(exists(global.jobUUID))
	set global.jobUUID = null
M400
; print finished and cannot be recovered, we delete the resurrect file if it exists
if(fileexists("/sys/resurrect.g"))
	M30 "/sys/resurrect.g"
M400
; -----------------------------------------------------------------------------
M118 S{"[cancel.g] Done "^var.CURRENT_FILE}
M99
