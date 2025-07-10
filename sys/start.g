; Description: 	
;	The start.g will be called every time a job is started from the SD-Card.
;	In this the 
;	   - check for the voltage
;	   - setting the starting power reading when the job begins
;	   - Setting the CBC temperature is set 0
;	   - checking whether the coldend fans are off or not
; TODO:
;	- Check if we have a power meter module, otherwise, disable the power read.
;---------------------------------------------------------------------------------------------
; Mandatory check before starting the file to sync all the input channels
if !inputs[state.thisInput].active
	M99
;------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/start.g"
M118 S{"[start.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
M98 P"/macros/assert/abort_if.g" R{global.errorRestartRequired}  Y{"Previous error requires restart: Please restart the machine"} F{var.CURRENT_FILE} E34208
; Setting the machine state
set global.hmiStateDetail = "job_starting"
; Checking for files first
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/files/logs/new.g"}	 	F{var.CURRENT_FILE} E34200
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/sensors/read_power.g"}	F{var.CURRENT_FILE} E34201
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/printing/get_ready.g"}	F{var.CURRENT_FILE} E34202

; Definitions -----------------------------------------------------------------
var START_TIME = {+state.time} ; Saving the time in epoch
var START_TIME_STR = {""^var.START_TIME} ; Start time as string

; Disable the forceAbort as we are canceling ----------------------------------
if(exists(global.forceAbort) && global.forceAbort)
	set global.forceAbort = false

; Setting the job UUID if necessary -------------------------------------------
if(!exists(global.jobUUID))
	global jobUUID = null

if(global.jobUUID == null)
	M118 S{"[start.g] Creating print UUID"}
	set global.jobUUID = {""^boards[0].uniqueId^"-"^var.START_TIME_STR}

; Open new log for the print job-----------------------------------------------
M118 S{"[start.g] New log file for printing "^ job.file.fileName}
M98 P"/macros/files/logs/new.g" C{(global.jobUUID != null) ? global.jobUUID : var.START_TIME_STR}

; Getting the power meter data ------------------------------------------------
M118 S{"[start.g] Reading the power meter"}
M98 P"/macros/sensors/read_power.g"
M98 P"/macros/assert/abort_if.g"		R{!exists(global.powerMeterValueStart)} 	Y{"Missing return value of read_power.g"} 	F{var.CURRENT_FILE} E34203
M98 P"/macros/assert/abort_if_null.g"   R{global.powerMeterValueStart} 				Y{"global powerMeterValueStart is null"} 	F{var.CURRENT_FILE} E34204
M118 S{"[start.g] Print started with power meter at "^global.powerMeterValueStart^"kWh"}

; turn off tools that are not used by the job
M118 S{"[start.g] used filament: "^job.file.filament}
while iterations < #job.file.filament
	if exists(tools[iterations])
		if job.file.filament[iterations] == 0
			if heat.heaters[tools[iterations].heaters[0]].state != "off"
				M98 P"/macros/report/event.g" Y{"Turning off unused tool %s"} A{iterations,} F{var.CURRENT_FILE} V34206
				M568 P{iterations} R-273.1 S-273.1 A2
			M400
		M400
M400
; Making sure the fans are off ------------------------------------------------
M118 S{"[start.g] Turning off the fans"}
M107

; Setting the machine is print state ------------------------------------------
M118 S{"[start.g] Getting the machine ready"}
M98 P"/macros/printing/get_ready.g"


M118 S{"[start.g] Running with file: "^job.file.fileName}
set global.hmiStateDetail = "job_heating"
;------------------------------------------------------------------------------
M118 S{"[start.g] Done "^var.CURRENT_FILE}
M99 ; proper exit