; The backlashtest macro has the same functionality as on the PRO machine.
; It moves Y back and forth 5 times with a distance of 8mm and a speed of 4000mm/min.
; Prerequisites
; - Door is closed
; - Machine is homed or "move without homing" is enabled

; Relative positioning
G91

var MOVE_DIST = 8
var MOVE_SPEED = 4000
var WAIT_TIME = 0.2
var NUM_RUNS = 5
var WAIT_BETWEEN_RUNS = 1

var run = 0
while (var.run < var.NUM_RUNS)
    G0 F{var.MOVE_SPEED} Y{var.MOVE_DIST}
    G4 S{var.WAIT_TIME}
    G0 F{var.MOVE_SPEED} Y{-var.MOVE_DIST}
    G4 S{var.WAIT_TIME}
    set var.run = var.run + 1
    G4 S{var.WAIT_BETWEEN_RUNS}

M400
M99