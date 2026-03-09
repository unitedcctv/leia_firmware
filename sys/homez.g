; =========================  homeZ.g  =========================
; RRF 3.4 +  |  4× independent Z motors, end-stops at Z-max
; BLTouch configured in config.g with M558 / G31
; ============================================================

;--- Make sure X-Y are homed first ------------------------------------------
if {!move.axes[0].homed || !move.axes[1].homed}
  M98 P"homeXY.g"              ; or G28 XY

;--- Only home to Z-max if not already homed --------------------------------
if {!move.axes[2].homed}
  ;--- Safe clearance --------------------------------------------------------
  G91                              ; relative moves
  G1  H2  Z5  F600                 ; +5 mm to clear anything

  ;--- Fast move to Z-max to square the gantry ------------------------------
  G1  H1  Z{move.axes[2].max} F2400  ; up until EACH of the 4 end-stops triggers

  ;--- Back-off and slow re-touch for precision -----------------------------
  G1  H2  Z-3 F600                 ; drop 3 mm (end-stop ignored)
  G1  H1  Z4  F300                 ; creep back into the switches
  G1  H2  Z-60 F600                 ; drop 60 mm (end-stop ignored)

  G90                              ; absolute moves
  G92 Z{move.axes[2].max}          ; tell firmware we are at Z max height
else
  ;--- Z already homed, just ensure we're in absolute mode ------------------
  G90                              ; absolute moves

;--- Move to probing point above the bed ------------------------------------
;G1  X500 Y250 F6000  ; adjust coords

;--- Probe the bed with BLTouch ---------------------------------------------
M401                      ; deploy BLTouch on 20.io0
G30                       ; single probe – sets Z = trigger height
M402                      ; retract probe

; =======================  end of homeZ.g  =======================