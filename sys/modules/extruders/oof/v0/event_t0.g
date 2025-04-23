; Description: 	
;	The out-of-filament sensor in T0 changed it status.
;------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/extruders/oof/v0/event_t0.g"
M118 S{"[OOF] Starting " ^var.CURRENT_FILE}
; -----------------------------------------------------------------------------

M98 P"/sys/modules/extruders/oof/v0/event.g" T0

; -----------------------------------------------------------------------------
M118 S{"[OOF] Done " ^var.CURRENT_FILE}
M99 ; Proper exit
