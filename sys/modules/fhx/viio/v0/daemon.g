; Description: 	
;	This will call file to create preload status after machine configuration, then delete itself off daemon Tasks
; Example:
;	M98 P"/sys/modules/fhx/viio/v0/daemon.g"
;------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/fhx/viio/v0/daemon.g"

if(exists(global.emergencyGeneralIsTriggered))
	if(global.emergencyGeneralIsTriggered == false)
		; logging starts here as it will spam the log if emergency is pressed
		M118 S{"[daemon.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

		M98 P"/macros/files/daemon/remove.g" F"/sys/modules/fhx/viio/v0/daemon.g"
		M98 P"/macros/assert/abort_if_file_missing.g" R{"/sys/modules/fhx/viio/v0/handle_preload_status.g"} F{var.CURRENT_FILE} E17648
		if (global.MODULE_FHX[0] != null)
			M98 P"/sys/modules/fhx/viio/v0/handle_preload_status.g" T0
		M400

		if (global.MODULE_FHX[1] != null)
			M98 P"/sys/modules/fhx/viio/v0/handle_preload_status.g" T1
		M400
; -----------------------------------------------------------------------------
		M118 S{"[daemon.g] Done " ^var.CURRENT_FILE}
M99 ; Proper exit
