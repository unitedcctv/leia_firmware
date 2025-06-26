;------------------------------------------------------------------------------
; Mandatory check before starting the file to sync all the input channels
; --- Stubbed: always ready to operate ---
if(!exists(global.machineReadyToOperate))
	global machineReadyToOperate = false
 
set global.machineReadyToOperate = true
M99