; Description: 	
;	We will add a file to the daemon.g list of tasks to execute.
; Input parameters:
;	- F: Path to the file to be added.
; Example:
;	M98 P"/macros/files/daemon/add.g" F"/sys/modules/cbc/viio/v0/control.g"
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/files/daemon/add.g"
M118 S{"[DAEMON] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if.g" 		R{!exists(param.F)}  	Y{"Missing required input parameter F"} F{var.CURRENT_FILE} E58100
M98 P"/macros/assert/abort_if_null.g"	R{param.F}			  	Y{"Input parameter F is null"} 			F{var.CURRENT_FILE} E58101
M98 P"/macros/assert/abort_if.g" 		R{param.F == ""} 	 	Y{"Input parameter F is empty "} 		F{var.CURRENT_FILE} E58102
M98 P"/macros/assert/abort_if_file_missing.g" R{param.F} 	 											F{var.CURRENT_FILE} E58103

; Checking if the file is in the global.daemonTasks list -----------------------------------------
if(exists(global.daemonTasks) && (global.daemonTasks != null) && (#global.daemonTasks>0))
	while true
		if (iterations >= #global.daemonTasks)
			break
		if (global.daemonTasks[iterations] == null)
			M98 P"/macros/report/warning.g" Y{"Unexpected null task path in index: %s"} A{iterations,} 		F{var.CURRENT_FILE} W58100
		elif (global.daemonTasks[iterations] == "")
			M98 P"/macros/report/warning.g" Y{"Unexpected empty task path in index: %s"} A{iterations,} 		F{var.CURRENT_FILE} W58101
		elif (global.daemonTasks[iterations] == param.F)
			M98 P"/macros/report/warning.g"	Y{"The file is already listed as a task"}	 				F{var.CURRENT_FILE} W58104
			M99

; Adding the new task --------------------------------------------------------
if(!exists(global.daemonTasks))
	global daemonTasks = { param.F, }
elif(global.daemonTasks == null || #global.daemonTasks == 0)
	set global.daemonTasks = { param.F, }
else
	var tasks = vector( #global.daemonTasks + 1 , null )
	while true
		if iterations >= #global.daemonTasks
			break
		set var.tasks[iterations] = global.daemonTasks[iterations]
	set var.tasks[#global.daemonTasks] = param.F
	set global.daemonTasks = var.tasks

; Reporting -------------------------------------------------------------------
M118 S{"[DAEMON] Tasks added: "^param.F}

; -----------------------------------------------------------------------------
M118 S{"[DAEMON] Done "^var.CURRENT_FILE}
M99 ; Proper exit
