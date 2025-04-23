;Description: 	
;	The stop.g is called when M0 (Stop) is run (e.g. when a print from SD-card
;	is finished normally).
;		   In this
;		   -  The bed heater will be switched off
;		   -  All the tool heaters will be turned off
;		   -  all the event logging will be closed
; TODO:
;	- Check if we have a power meter module, otherwise, disable the power read.
;------------------------------------------------------------------------------
; Mandatory check before starting the file to sync all the input channels
if !inputs[state.thisInput].active
	M99
;------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/stop.g"
M118 S{"[stop.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking for files first
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/sensors/read_power.g"} 			F{var.CURRENT_FILE} E34500
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/axes/part_removal_position.g"}				F{var.CURRENT_FILE} E34501
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/generic/turn_off_everything.g"} 	F{var.CURRENT_FILE} E34502
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/doors/unlock.g"} 					F{var.CURRENT_FILE} E34503
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/files/logs/open_default.g"} 		F{var.CURRENT_FILE} E34504
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/generic/reset_idle_timer.g"} 		F{var.CURRENT_FILE} E34505
; Disable the forceAbort as we are stopping ------------------------------------
if(exists(global.forceAbort) && global.forceAbort)
	set global.forceAbort = false

var AUTO_PLACEMENT_SAFETY_MARGIN	= 100	; [mm] Safety margin when shrinking printing area so that the extruder does not hit the last print
; Getting the power meter data ------------------------------------------------
if(!exists(global.powerMeterValueStart) || global.powerMeterValueStart == null)
	M98 P"/macros/report/warning.g" Y{"Missing information about the power meter"} F{var.CURRENT_FILE} W24500
else
	var START_VALUE = global.powerMeterValueStart
	M98 P"/macros/sensors/read_power.g"
	if(global.powerMeterValueStart == null)
		M98 P"/macros/report/warning.g" Y{"Unable to read the power meter"} F{var.CURRENT_FILE} W24501
	else
		M118 S{"[stop.g] Print finished with power meter at "^global.powerMeterValueStart^"kWh"}
		M98 P"/macros/report/event.g" Y{"Power meter ended at: %skWh"} A{(global.powerMeterValueStart-var.START_VALUE),} F{var.CURRENT_FILE} V24500

; Reset the idle cool down timers for bed and the tools------------------------
M98 P"/macros/axes/part_removal_position.g"
M98 P"/macros/generic/reset_idle_timer.g"
; Turn off everything ---------------------------------------------------------
M98 P"/macros/generic/turn_off_everything.g"

; Unlock the doors ------------------------------------------------------------
M98 P"/macros/doors/unlock.g"

var JOB_NAME 		= { (exists(global.jobUUID) && global.jobUUID != null && #global.jobUUID > 0) ? global.jobUUID : "UNKNOWN" }

; Setting back to the default coordinate system
G54
M400
; Moving the maximum printing area back by the safety margin
if exists(global.activatePrintAreaManagement) && global.activatePrintAreaManagement
	; setting the next x max limit
	if exists(global.jobBBOX) && #global.jobBBOX == 6
		var NEXT_X_MAX_LIMIT = global.jobBBOX[0] - var.AUTO_PLACEMENT_SAFETY_MARGIN
		; reset bbox after printing
		set global.jobBBOX = null
		; checking for the printing limit variable and setting the used up area
		if(exists(global.printingLimitsX))
			set global.printingLimitsX[1] = var.NEXT_X_MAX_LIMIT > 0 ? var.NEXT_X_MAX_LIMIT : 0

; revert the extruder relay status
if(exists(global.activateExtruderRelay))
	set global.activateExtruderRelay = false
; set back the autoplacement active to false if exists
if(exists(global.autoPlacementActive))
	set global.autoPlacementActive = false
; clear the override extruder number
if(exists(global.overrideExtruderNum))
	set global.overrideExtruderNum = null

; Close the event logging and open the default log file -----------------------
M118 S"[stop.g] Properly closing log file"
M98 P"/macros/files/logs/open_default.g"
M118 S{"[stop.g] Done printing job " ^ var.JOB_NAME }

; Setting the job id back to null ---------------------------------------------
if(exists(global.jobUUID))
	set global.jobUUID = null
M400
; print finished and cannot be recovered, we delete the resurrect file if it exists
if(fileexists("/sys/resurrect.g"))
	M30 "/sys/resurrect.g"
M400
; -----------------------------------------------------------------------------
M118 S{"[stop.g] Done "^var.CURRENT_FILE}
M99 ; Proper exit