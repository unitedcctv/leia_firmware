; Description: 	
;	We will remove a file from the daemon.g list of tasks to execute.
; Input parameters:
;	- F: Path to the file to be removed.
; Example:
;	M98 P"/macros/files/daemon/remove.g" F"/sys/modules/cbc/control.g"
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/files/daemon/add.g"

; Checking global variables and input parameters ------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if.g" 		R{!exists(param.F)}  			Y{"Missing required input parameter F"}  F{var.CURRENT_FILE} E58200
M98 P"/macros/assert/abort_if_null.g"	R{param.F}			  			Y{"Input parameter F is null"} 			 F{var.CURRENT_FILE} E58201
M98 P"/macros/assert/abort_if.g" 		R{param.F == ""} 	 			Y{"Input parameter F is empty"} 		 F{var.CURRENT_FILE} E58202
M98 P"/macros/assert/abort_if.g" 		R{!exists(global.daemonTasks)} 	Y{"Missing required global daemonTasks"} F{var.CURRENT_FILE} E58203
M98 P"/macros/assert/abort_if_null.g" 	R{global.daemonTasks} 			Y{"Global daemonTasks is null"} 		 F{var.CURRENT_FILE} E58204
M98 P"/macros/assert/abort_if.g"	 	R{#global.daemonTasks == 0} 	Y{"Global daemonTasks is empty"} 		 F{var.CURRENT_FILE} E58205

; Checking if the file is in the list -----------------------------------------
var indexToDelete = null
while true
	if (iterations >= #global.daemonTasks)
		break
	if (global.daemonTasks[iterations] == null)
		M98 P"/macros/report/warning.g" Y{"Unexpected null task path in index: %s"} A{iterations,} 					F{var.CURRENT_FILE} W58200
	elif (global.daemonTasks[iterations] == "")
		M98 P"/macros/report/warning.g" Y{"Unexpected empty task path in index: %s"} A{iterations,}  					F{var.CURRENT_FILE} W58201
	elif (global.daemonTasks[iterations] == param.F)
		set var.indexToDelete = iterations
		break
M98 P"/macros/assert/abort_if_null.g"	 	R{var.indexToDelete} 	Y{"The file is not listed as a task"}	 	F{var.CURRENT_FILE} E58206

; Removing the task from the list ---------------------------------------------
if(#global.daemonTasks == 1)
	set global.daemonTasks = null
else
	var tasks = vector( #global.daemonTasks - 1 , null )
	var counter = 0
	while true
		if iterations >= #global.daemonTasks
			break
		if iterations != var.indexToDelete
			set var.tasks[var.counter] = global.daemonTasks[iterations]
			set var.counter = var.counter + 1
	set global.daemonTasks = var.tasks ; Updating daemonTasks

; Reporting -------------------------------------------------------------------
M118 S{"[DAEMON] Tasks removed: "^param.F}

; -----------------------------------------------------------------------------
M99 ; Proper exit
