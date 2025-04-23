; Description: 	
;	Updates the configuration. The old configuration links are moved to: 
;	'/sys/links'.
;------------------------------------------------------------------------------
M118 S{"[CONFIG] Updating to new configuration"}

; Removing the links folder ---------------------------------------------------
M118 S{"[CONFIG] Cleaning the previous links folder"}
M471 S"/sys/links" T{"/sys/temp/links_"^{+state.time}} D1

;M98 P"/macros/report/event.g" Y{"Restarting to update config"}  F"/macros/machine/configuration/update.g" V62200
;M118 S{"[CONFIG] Restarting board in 3 sec"}
;G4 S3

M99 ; Restarting