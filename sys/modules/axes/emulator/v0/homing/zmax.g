var CURRENT_FILE = "/sys/modules/axes/emulator/v0/homing/zmax.g"
M118 S{"[HOMING] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}
G92 Z{move.axes[2].max}
G4 S1
M118 S{"[HOMING] Done "^var.CURRENT_FILE}
M99
