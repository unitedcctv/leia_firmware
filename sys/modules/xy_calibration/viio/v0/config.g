; Description: 
;	This module only enabled the XY-Calibration module. Most of the files are 
;	available in /macros/xy_calibration/.
;------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/xy_calibration/viio/v0/config.g"
M118 S{"[CONFIG] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/xy_calibration/set_offset_correction.g"} F{var.CURRENT_FILE} E171001
global MODULE_XY_CALIBRATION = 0.1	; Setting the current version of this module

; -----------------------------------------------------------------------------
; Load the offset correction file for the available tools
if exists(global.MODULE_EXTRUDER_0)
    M98 P"/macros/xy_calibration/set_offset_correction.g" T0 L

if exists(global.MODULE_EXTRUDER_1)
    M98 P"/macros/xy_calibration/set_offset_correction.g" T1 L

; -----------------------------------------------------------------------------
M118 S{"[CONFIG] Configured "^var.CURRENT_FILE}
M99						;Proper exit file