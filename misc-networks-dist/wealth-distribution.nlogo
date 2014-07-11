globals [
  curr_x
  resize?
  gini
  ;prob-trade
  ]

breed [ houses house]
breed [bills bill]

houses-own[
  min-x
  max-x
  num-dollars
  new-size
]

bills-own[
  house-num
  move?
]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;; Setup Procedures ;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  ca
  set resize? true
  ;Creating houses, all of size 10
  set curr_x -200
  while[curr_x < 195]
  [
    create-houses 1[
      set shape "house ranch"
      set size 10
      set xcor curr_x + 5
      set ycor 10 + 10 / 3
      set curr_x xcor + 5
    ]
  ]
  ask houses[
    set max-x xcor + size / 2
    set min-x xcor - size / 2
  ]
  reset-ticks
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;; Money Procedures ;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to add-money
  ;Initial addition without resizing
  while[count bills < 35][
    make-money
    repeat 100 [money-fall]
    money-display
    ask bills [set move? true]
    money-move
  ]
  ;Resizing
  resize-houses
  ;Shifting bills to align
  money-move
  ;Adition of money with houses resizing at each new addition
  while[count bills < money-supply][
    make-money
    repeat 100 [money-fall]
    money-display
    resize-houses
    ask bills [set move? true]
    money-move
  ]
  money-move
  set resize? true
end

;Money falls 10 bills at a time
to make-money
  create-bills 10[
    set move? true
    set shape "dollar bill"
    set color green
    set size 10
    set xcor random-xcor
    set ycor 80]
  money-sort
end

;Moves the money down the screen in steps
to money-fall
  ask bills with [move?][
    if (ycor < 5) [ stop]
    downhill4 pycor
    wait 0.002
  ]
  let num-done count bills with [ycor < 0]
  if(num-done = count bills)[stop]
end

;Sets the money to different houses, and colors appropriately
;Also adds the wealth to the houses
to money-sort
  ask houses[
    let min-val min-x
    let max-val max-x
    let my-bills bills with [xcor > min-val and xcor < max-val]
    if any? my-bills [
      set num-dollars count my-bills
      ask my-bills[set house-num [who] of myself]]
  ]
  ask bills[set color [color] of house house-num]
  tick
end

;Displays the labels at the bottom of the screen which indicate a household's wealth
to money-display
  ask houses[
    let money num-dollars
    ask patch xcor -53[
      ifelse money > 0 [set plabel money][set plabel ""]
    ]
  ]
end

;Shifts the money so that it aligns with the house it belongs to
to money-move
  ask bills[set move? true]
  while[count bills with [move?] > 0]
  [
    ask one-of bills with [move?][
      let x-cor [xcor] of house house-num
      let y-cor 5  - 5 * (count other bills with [move? = false and xcor = x-cor])
      if(y-cor < -45)[set y-cor -45]
      setxy x-cor y-cor
      set move? false
    ]
  ]
  ask bills[set color [color] of house house-num]
  plot-lorenz
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;; House Procedures ;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;Resizes the houses according to their wealth. The size isn't in direct proportion to
;the wealth, but rather in relative proportion to the wealth of other houses.
to resize-houses
  if resize? [
    let total-size 400
    let total-money sum [num-dollars] of houses
    ask houses[
      set new-size num-dollars / total-money
    ]
    set curr_x -200
    let to-move houses
    while [any? to-move][
      ask min-one-of to-move [xcor][
        set size new-size * total-size
        set xcor curr_x + size / 2
        set ycor 10 + size / 3
        set curr_x xcor + size / 2
        set to-move other to-move
      ]
    ]
    ask patches [set plabel ""]
    money-display
    ask bills[set move? true]
  ]
  ask houses[
    set max-x xcor + size / 2
    set min-x xcor - size / 2
  ]
end

;to trade
;  ask one-of houses with [num-dollars > 0][
;    ifelse(random-float 1 < prob-trade / [num-dollars] of self)
;    [
;      set resize? true
;      let new-num []
;      let num-to-take random [num-dollars] of self + 1
;      output-print num-to-take
;      if(num-to-take > count houses - 1) [set num-to-take count houses - 1]
;      ifelse(num-to-take < 10)[ask roulette-wheel num-to-take [
;          set num-dollars num-dollars + 1
;          set new-num lput [who] of self new-num]]
;      [ask n-of num-to-take houses [
;          set num-dollars num-dollars + 1
;          set new-num lput [who] of self new-num]]
;      output-print new-num
;      set num-dollars num-dollars - num-to-take
;      let my-num [who] of self
;      let bills-to-ask nobody
;      ifelse(num-to-take < count bills with [house-num = my-num])
;      [set bills-to-ask n-of num-to-take bills with [house-num = my-num]]
;      [set bills-to-ask bills with [house-num = my-num]]  
;      ask bills-to-ask
;      [ set house-num item 0 new-num
;        set new-num remove item 0 new-num new-num 
;        set move? true
;        money-move]
;    ]
;    [set resize? false]
;  ]
;  ask bills[set move? true]
;  tick
;end

;to-report roulette-wheel [number]
;  let choose1 random 400
;  let chosen-house1 houses with [min-x < choose1 and max-x > choose1]
;  let chosen chosen-house1
;  while[count chosen < number][
;    let choose random 400
;    let chosen-house one-of houses with [min-x < choose and max-x > choose]
;    set chosen (turtle-set chosen chosen-house)
;  ]
;  report chosen
;end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;; Plotting Procedures ;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;Plots the lorenz curve, line of equality, and calculates the Gini coefficient
to plot-lorenz
  let ordered-list sort [num-dollars] of houses
  let cumulative-list []
  let current 0
  let gini-sum 0
  let x 1
  foreach ordered-list[
    set current current + ?
    set cumulative-list lput current cumulative-list
    set gini-sum gini-sum + ? * x
    set x x + 1
  ]
  set x 1
  set-current-plot "Cumulative Wealth Distribution"
  set-current-plot-pen "Lorenz Curve"
  plot-pen-reset
  plot-pen-up
  plotxy 0 0
  plot-pen-down
  foreach cumulative-list[
    plotxy 100 * (x / count houses) 100 * ( ? / max cumulative-list)
    set x x + 1
  ]
  let n count houses
  set gini (2 * gini-sum) / (n * sum(ordered-list)) - (n + 1) / n
end
@#$#@#$#@
GRAPHICS-WINDOW
8
150
880
473
200
-1
2.15
1
10
1
1
1
0
0
0
1
-200
200
-55
80
0
0
1
ticks
30.0

BUTTON
13
86
130
119
Make Houses
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

PLOT
912
149
1288
318
Wealth Distribution
Wealth
Count
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 2.0 1 -13791810 true "" "histogram [num-dollars] of houses\nif(max [num-dollars] of houses > 10)[set-plot-x-range 0 max [num-dollars] of houses]"

BUTTON
129
86
244
119
Add Money
add-money
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
440
83
532
128
# of Households
count houses with [size > 0]
17
1
11

TEXTBOX
13
14
180
34
The Rich Get Richer
18
95.0
1

TEXTBOX
15
53
165
73
Procedures
16
0.0
1

SLIDER
267
85
401
118
money-supply
money-supply
0
200
100
1
1
NIL
HORIZONTAL

TEXTBOX
269
52
419
72
Settings
16
0.0
1

PLOT
912
318
1288
472
Cumulative Wealth Distribution
Cumulative Population (%)
Cum. Wealth (%)
0.0
100.0
0.0
100.0
true
true
"" ""
PENS
"Lorenz Curve" 1.0 0 -13791810 true "" ""
"Line of Equality" 1.0 0 -16777216 true "plot-pen-up\nplotxy 0 0\nplot-pen-down\nplotxy 100 100" ""

MONITOR
532
83
632
128
Gini Coefficient
gini
5
1
11

TEXTBOX
441
50
591
70
Statistics
16
0.0
1

TEXTBOX
913
48
1063
68
Plots
16
0.0
1

TEXTBOX
912
73
1289
132
The \"Wealth Distribution\" plot shows a histogram of the various individuals' wealths. The cumulative wealth distribution shows how much of the population (on the x-axis) owns a proportion of the wealth (on the y-axis). If income were equally distributed, the Lorenz Curve would equal the Line of Equality.
11
0.0
1

TEXTBOX
640
75
883
131
The Gini coefficient measures of wealth inequality. It's the area between the line of equality and the Lorenz Curve on the cumulative wealth plot. The closer to 1 it is, the more unequal the wealth.
11
0.0
1

@#$#@#$#@
## WHAT IS IT?

This model showcases the principle of preferential attachment, using the case study of wealth distribution. At a deeper level, this model explores the patterns which give rise to a power law distribution, such as this "rich get richer" model.

## HOW IT WORKS

Initially, there are 40 houses populating the world, each of the same size. Money falls randomly from the top of the worldview. As it falls into a certain household, it adds to that household's wealth. After an initial period of time, the houses begin to resize proportional to the amount of money they have. Thus, as the money continues to fall randomly, the larger houses (which have more money) are more likely to be on the receiving end. This illustrates the idea of preferential attachment -- those who are the wealthiest are the most likely to become more wealthy at each timestep.

## HOW TO USE IT

To set up the original world, hit "Make Houses". This will generate the 40 different houses, with randomly assigned colors. Then, if you hit "Add Money", the bills will begin to drift down from the top. The colors of the bills match the house whose wealth they add to. The slider labelled "money-supply" controls how much wealth is being added. Then, if you look to the right of that, you can see the Number of Households and the Gini Coefficient. The number of households is significant because although the model will consistently start with 40 houses, a large number of those cease to exist (get pushed out of the market) because they failed to collect enough wealth. The Gini coefficient is an important measure of wealth distribution. At 0, it indicates that all households hold the same amount of wealth, and at 1, that one household owns all the wealth. It measures the area between the line of equality and the Lorenz Curve, which are plotted under "Cumulative Wealth Distribution". Finally, the histogram above shows the "Wealth Distribution", which follows a power law distribution.

## THINGS TO NOTICE

In addition to tracking the distribution of wealth in the "Wealth Distribution" histogram, the wealth belonging to a house is all displayed below it. Additionally, there are labels at the bottom of the screen corresponding to the number of bills that each household has. 

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

coin heads
false
0
Circle -7500403 true true 15 15 270
Circle -16777216 false false 22 21 256
Line -16777216 false 165 180 192 196
Line -16777216 false 42 140 83 140
Line -16777216 false 37 151 91 151
Line -16777216 false 218 167 265 167
Polygon -16777216 false false 148 265 75 229 86 207 113 191 120 175 109 162 109 136 86 124 137 96 176 93 210 108 222 125 203 157 204 174 190 191 232 230
Polygon -16777216 false false 212 142 182 128 154 132 140 152 149 162 144 182 167 204 187 206 193 193 190 189 202 174 193 158 202 175 204 158
Line -16777216 false 164 154 182 152
Line -16777216 false 193 152 202 153
Polygon -16777216 false false 60 75 75 90 90 75 105 75 90 45 105 45 120 60 135 60 135 45 120 45 105 45 135 30 165 30 195 45 210 60 225 75 240 75 225 75 210 90 225 75 225 60 210 60 195 75 210 60 195 45 180 45 180 60 180 45 165 60 150 60 150 45 165 45 150 45 150 30 135 30 120 60 105 75

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

dollar bill
false
0
Rectangle -7500403 true true 15 90 285 210
Rectangle -1 true false 30 105 270 195
Circle -7500403 true true 120 120 60
Circle -7500403 true true 120 135 60
Circle -7500403 true true 254 178 26
Circle -7500403 true true 248 98 26
Circle -7500403 true true 18 97 36
Circle -7500403 true true 21 178 26
Circle -7500403 true true 66 135 28
Circle -1 true false 72 141 16
Circle -7500403 true true 201 138 32
Circle -1 true false 209 146 16
Rectangle -16777216 true false 64 112 86 118
Rectangle -16777216 true false 90 112 124 118
Rectangle -16777216 true false 128 112 188 118
Rectangle -16777216 true false 191 112 237 118
Rectangle -1 true false 106 199 128 205
Rectangle -1 true false 90 96 209 98
Rectangle -7500403 true true 60 168 103 176
Rectangle -7500403 true true 199 127 230 133
Line -7500403 true 59 184 104 184
Line -7500403 true 241 189 196 189
Line -7500403 true 59 189 104 189
Line -16777216 false 116 124 71 124
Polygon -1 true false 127 179 142 167 142 160 130 150 126 148 142 132 158 132 173 152 167 156 164 167 174 176 161 193 135 192
Rectangle -1 true false 134 199 184 205

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

house ranch
false
0
Rectangle -7500403 true true 270 120 285 255
Rectangle -7500403 true true 15 180 270 255
Polygon -7500403 true true 0 180 300 180 240 135 60 135 0 180
Rectangle -16777216 true false 120 195 180 255
Line -7500403 true 150 195 150 255
Rectangle -16777216 true false 45 195 105 240
Rectangle -16777216 true false 195 195 255 240
Line -7500403 true 75 195 75 240
Line -7500403 true 225 195 225 240
Line -16777216 false 270 180 270 255
Line -16777216 false 0 180 300 180

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
