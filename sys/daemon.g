; Description:
;	This file is automatically execute all the time.
;	File required by Duet3D. 
;	NOTE: Avoid long pauses and delays in this function and subfunctions!
;	It can be stopped using global.daemonStop:
;		set global.daemonStop = false ; Stop daemon.g
;		set global.daemonStop = true  ; Resume daemon.g (default value)
; -----------------------------------------------------------------------------
if(!exists(global.daemonStop))
	global daemonStop = false	; Set to 1 to stop the daemon.g, it can be use to upload a new daemon.g file

if(!exists(global.daemonTasks))
	global daemonTasks = null

if(global.daemonTasks == null || #global.daemonTasks == 0)
	set global.daemonStop = true
else 
	set global.daemonStop = false

if(!exists(global.daemonLastRuntime))
	global daemonLastRuntime = 0

while( global.daemonStop == false )
	var timestamp = state.upTime * 1000 + state.msUpTime
	if(global.daemonTasks != null)
		var TASKS = global.daemonTasks
		var counter = #var.TASKS
		while( var.counter > 0 )
			set var.counter = var.counter - 1
			var FILE = var.TASKS[var.counter]
			if(var.FILE != null)
				M98 P{var.FILE}
	set global.daemonLastRuntime = state.upTime * 1000 + state.msUpTime - var.timestamp
	G4 S0.5
M99; Exit