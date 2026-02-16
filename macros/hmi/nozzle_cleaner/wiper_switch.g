; Description: 	
;	Nozzle wipe station removed - no wipe station on this printer.
;------------------------------------------------------------------------------
M118 S{"[wiper_switch.g] No wipe station installed"}
if exists(param.I)
	M118 S{"#I"^param.I^"#DONE"}
M99
