; Description: 	
;	Nozzle wipe station removed - no wipe station on this printer.
;------------------------------------------------------------------------------
M118 S{"[wipe.g] No wipe station installed, skipping"}
if exists(param.I)
	M118 S{"#I"^param.I^"#DONE"}
M99
