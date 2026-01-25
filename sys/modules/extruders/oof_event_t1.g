; Description: 	
;	The out-of-filament sensor in T1 changed it status.
;------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/extruders/oof_event_t1.g"
M118 S{"[OOF] Starting " ^var.CURRENT_FILE}
; -----------------------------------------------------------------------------

M98 P"/sys/modules/extruders/oof_event.g" T1

; -----------------------------------------------------------------------------
M118 S{"[OOF] Done " ^var.CURRENT_FILE}
M99 ; Proper exit
