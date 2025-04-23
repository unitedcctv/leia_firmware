; Description:
;	Enable the moving without homing.
;------------------------------------------------------------------------------
M118 S{"[AXES] Enabling move without homing"}
M98 P"/macros/report/warning.g" Y"Dangerous operation" F"/macros/axes/move_without_homing.g" W51400
M564 H0

;------------------------------------------------------------------------------
M99 ; Proper exit