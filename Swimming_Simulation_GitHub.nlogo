globals [
  collision-midle-lane          ; Counts collisions in the middle lane
  collisions-over-time          ; Tracks collisions over time
  number-of-collisons           ; Total number of collisions

  secondes                      ; Number of seconds passed in simulation
  delay-total                   ; Total delay accumulated
  delay-average                 ; Average delay per turtle

  pools                         ; List of pool configurations (number of lanes)
  lanes-length                  ; List of lengths of lanes in each pool

  range-swimmer-view            ; Range of visibility for swimmers
  number-overtakes              ; Count of overtakes by swimmers

  i-speed
  minutes

  centroids
]

turtles-own [
  next-move-x                   ; X direction for next move
  next-move-y                   ; Y direction for next move
  target                        ; Current target lane (0 or 1)
  top-speed                     ; Maximum speed of the turtle
  collision-flag                ; Flag to indicate collision occurrence
  time-lane                     ; Time spent in current lane
  time-save                     ; Last saved time
  previous-target               ; Previous target lane
  time-lane-plot                ; Time spent in lane for plotting
  number-tours                  ; Number of laps completed
  ybottom                       ; Bottom lane y-coordinate

  simulation-length             ; Length of the lane for each swimmers in the simulation

  index-speed

  swimming-style-index-map ;
]

to setup
  clear-all
  clear-output

  set minutes 0
  print("******* New Run********")

  set i-speed 0

  set number-overtakes 0

  set collision-midle-lane 0
  set collisions-over-time 0
  set number-of-collisons 0

  setup-grid
  create-or-remove-swimmers

  set secondes 0
  set delay-total 0

  reset-ticks
end
to create-or-remove-swimmers
  ; Determine available patches for swimmers (blue patches not in the middle of lanes)
  let available-patches patches with [pcolor != (rgb 0 0 0) and pycor mod 4 != 2]

  ; Current number of turtles
  let current-swimmers count turtles

  ; Add new swimmers if current count is less than desired
  if current-swimmers < number-of-swimmers and any? available-patches [
    let num-new-swimmers number-of-swimmers - current-swimmers
    create-turtles num-new-swimmers [
      ; Initialize turtle properties
      set size 1
      set shape "circle"
      set next-move-x 0
      set next-move-y 0
      set target 0
      set number-tours 0
      let turtle-id who

      let speed-gumbell sample-from-gumbel
      set top-speed round (100 / speed-gumbell)

      set time-lane 1
      set time-lane-plot 0
      set time-save 0
      set previous-target false
    ]

      let numb-lanes (number-lanes-pool-1 + number-lanes-pool-2)
      print numb-lanes

      foreach sort-on [top-speed] turtles
      [ the-turtle -> ask the-turtle [
      type("turtle ") type who type(" :") type(100 / top-speed) print(" ")

      set index-speed i-speed
      set color rgb (7000 / top-speed) 0 0

      if allocation = "random" [
        let random-patch one-of available-patches with [pycor > 0 and pycor <= numb-lanes * 4]
        setxy [pxcor] of random-patch [pycor] of random-patch
        set ybottom 1 + (floor (ycor / 4) )* 4

        ifelse ybottom > number-lanes-pool-1 * 4 [
          set simulation-length round (item 1 lanes-length / 2)
        ] [
          set simulation-length round (item 0 lanes-length / 2)
        ]
      ]

      if allocation = "logic" [
        let swimmers-per-lane ceiling (count turtles / numb-lanes)

        let lane (1 + floor (index-speed / swimmers-per-lane))

        let random-patch one-of available-patches with [pycor > 0 + (lane - 1) * 4 and pycor <= lane * 4]

        setxy [pxcor] of random-patch [pycor] of random-patch
        set ybottom 1 + (floor (ycor / 4) )* 4
        ifelse ybottom > number-lanes-pool-1 * 4 [
          set simulation-length round (item 1 lanes-length / 2)
        ] [
          set simulation-length round (item 0 lanes-length / 2)
        ]
      ]

      set i-speed i-speed + 1

      ]
    ]

    if allocation = "clustering" [
      let k-clusters numb-lanes

      set centroids []

      let step (count turtles) / (k-clusters)
      let index 0

      while [length centroids < k-clusters] [
        let centroid-value 0
        ask turtles with [index-speed = index * step] [
          set centroid-value (100 / top-speed)
        ]
        set centroids lput centroid-value centroids
        set index index + 1
      ]

      print centroids

      ask turtles [
        let closest-centroids []
        let final-index 0

        while [length closest-centroids < k-clusters] [
          let index-clos length closest-centroids
          set closest-centroids lput abs ((item index-clos centroids) - (100 / top-speed)) closest-centroids

          let value-final min closest-centroids

          if value-final = item index-clos closest-centroids [
            set final-index index-clos + 1
          ]
        ]

        let random-patch one-of available-patches with [pycor > 0 + (final-index - 1) * 4 and pycor <= final-index * 4]

        setxy [pxcor] of random-patch [pycor] of random-patch
        set ybottom 1 + (floor (ycor / 4) )* 4
        ifelse ybottom > number-lanes-pool-1 * 4 [
          set simulation-length round (item 1 lanes-length / 2)
        ] [
          set simulation-length round (item 0 lanes-length / 2)
        ]

      ]
    ]

  ]

  ; Remove excess turtles if current count is greater than desired
  if current-swimmers > number-of-swimmers [
    let num-remove current-swimmers - number-of-swimmers
    ask n-of num-remove turtles [
      die
    ]
  ]
end



to setup-grid
  ask patches [
    ifelse (pxcor + pycor) mod 2 = 0 [
      set pcolor blue  ;; Set light blue color for every other patch
    ] [
      set pcolor (rgb 0 0 127) ;; Set dark blue color for the rest
    ]

    set pools list number-lanes-pool-1 number-lanes-pool-2
    set lanes-length list length-of-pool-1 length-of-pool-2

    let number-pools length pools
    let pycor-pre 0

    let i 0

    while [i < number-pools] [

    if pycor = pycor-pre or pycor mod 4 = 0 or pxcor = 0 or (pxcor > round ((item i lanes-length) / 2) and pycor <= pycor-pre + (item i pools) * 4 and pycor >= pycor-pre) [
      set pcolor (rgb 0 0 0) ;; Set black
    ]
      set pycor-pre pycor-pre + 4 * (item i pools)
      set i i + 1
    ]
    if pycor > pycor-pre [ set pcolor (rgb 0 0 0)]
  ]
end

to go
  ; Create or remove swimmers based on current conditions
  create-or-remove-swimmers

  ; Adjust swimmer view range
  set range-swimmer-view range-swimmer-vision-real / 2

  ; Move turtles based on their speed
  ask turtles [
    if ticks mod top-speed = 0 [
      swim
    ]
  ]

  if ticks mod 50 = 0 [
    set secondes secondes + 1
    if secondes mod 60 = 0 [
      set minutes minutes + 1
    ]
    record-collisions
  ]

  ; Calculate average delay per tour if any tours have been completed
  if sum [number-tours] of turtles != 0 [
    set delay-average delay-total / sum [number-tours] of turtles
  ]

  ; Stop simulation if specified duration is reached
  if secondes >= (simulation-duree * 60 * 60) [
    stop
  ]


  tick
end


to swim
  set next-move-x 0
  set next-move-y 0
  set previous-target target

  if ycor = ybottom + 2 [  ; At the top row
    set target 0
    set next-move-x 1
    ifelse xcor < ( simulation-length - 1 ) [   ; At the top row, move left when reaching the end
    ][
      if xcor = ( simulation-length - 1 ) and not any? turtles-on patch-at 0 -1 [
        set next-move-y -1
      ]
      if xcor = simulation-length [
        set next-move-y -1
        set next-move-x -1
        set target 1
      ]
    ]
    ]

  if ycor = ybottom + 1 [
      if xcor = simulation-length [  ; At the middle row, move left when reaching the end
      set next-move-y -1
      set next-move-x -1
      ]
      if xcor = 1 [  ; At the middle row, move right when reaching the beginning
      set next-move-y 1
      set next-move-x 1
      ]

    if target = 0 [                      ;overtake1
    if xcor < ( simulation-length - 1 ) [
        let turtle-front turtles-on patch-at 1 0
        ifelse not any? turtles-on patch-at 0 1 or ([target] of turtle-front != target and any? turtle-front ) [
          set next-move-x 1
          set next-move-y 1
        ] [
          set next-move-x 1
          set next-move-y 0
        ]
      ]
      if xcor = ( simulation-length - 1 )[
      set next-move-x 1
      set next-move-y 0
      ]
    ]
    if target = 1 [                      ;overtake2
      if xcor > 2 [
        let turtle-front turtles-on patch-at -1 0
        ifelse not any? turtles-on patch-at 0 -1 or ([ target ] of turtle-front != target and any? turtle-front  )[
          set next-move-x -1
          set next-move-y -1
        ] [
          set next-move-x -1
          set next-move-y 0
        ]
     ]
      if xcor = 2[
      set next-move-x -1
      set next-move-y  0
      ]
    ]
  ]

  if ycor = ybottom [
    set target 1
    set next-move-x -1
    ifelse xcor > 2 [  ; At the bottom row, move right when reaching the beginning
    ][
      if xcor = 2 and not any? turtles-on patch-at 0 1 [
        set next-move-y 1
      ]
      if xcor = 1 [
        set next-move-y 1
        set next-move-x 1
        set target 0
      ]
     ]

  ]

  if any? turtles-on patch-at next-move-x next-move-y [
    let my-xcor xcor
    let my-ycor ycor
    let my-ybottom ybottom

    let turtles-on-patch turtles-on patch-at next-move-x next-move-y
    let max-speed-of-others max [top-speed] of turtles-on-patch


    ifelse max-speed-of-others > top-speed  [
    if target = 0 [ ; right direction
        ifelse xcor < ( simulation-length - 2 ) [
      ifelse ycor <= ybottom + 1 [   ; on midle lane
            if ycor = ybottom + 1 [
        set next-move-y 0
        set next-move-x 1
            ]
      ] [                 ; on top lane
          let turtles-in-midle turtles-on patches with [pycor = my-ybottom + 1 and pxcor >= my-xcor and pxcor <= my-xcor + range-swimmer-view ]

          ifelse any? turtles-in-midle [
            ifelse [ target ] of turtles-in-midle != target [
              set next-move-x 0
              set next-move-y 0
          ][
            set next-move-y -1
            set next-move-x 1
          ]
          ] [
            set next-move-y -1
            set next-move-x 1
          ]
      ]
        ][
          ifelse xcor = simulation-length [
        set next-move-x 0
        set next-move-y 0
          ] [
        set next-move-x 1
        set next-move-y 0
          ]
        ]
    ]
    if target = 1 [      ; left direction
       ifelse xcor > 3 [
      ifelse ycor >= ybottom + 1 [  ; on midle lane
            if ycor = ybottom + 1 [
        set next-move-y 0
        set next-move-x -1
            ]
      ] [                ; on bottom lane
          let turtles-in-midle turtles-on patches with [pycor = my-ybottom + 1 and pxcor >= my-xcor and pxcor <= my-xcor - range-swimmer-view ]

          ifelse any? turtles-in-midle [
            ifelse [ target ] of turtles-in-midle != target [
              set next-move-x 0
              set next-move-y 0
          ][
            set next-move-y 1
            set next-move-x -1
          ]
          ][
            set next-move-y 1
            set next-move-x -1
          ]
      ]
        ][
          ifelse xcor = 1 [
        set next-move-x 0
        set next-move-y 0
          ][
        set next-move-x -1
        set next-move-y 0
          ]
        ]
    ]
    ] [
      set next-move-x 0
      set next-move-y 0
    ]
]
  ifelse not any? turtles-on patch-at next-move-x next-move-y [
    let ycor-previous ycor

    set xcor xcor + next-move-x
    set ycor ycor + next-move-y

    set collision-flag false

    if ycor = ybottom + 1 and ycor-previous != ycor and xcor > 2 and xcor < simulation-length - 2 [
      set number-overtakes number-overtakes + 1
    ]
  ] [
    if ycor = ybottom + 1 and max [ target ] of turtles-on patch-at next-move-x next-move-y != target and collision-flag = false and one-of [collision-flag] of turtles-on patch-at next-move-x next-move-y = false[
    set collision-midle-lane collision-midle-lane + 1
    set collision-flag true
    ]
  ]

  if previous-target != target [
      set time-lane (secondes - time-save) - ((simulation-length * 2) / (100 / top-speed))
    ifelse time-lane < 0 [
    ] [
      set time-lane-plot time-lane-plot + time-lane
      set delay-total (delay-total + time-lane)
    ]
      set number-tours number-tours + 1
      set time-save secondes
  ]

end

to record-collisions
  ; Record current mid-lane collisions and update counters
  set collisions-over-time collision-midle-lane
  set number-of-collisons number-of-collisons + collisions-over-time
  set collision-midle-lane 0
end


to-report sample-from-gumbel
  ; Sample from Gumbel distribution based on configuration
  let mu 0
  let beta 0

  let index 0
  if swimming-style = "back" [
    set index 0
  ]
  if swimming-style = "breast" [
    set index 1
  ]
  if swimming-style = "fly" [
    set index 2
  ]
  if swimming-style = "free" [
    set index 3
  ]
  if swimming-style = "IM" [
    set index 4
  ]

  ifelse gender = "male" [
    let mu_list [0.9472 0.9491 1.1808 1.2098 1.0893] ; [Back Breast Fly Free IM]
    let beta_list [0.2085 0.1710 0.2027 0.2247 0.1748]
    set mu item index mu_list
    set beta item index beta_list
  ] [
    let mu_list [0.8575 0.8970 1.0149 1.0556 0.9886]
    let beta_list [0.1709 0.1310 0.1483 0.1841 0.1347]
    set mu item index mu_list
    set beta item index beta_list
  ]

  let x random-exponential 1
  let y mu - beta * log x 2
  report y
end
@#$#@#$#@
GRAPHICS-WINDOW
848
10
1396
839
-1
-1
20.0
1
20
1
1
1
0
1
1
1
0
26
0
40
0
0
1
ticks
30.0

BUTTON
89
57
162
90
NIL
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
182
57
245
90
NIL
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

SLIDER
86
104
323
137
number-of-swimmers
number-of-swimmers
1
50
30.0
1
1
NIL
HORIZONTAL

SLIDER
86
143
320
176
range-swimmer-vision-real
range-swimmer-vision-real
0
20
15.0
5
1
NIL
HORIZONTAL

MONITOR
229
449
406
494
number-of-collisons-total
number-of-collisons
17
1
11

SLIDER
84
392
308
425
simulation-duree
simulation-duree
1
5
1.0
1
1
hours
HORIZONTAL

MONITOR
425
450
703
495
sum of delay of all swimmer (secondes)
delay-total
0
1
11

SLIDER
85
346
285
379
number-lanes-pool-1
number-lanes-pool-1
1
5
5.0
1
1
NIL
HORIZONTAL

SLIDER
84
304
285
337
number-lanes-pool-2
number-lanes-pool-2
0
5
0.0
1
1
NIL
HORIZONTAL

SLIDER
301
345
473
378
length-of-pool-1
length-of-pool-1
25
50
50.0
25
1
NIL
HORIZONTAL

SLIDER
302
303
474
336
length-of-pool-2
length-of-pool-2
25
50
25.0
25
1
NIL
HORIZONTAL

MONITOR
81
449
214
494
NIL
number-overtakes
17
1
11

CHOOSER
85
240
223
285
allocation
allocation
"random" "logic" "clustering"
2

CHOOSER
236
188
374
233
gender
gender
"male" "female"
0

CHOOSER
84
187
222
232
swimming-style
swimming-style
"back" "breast" "fly" "free" "IM"
0

PLOT
75
513
703
823
Density of Gumbel Distribution
10 * speed
swimmers
0.0
30.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram [(100 / top-speed) * 10] of turtles"
"pen-1" 1.0 2 -14454117 true "" "if allocation = \"clustering\" [\nlet index 0\nwhile [index < length centroids] [\n    plotxy 10 * (item index centroids) 1\n    set index index + 1\n    \n    ]\n]"

MONITOR
323
388
432
433
time (minutes)
minutes
17
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
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <metric>delay-total</metric>
    <metric>number-of-collisons</metric>
    <enumeratedValueSet variable="Swimming-Style">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-swimmers">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range-swimmer-vision-real">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Men">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
