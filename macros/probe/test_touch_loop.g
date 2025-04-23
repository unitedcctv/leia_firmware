var NUMPOINTS = (exists(param.N) && param.N != null) ? param.N : 3
var NUMSAMPLES = (exists(param.S) && param.S != null) ? param.S : 3
var RECT = (exists(param.R) && param.R != null && #param.R == 4) ? param.R : {100,100,300,300}
var TOOL = (exists(param.T) && param.T == 1) ? 1 : 0

M118 S{"[test_touch_loop.g] Starting test_touch_loop.g with N: " ^ var.NUMPOINTS ^ " S: " ^ var.NUMSAMPLES ^ " R: " ^ var.RECT ^ " T: " ^ var.TOOL}

; first, test at the probe zero position
while iterations < var.NUMSAMPLES
	M118 S{"[test_touch_loop.g] PROBE_START position, iteration: " ^ iterations+1}
	M400
	M98 P"/sys/modules/stage/viio/v2/detect_bed_touch.g" X{global.PROBE_START_X} Y{global.PROBE_START_Y} T{var.TOOL}
	M400
M400

while iterations < var.NUMPOINTS
	var randX = random(var.RECT[2] - var.RECT[0]) + var.RECT[0]
	var randY = random(var.RECT[3] - var.RECT[1]) + var.RECT[1]
	M118 S{"[test_touch_loop.g] Testing at point X: " ^ var.randX ^ " Y: " ^ var.randY ^ " iteration: " ^ iterations+1}
	while iterations < var.NUMSAMPLES
		M118 S{"[test_touch_loop.g] Sample: " ^ iterations+1}
		M400
		M98 P"/sys/modules/stage/viio/v2/detect_bed_touch.g" X{var.randX} Y{var.randY} T{var.TOOL}
		M400
	M400
M99