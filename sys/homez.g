; =========================  homeZ.g  =========================
; RRF 3.4 +  |  4× independent Z motors, end-stops at Z-max
; BLTouch configured in config.g with M558 / G31
; ============================================================

;--- Make sure X-Y are homed first ------------------------------------------
if {!move.axes[0].homed || !move.axes[1].homed}
  M98 P"homeXY.g"              ; or G28 XY

;--- Safe clearance ----------------------------------------------------------
G91                              ; relative moves
G1  H2  Z5  F600                 ; +5 mm to clear anything

;--- Fast move to Z-max to square the gantry -------------------------------
G1  H1  Z{move.axes[2].max} F2400  ; up until EACH of the 4 end-stops triggers

;--- Back-off and slow re-touch for precision -------------------------------
G1  H2  Z-3 F600                 ; drop 3 mm (end-stop ignored)
G1  H1  Z4  F300                 ; creep back into the switches

G90                              ; absolute moves
G92 Z{move.axes[2].max}          ; tell firmware we are at Z max height

;--- Move to probing point above the bed ------------------------------------
G1  X500 Y250 F6000  ; adjust coords

;--- Move down 100 ----------------------------------------------------------
;G1 Z-200 ; removed drop, using immediate BLTouch probe

;--- needs bl touch ---------------------------------------------------------
; Drop most of the way, leaving 10 mm clearance
;G91
;G1  Z-{move.axes[2].max-10} F2400
;G90
;G1  Z10 F600

;--- Probe the bed with BLTouch ---------------------------------------------
M401                      ; deploy BLTouch on 20.io0
G30                       ; single probe – sets Z = trigger height
M402                      ; retract probe




;--- Lift a little so we’re not scraping ------------------------------------
;G91
;G1  Z5 F600
;G90

; Optional: load an existing height-map
; G29 S1

; =======================  end of homeZ.g  =======================