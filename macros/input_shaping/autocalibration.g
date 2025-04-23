;---------------------------------------------------------------------------------------------
;	This macro is used to run the system identification and update the input shaping parameters.
;   
;---------------------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/input_shaping/autocalibration.g"
M118 S{"[autocalibration.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Check dependencies
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/input_shaping/system_identification.g"} F{var.CURRENT_FILE} E88200

; Run system identification
M98 P"/macros/input_shaping/system_identification.g"
; Check the report file has been generated
M98 P"/macros/assert/abort_if_file_missing.g" R{global.sysidReportID^"report.txt"} F{var.CURRENT_FILE} E88201

; The report file is a flattened one-row csv, where the first 15 elements corresponds to the header and the last 15 elements to the values. The header is:
;       "epoch","X_omega_n","X_zeta","Y_omega_n","Y_zeta"
; Read the values from the report file (elements from 16 to 30) and pick x-y omega_n and damping ratio 
var REPORT     = fileread(global.sysidReportID^"report.txt", 5, 5, ',')
var X_OMEGA    = var.REPORT[1]
var X_DAMPING  = var.REPORT[2]
var Y_OMEGA    = var.REPORT[3]
var Y_DAMPING  = var.REPORT[4]

; Definitions
var DIFF_THRESHOLD = 0.25        ; Max allowable percentage deviation from the previous input shaping parameters (quite high for now: 25%)
var EI2_BANDWIDTH  = 0.35        ; EI2 shaping frequency (bandwidth +-35%)

; Define for which frequency and damping ratio to center the input shaping
var IS_DAMPING = (var.X_DAMPING + var.Y_DAMPING) / 2
var IS_OMEGA   = var.X_OMEGA / (1 - var.EI2_BANDWIDTH)            
; Get the difference in percentage from the previous configuration
var DIFF_DAMPING = abs(global.inputShapingDamping - var.IS_DAMPING) / global.inputShapingDamping
var DIFF_OMEGA   = abs(global.inputShapingOmega - var.IS_OMEGA) / global.inputShapingOmega

; Update input shaping if new values are valid
if (var.DIFF_DAMPING < var.DIFF_THRESHOLD && var.DIFF_OMEGA < var.DIFF_THRESHOLD)
    set global.inputShapingOmega    = var.IS_OMEGA 
    set global.inputShapingDamping  = var.IS_DAMPING 
    M593 P"ei2" F{global.inputShapingOmega} S{global.inputShapingDamping}
    M118 S{"[autocalibration.g] Input Shaping EI2 centered at "^global.inputShapingOmega^" Hz, damping ratio "^global.inputShapingDamping}
else
    M118 S{"[autocalibration.g] Input Shaping not updated: new parameters differ more than 10% from the previous ones. Try to run the system identification again."}

M118 S{"[autocalibration.g] Done "^var.CURRENT_FILE}
M99 ; Proper exit
