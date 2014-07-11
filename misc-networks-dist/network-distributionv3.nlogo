extensions [matrix]

globals[
  update-count
  clustering-coefficient
  plot?
  log-log-coeff
  semi-log-coeff
]

turtles-own[
  node-coeff
  num-links
  my-neighbors
  neighbor-links
  new?
  log-link
]


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;; Setup Procedures  ;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  ca
  set update-count 0
  set-default-shape turtles "person"
  set plot? false
  ifelse grow?
  [ make-turtles n ]
  [ make-turtles num-turtles ]
  reset-ticks
end

to go
  ask turtles [set num-links count link-neighbors]
  if grow?[ make-turtles n 
    ask (turtles with [new?]) [make-network]
  ]
  ask n-of n turtles[make-network]
  ask links [set color gray]
  if layout? [layout]
  find-clustering-coefficient
  if(any? turtles with [clustering-coefficient > 0]) [set plot? true]
  ask turtles[
    ifelse num-links > 0
    [set log-link log(num-links)10]
    [set log-link 0]
  ]
  tick
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Turtle Operations ;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to make-turtles[number-of-turtles]
  crt number-of-turtles[
    set xcor random-xcor set ycor random-ycor
    set color cyan
    set size 2
    set num-links 0
    set my-neighbors nobody
    set neighbor-links []
    set new? true
  ]
end

to update
  set new? false
  set update-count update-count + 1
  fd 2
  if(update-count mod 3 = 1)[rt random 360]
end

to observe
  ifelse grow?
  [set my-neighbors other turtles]
  [set my-neighbors other turtles in-radius radius]
  set neighbor-links [num-links] of my-neighbors
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;; Network Operations ;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to make-network
  update
  observe
  ifelse strategy = "Random"
  [random-links]
  [ifelse strategy = "Preferential Attachment"
    [create-links1]
    [renyi]
  ]
end


to create-links1
  let partner nobody
  ifelse (empty? neighbor-links or max neighbor-links = 0)[
    if any? my-neighbors [set partner one-of my-neighbors]
  ]
  [ set partner find-partner ]
  if not (partner = nobody) [create-link-with partner]
end

to-report find-partner
  let total random-float sum neighbor-links
  let partner nobody
  ask my-neighbors
  [
    let nc num-links
    ;; if there's no winner yet...
    if partner = nobody
    [
      ifelse nc > total
        [ set partner self ]
        [ set total total - nc ]
    ]
  ]
  report partner
end

to random-links
  ifelse(any? my-neighbors)[
    create-link-with one-of my-neighbors
  ]
  [stop]
end

to renyi
  create-link-with one-of other turtles
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;; Clustering Coefficient ;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to-report link-member? [ hood ]
  report ( member? end1 hood and member? end2 hood )
end


to find-clustering-coefficient
  ifelse count turtles with [count link-neighbors > 1] = 0
  [ set clustering-coefficient 0 ]
  [
    let total 0
    ask turtles with [ count link-neighbors <= 1] [ set node-coeff 0 ]
    ask turtles with [ count link-neighbors > 1]
    [
      let neighborhood link-neighbors
      let denom (factorial (count link-neighbors) / (2 * factorial (count link-neighbors - 2)))
      set node-coeff count links with [link-member? neighborhood] / denom
      set total total + node-coeff
    ]
    set clustering-coefficient total / count turtles with [count link-neighbors > 1]
  ]
end

to-report factorial [ num ]
  report ifelse-value (num <= 1 )
  [ 1 ] 
  [ reduce [ ?1 * ?2 ] (n-values num [ 1.0 + ? ] ) ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;; Plotting Operations ;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to regress
  let log-x []
  let log-y []
  let x []
  let max-degree max [count link-neighbors] of turtles
  let degree 1
  while [degree <= max-degree] [
    let matches turtles with [count link-neighbors = degree]
    if any? matches
    [ set log-x lput log degree 10 log-x
      set log-y lput log (count matches) 10 log-y
      set x lput degree x
    ]
    set degree degree + 1
  ]
  let log-log-output matrix:regress matrix:from-column-list(list log-y log-x)
  let semi-log-output matrix:regress matrix:from-column-list (list log-y x)
  set log-log-coeff item 0 (item 1 log-log-output)
  set semi-log-coeff item 0 (item 1 semi-log-output)
  set-current-plot "log-log Degree Distribution"
  plot-line (item 0 log-log-output)
  set-current-plot "semi-log Degree Distribution"
  plot-line (item 0 semi-log-output)
end

to plot-line [eq]
  let y-int item 0 eq
  let slope item 1 eq
  create-temporary-plot-pen "regression"
  set-plot-pen-color blue
  ;output-type "Y-intercept: " output-print y-int
  ;output-type "Slope: " output-print slope
  plotxy 0 y-int
  plot-pen-down
  plotxy plot-x-max (plot-x-max * slope + y-int)
  plot-pen-up  
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;; Layout ;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to layout
  ;; the number 3 here is arbitrary; more repetitions slows down the
  ;; model, but too few gives poor layouts
  repeat 3 [
    ;; the more turtles we have to fit into the same amount of space,
    ;; the smaller the inputs to layout-spring we'll need to use
    let factor sqrt count turtles
    ;; numbers here are arbitrarily chosen for pleasing appearance
    layout-spring turtles links (1 / factor) (7 / factor) (1 / factor)
    display  ;; for smooth animation
  ]
  ;; don't bump the edges of the world
  let x-offset max [xcor] of turtles + min [xcor] of turtles
  let y-offset max [ycor] of turtles + min [ycor] of turtles
  ;; big jumps look funny, so only adjust a little each time
  set x-offset limit-magnitude x-offset 0.1
  set y-offset limit-magnitude y-offset 0.1
  ask turtles [ setxy (xcor - x-offset / 2) (ycor - y-offset / 2) ]
end

to-report limit-magnitude [number limit]
  if number > limit [ report limit ]
  if number < (- limit) [ report (- limit) ]
  report number
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
675
496
45
45
5.0
1
10
1
1
1
0
1
1
1
-45
45
-45
45
1
1
1
ticks
20.0

SLIDER
13
105
193
138
num-turtles
num-turtles
0
500
288
1
1
NIL
HORIZONTAL

CHOOSER
13
138
193
183
strategy
strategy
"Preferential Attachment" "Random" "Erdos-Renyi"
1

BUTTON
15
47
79
82
Setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
70
47
129
82
Step
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
712
19
1060
308
Degree Distribution
Degree
# of People
0.0
10.0
0.0
10.0
true
false
"" "ifelse(max [num-links] of turtles > 10)\n[set-plot-x-range 0 max [num-links] of turtles]\n[set-plot-x-range 0 10]"
PENS
"default" 1.0 1 -16777216 true "" "histogram [num-links] of turtles"

SLIDER
13
183
193
216
radius
radius
0
50
5
1
1
NIL
HORIZONTAL

SLIDER
13
216
193
249
n
n
0
20
5
1
1
NIL
HORIZONTAL

SWITCH
13
249
103
282
layout?
layout?
0
1
-1000

BUTTON
129
47
192
82
Go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
103
249
193
282
grow?
grow?
0
1
-1000

MONITOR
972
315
1058
361
Cluster Coeff
clustering-coefficient
5
1
11

PLOT
713
315
972
495
Clustering Coefficient
Ticks
Clustering Coefficient
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot clustering-coefficient"

PLOT
1058
19
1310
165
log-log Degree Distribution
log(Degree)
log(Freq)
0.0
2.0
0.0
3.0
true
false
"" ""
PENS
"default" 1.0 2 -16777216 true "" "if not plot? [ stop ]\nlet max-degree max [count link-neighbors] of turtles\n;; for this plot, the axes are logarithmic, so we can't\n;; use \"histogram-from\"; we have to plot the points\n;; ourselves one at a time\nplot-pen-reset  ;; erase what we plotted before\n;; the way we create the network there is never a zero degree node,\n;; so start plotting at degree one\nlet degree 1\nwhile [degree <= max-degree] [\n  let matches turtles with [count link-neighbors = degree]\n  if any? matches\n    [ plotxy log degree 10\n             log (count matches) 10 ]\n  set degree degree + 1\n]"

PLOT
1059
165
1309
309
semi-log Degree Distribution
Degree
log(Freq)
0.0
2.0
0.0
3.0
true
false
"" ""
PENS
"default" 1.0 2 -16777216 true "" "if not plot? [ stop ]\nlet max-degree max [count link-neighbors] of turtles\n;; for this plot, the axes are logarithmic, so we can't\n;; use \"histogram-from\"; we have to plot the points\n;; ourselves one at a time\nplot-pen-reset  ;; erase what we plotted before\n;; the way we create the network there is never a zero degree node,\n;; so start plotting at degree one\nlet degree 1\nwhile [degree <= max-degree] [\n  let matches turtles with [count link-neighbors = degree]\n  if any? matches\n    [ plotxy degree\n             log (count matches) 10]\n  set degree degree + 1\n]"

BUTTON
1319
108
1425
142
Find best fit
regress
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
1319
19
1425
65
log-log correlation
log-log-coeff
5
1
11

MONITOR
1319
64
1425
110
semi-log correlation
semi-log-coeff
5
1
11

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 1.0 0.0
0.0 1 1.0 0.0
0.2 0 1.0 0.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
