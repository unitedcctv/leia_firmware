; Description: 	
;	Post selection tool script.
;	To be called from tpost0.g or tpost1.g when using generic extruders.
;   We cannot abort in tool change macros as per doc https://docs.duet3d.com/en/User_manual/Tuning/Tool_changing
; Ïnput Parameters:
;	- T: Tool number (0 or 1) to execute the post selection.
; Example:
;	M98 P"/macros/extruder/tpost.g" T0
;------------------------------------------------------------------------------


; this file is currently unused
M99 ; Proper exit