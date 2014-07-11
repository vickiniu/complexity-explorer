globals[
  a_11
  a_12
  a_21
  a_22
  x
  y
  prev_x
  prev_y
  pos_vector
]

turtles-own[ show? ]

to setup
  ca
  reset-ticks
  set pos_vector [0 0]
  set x x_i set y y_i
  ask patches [set pcolor white]
  ask patches with [pxcor = 0 or pycor = 0]
  [set pcolor black]
  plot-point
end

to transform
  set pos_vector (list x y)
  transform-mat
  translate-vector
  set x item 0 pos_vector
  set y item 1 pos_vector
  plot-point
end

to output
  clear-output
  output-type "[ " output-type prev_x output-type " ]   [ " output-type a_11 output-type "   " output-type a_12 output-type " ]   [ " output-type t_x output-type " ]     [ " output-type precision(item 0 pos_vector)3 output-print " ]"
  output-type "[ " output-type prev_y output-type " ] x [ " output-type a_21 output-type "   " output-type a_22 output-type " ] + [ " output-type t_y output-type " ]  =  [ " output-type precision(item 1 pos_vector)3 output-print " ]"
end

to plot-point
  set x precision x 2
  set y precision y 2
;  if(x > 10 or y > 10) [stop]
  carefully[
    ask patch 0 0[
      sprout 1[
        set color blue
        set size 10
        ifelse(x = 0 and y = 0)
        [set heading 0]
        [set heading atan x y]
        ifelse vector?
        [pd setxy (10 * x) (10 * y) pu]
        [setxy (10 * x) (10 * y)]
      ]
    ]
  ]
  [ user-message "The transformed point is beyond the scope of this plot!\nPress OK to reset the point" 
    setup]
  if label? [ask turtles[set label-color black set label (list precision(xcor / 10)2 precision(ycor / 10)2)]]
  ask turtles[
    if(who < ticks - 1 )[
      hide-turtle
      pe
      set pen-size 3
      setxy 0 0]
    if(who < ticks)[ set color 107
    ]
    ]
  tick
end

to transform-mat
  make-mat
  let x-cor 23
  let y-cor 52
  set x-cor (a_11 * (item 0 pos_vector) + a_12 * (item 1 pos_vector))
  set y-cor (a_21 * (item 0 pos_vector) + a_22 * (item 1 pos_vector))
  set prev_x (item 0 pos_vector)
  set prev_y (item 1 pos_vector)
  set pos_vector (list x-cor y-cor)
end

;;Performing the translation based on the inputs from the
;;interface, corresponding to the matrix transformation
;;previously performed (indicated by which)
to translate-vector
  let x-cor 0
  let y-cor 0
  set x-cor (item 0 pos_vector) + t_x
  set y-cor (item 1 pos_vector) + t_y
  set pos_vector (list x-cor y-cor)
  output
end

to make-mat
  set a_11 precision (scale_x * cos(rot_x))3 set a_12 precision(scale_y * sin(rot_y))3 set a_21 precision(-1 * scale_x * sin(rot_x))3 set a_22 precision(scale_y * cos(rot_y))3
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
622
443
100
100
2.0
1
10
1
1
1
0
0
0
1
-100
100
-100
100
0
0
1
ticks
30.0

BUTTON
18
109
95
142
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

INPUTBOX
21
284
71
344
x_i
5
1
0
Number

INPUTBOX
71
284
121
344
y_i
5
1
0
Number

INPUTBOX
647
70
697
130
rot_x
60
1
0
Number

INPUTBOX
647
130
697
190
rot_y
60
1
0
Number

INPUTBOX
705
70
755
130
scale_x
4
1
0
Number

INPUTBOX
705
130
755
190
scale_y
4
1
0
Number

INPUTBOX
763
70
813
130
t_x
0
1
0
Number

INPUTBOX
763
130
813
190
t_y
0
1
0
Number

BUTTON
94
109
182
142
Transform
transform
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
20
189
123
222
vector?
vector?
0
1
-1000

MONITOR
837
71
894
116
NIL
a_11
3
1
11

MONITOR
893
71
950
116
NIL
a_12
3
1
11

MONITOR
837
115
894
160
NIL
a_21
3
1
11

MONITOR
893
115
950
160
NIL
a_22
3
1
11

TEXTBOX
650
50
697
68
Rotation
11
0.0
1

TEXTBOX
710
50
753
68
Scale
11
0.0
1

TEXTBOX
763
50
825
68
Translation
11
0.0
1

TEXTBOX
838
50
988
68
Transformation Matrix
11
0.0
1

TEXTBOX
22
264
110
292
Initial Position
11
0.0
1

SWITCH
20
222
123
255
label?
label?
0
1
-1000

TEXTBOX
18
81
168
103
Procedures
16
0.0
1

TEXTBOX
18
160
168
182
Plot Options
16
0.0
1

TEXTBOX
15
11
188
72
Affine Transformations
18
95.0
1

TEXTBOX
646
10
870
28
Transformation Controls
16
0.0
1

OUTPUT
646
237
1086
317
12

TEXTBOX
645
216
795
234
Transformation Operations
11
0.0
1

@#$#@#$#@
## WHAT IS IT?

This model introduces linear affine transformations, by having the user experiment with applying various scaling, rotation, and translation operations to a point in the plane. A translation is performed on a point via vector addition. Then, a point can be scaled if it is multiplied by a scalar constant. Finally, a point can be rotated by multiplication by a rotation matrix. In our representation, the scaling of the point is incorporated into the matrix multiplication, so that a single operation scales, reflects, and rotates the point. The user can see the transformation matrix resulting from their desired scaling and rotation, and the matrix multiplication and vector addition operations are shown in the output window.

## HOW IT WORKS

After choosing an initial point, the user controls  three sets of inputs: scaling, rotation, and translation (on the x and y axes). The amount of rotation is expressed as a rotation matrix as follows:

&nbsp;&nbsp;&nbsp;&nbsp;[cosθ<sub>x</sub>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;sinθ<sub>y</sub>]
&nbsp;&nbsp;&nbsp;&nbsp;[-sinθ<sub>x</sub>&nbsp;&nbsp;&nbsp;&nbsp;cosθ<sub>y</sub>]

where θ<sub>x</sub> and θ<sub>y</sub> represent the number of degrees clockwise the x- and y-axes, respectively, are rotated.

When incorporating the scale factors, the matrix becomes:
&nbsp;&nbsp;&nbsp;&nbsp;[scale<sub>x</sub> * cosθ<sub>x</sub>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;scale<sub>y</sub> * sinθ<sub>y</sub>]
&nbsp;&nbsp;&nbsp;&nbsp;[-scale<sub>x</sub> * sinθ<sub>x</sub>&nbsp;&nbsp;&nbsp;&nbsp;scale<sub>y</sub> * cosθ<sub>y</sub>]

The total operation (matrix multiplication and vector addition) is:
&nbsp;&nbsp;&nbsp;&nbsp;[scale<sub>x</sub> * cosθ<sub>x</sub>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;scale<sub>y</sub> * sinθ<sub>y</sub>]&nbsp;&nbsp;&nbsp;&nbsp;[x<sub>i</sub>]&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[t<sub>x</sub>]&nbsp;&nbsp;&nbsp;&nbsp;[x]  <br>&nbsp;&nbsp;&nbsp;&nbsp;[-scale<sub>x</sub> * sinθ<sub>x</sub>&nbsp;&nbsp;&nbsp;&nbsp;scale<sub>y</sub> * cosθ<sub>y</sub>]&nbsp;*&nbsp;[y<sub>i</sub>]&nbsp;&nbsp;&nbsp;&nbsp;+&nbsp;&nbsp;[t<sub>y</sub>]&nbsp;=&nbsp;[y]

The model iterates this, so that the new coordinates generated from the current transformation become the input coordinates to the next transformation.

## HOW TO USE IT

First, pick an initial point, with x-coordinate between -10 and 10, and y-coordinate between -10 and 10. If you wish to see the point drawn as a position vector, make sure the vector? switch is on, and if you wish to see the point labeled with its coordinates, turn on the label? switch. Then, move to the right-hand side of the interface and input degree values (0-360) for rot_x and rot_y, a scale factor for scale_x and scale_y (it can be negative!) and some translation for t_x and t_y. Then, press transform and see how the newly generated point (the darker colored one) results from the transformations you selected and your previous point. Keep iterating the model by pressing the transform button to see the gradual changes. If the point goes outside the worldview, simply select new initial coordinates within the domain and range, and start again.

Look in the ouput window on the right-hand side to see the transformations expressed as matrix multplication and vector addition. Try taking your initial point and computing the transformed point by hand, and then compare it against the model output.

## CREDITS AND REFERENCES

This model is part of the Fractals series of the Complexity Explorer project.  
 
Main Author:  Vicki Niu

Netlogo:  Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.


## HOW TO CITE

If you use this model, please cite it as: Affine Transformations model, Complexity Explorer project, http://complexityexplorer.org

## COPYRIGHT AND LICENSE

Copyright 2013 Santa Fe Institute.  

This model is licensed by the Creative Commons Attribution-NonCommercial-NoDerivs 3.0 License ( http://creativecommons.org/licenses/by-nc-nd/3.0/ ). This states that you may copy, distribute, and transmit the work under the condition that you give attribution to ComplexityExplorer.org, and your use is for non-commercial purposes.
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
