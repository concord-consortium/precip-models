breed [ stations station ]
breed [ vector-heads vector-head ]

breed [ raindrops raindrop ]
breed [ airs air ]
breed [ selection-circles selection-circle ]

patches-own [
  pwind-x
  pwind-y
]

globals [
  last-trails?
  last-interpolation-method
  interpolation-fn
  vector-scale

  nearby-points

  station-wind-speed
  station-wind-direction

  visible-stations

  mouse-was-down? ; for station selection
]

stations-own [
  wind-x
  wind-y

  temps
  moistures

  init-moisture
  init-temp
]

airs-own [
  vapor-pressure
  temp

  birth-tick

  convergence
  last-density
]

to setup
  ca
  update-interp
  ask patches [ set pcolor brown + 4 ]


  set vector-scale 5


  set-default-shape stations "house"
  set-default-shape selection-circles "selection-circle"
  setup-stations-from-data init-data

  create-airs 0 [
    setxy random-xcor random-ycor
    set vapor-pressure (runresult interpolation-fn stations [-> init-moisture])
    set temp (runresult interpolation-fn stations [-> init-temp])
    update-visual
    set heading atan vel-x vel-y
  ]
  ask stations [ update-measurements ]
  set visible-stations stations

  set nearby-points [ [ list (pxcor - 5) (pycor - 5) ] of patches in-radius 2 ] of patch 5 5
  reset-drawing
  reset-ticks
end

to reset-drawing
  cd
  import-drawing "ak-base-map.png"
end

to setup-stations-from-data [ data ]
  foreach data [ row ->
    create-stations 1 [
      set color (item (count stations mod length base-colors) base-colors)
      let lat item 0 row
      let lon item 1 row
      setxy (lon-to-xcor lon lat) (lat-to-ycor lat)
      let wind-speed item 2 row
      let wind-dir item 3 row
      let wx wind-speed * sin (wind-dir + 180)
      let wy wind-speed * cos (wind-dir + 180)
      set wind-x km-to-dist wx
      set wind-y km-to-dist wy
      set temps []
      set moistures []
      set init-temp item 4 row
      set init-moisture sat-vapor-pressure item 5 row
      make-vector
      update-vector
    ]
  ]
  update-patch-interp
end

to go
  update-interp

  add-new-airs

  ask airs [
    move
    update-convergence
    rain
    update-visual
  ]

  ask raindrops [
    set size size - 0.2 * size * timestep
    if size <= 0.1 [ die ]
  ]

  ifelse trails? [
    ask airs [ pd ]
  ] [
    if trails? != last-trails? [
      ask airs [ pu ]
      if is-air? subject [ ask subject [ pd ] ]
      reset-drawing
    ]
  ]
  set last-trails? trails?

  tick-advance timestep
  safe-display
  if floor ticks > floor (ticks - timestep) [
    ask stations [ update-measurements ]
    update-plots
  ]
end

to edit-stations
  ifelse mouse-down? [
    if is-station? subject [
      ask subject [
        setxy mouse-xcor mouse-ycor
        update-vector
      ]
    ]
    if is-vector-head? subject [
      ask subject [
        ask link-neighbors [
          set wind-x (mouse-xcor - xcor) / vector-scale
          set wind-y (mouse-ycor - ycor) / vector-scale
          let wx wind-x
          let wy wind-y
          update-vector
          set station-wind-speed dist-to-km ((distance one-of link-neighbors) / vector-scale)
          if station-wind-speed > 0 [
            set station-wind-direction (270 - towards one-of link-neighbors) mod 360
          ]
        ]
      ]
    ]
    if subject = nobody or is-air? subject [

      let possible-subject min-one-of (turtle-set stations vector-heads) [ distancexy mouse-xcor mouse-ycor ]

      ifelse is-turtle? possible-subject and [ distancexy mouse-xcor mouse-ycor < 1 ] of possible-subject [
        ask possible-subject [ watch-me ]
      ] [
        create-stations 1 [
          set color (item (count stations mod length base-colors) base-colors)
          setxy mouse-xcor mouse-ycor
          set temps []
          set moistures []
          make-vector
          ask link-neighbors [ watch-me ]
        ]
      ]
    ]

    update-patch-interp
    safe-display
  ] [
    if is-station? subject or is-vector-head? subject [
      reset-perspective
      safe-display
    ]
  ]
end

to delete-station
  ifelse mouse-down? and mouse-inside? [
    let possible-subject min-one-of stations with [ distancexy mouse-xcor mouse-ycor < 1 ] [ distancexy mouse-xcor mouse-ycor ]
    ifelse is-station? possible-subject [
      watch possible-subject
    ] [
      reset-perspective
    ]
  ] [
    if mouse-inside? and is-station? subject [
      ask subject [
        ask link-neighbors [ die ]
        die
      ]
      update-patch-interp
    ]
  ]
  safe-display
end

to safe-display
  if not netlogo-web? [ display ]
end

to make-vector
  hatch-vector-heads 1 [
    create-link-from myself
    set color grey
  ]
end

to update-vector
  let wx wind-x
  let wy wind-y
  ask link-neighbors [
    move-to myself
    if wx != 0 or wx != 0 [
      set heading atan wx wy
    ]
    fd vector-scale * sqrt ((wx * wx) + (wy * wy))
  ]
end

; from google maps api
; eg https://maps.googleapis.com/maps/api/staticmap?center=42,-91.5&zoom=6&format=png&size=500x500&maptype=roadmap&style=feature:road|visibility:off

to-report image-dim
  report 500
end

to-report center-lat
  report 42
end

to-report center-lon
  report -91.5
end

to-report zoom-level
  report 6
end

to-report image-px-to-km
  ; from https://gis.stackexchange.com/a/127949
  report 156.54303392 * (cos center-lat) / (2 ^ zoom-level)
end

to-report km-to-dist [ km ]
  report (km / image-px-to-km) * world-width / image-dim
end

to-report dist-to-km [ d ]
  report image-px-to-km * d * image-dim / world-width
end

to-report km-to-lat [ y ]
  report y / 110.574
end

to-report km-to-lon [ x la ]
  report x / (111.320 * cos la)
end

to-report lat-to-km [ la ]
  report 110.574 * la
end

to-report lon-to-km [ lo la ]
  report lo * 111.320 * cos la
end

to-report xcor-to-lon [ x lat ]
  report km-to-lon dist-to-km (x - (max-pxcor + min-pxcor) / 2) lat + center-lon
end

to-report ycor-to-lat [ y ]
  report km-to-lat dist-to-km (y - (max-pycor + min-pycor) / 2) + center-lat
end

to-report lon-to-xcor [ lon lat ]
  report (km-to-dist lon-to-km (lon - center-lon) lat) + (max-pxcor + min-pxcor) / 2
end

to-report lat-to-ycor [ lat ]
  report (km-to-dist lat-to-km (lat - center-lat)) + (max-pycor + min-pycor) / 2
end

to-report mr-to-vp [ mr ]
  report mr / 0.62
end

to-report vp-to-mr [ vp ]
  report 0.62 * vp
end

to update-interp
  if interpolation-method != last-interpolation-method [
    ifelse interpolation-method = "nearest-neighbor" [
      set interpolation-fn [ [agents rep] -> nearest-neighbors agents rep ]
    ] [
      set interpolation-fn [ [agents rep] -> interpolate-idw agents rep ]
    ]
    update-patch-interp
    set last-interpolation-method interpolation-method
  ]
end

to update-patch-interp
  ask patches [
    set pwind-x (runresult interpolation-fn stations [-> wind-x])
    set pwind-y (runresult interpolation-fn stations [-> wind-y])
  ]
end

to add-new-airs
  ; West
  ask patches with [ pxcor = min-pxcor and pycor != max-pycor and pycor != min-pycor ] [
    make-airs W-incoming-temp W-incoming-moisture -0.49 (0.5 - random-float 1)
  ]
  ; East
  ask patches with [ pxcor = max-pxcor and pycor != max-pycor and pycor != min-pycor ] [
    make-airs E-incoming-temp E-incoming-moisture 0.49 (0.5 - random-float 1)
  ]
  ; North
  ask patches with [ pycor = max-pycor and pxcor != max-pxcor and pxcor != min-pxcor ] [
    make-airs N-incoming-temp N-incoming-moisture (0.5 - random-float 1) 0.49
  ]
  ; South
  ask patches with [ pycor = min-pycor and pxcor != max-pxcor and pxcor != min-pxcor ] [
    make-airs S-incoming-temp S-incoming-moisture (0.5 - random-float 1) -0.49
  ]
  ; NW
  ask patch min-pxcor max-pycor [
    let t (W-incoming-temp + N-incoming-temp) / 2
    let m (W-incoming-moisture + N-incoming-moisture) / 2
    let x -0.49
    let y (0.5 - random-float 1)
    if one-of [ true false ] [
      set x y
      set y 0.49
    ]
    make-airs t m x y
  ]
  ; NE
  ask patch max-pxcor max-pycor [
    let t (E-incoming-temp + N-incoming-temp) / 2
    let m (E-incoming-moisture + N-incoming-moisture) / 2
    let x 0.49
    let y (0.5 - random-float 1)
    if one-of [ true false ] [
      set x y
      set y 0.49
    ]
    make-airs t m x y
  ]
  ; SE
  ask patch max-pxcor min-pycor [
    let t (E-incoming-temp + S-incoming-temp) / 2
    let m (E-incoming-moisture + S-incoming-moisture) / 2
    let x 0.49
    let y (0.5 - random-float 1)
    if one-of [ true false ] [
      set x y
      set y -0.49
    ]
    make-airs t m x y
  ]
  ; SW
  ask patch min-pxcor min-pycor [
    let t (W-incoming-temp + S-incoming-temp) / 2
    let m (W-incoming-moisture + S-incoming-moisture) / 2
    let x -0.49
    let y (0.5 - random-float 1)
    if one-of [ true false ] [
      set x y
      set y -0.49
    ]
    make-airs t m x y
  ]
  ask airs with [ last-density = 0 ] [ set last-density density ]
end

to make-airs [ incoming-temp incoming-moisture x-mod y-mod ]
  sprout-airs random-poisson (timestep * new-air-rate)  [
    set temp random-normal incoming-temp 2
    set vapor-pressure mr-to-vp random-normal incoming-moisture 2
    if vapor-pressure < 0 [ set vapor-pressure 0 ]
    set xcor pxcor + x-mod
    set ycor pycor + y-mod
    set birth-tick ticks
    update-visual
  ]
end

to-report new-air-rate
  report interpolate stations [-> sqrt (wind-x * wind-x + wind-y * wind-y)] / 5
end

to follow-air
  if mouse-down? and mouse-inside? [
    let new-subject min-one-of airs [ distancexy mouse-xcor mouse-ycor ]
    if new-subject != subject [
      reset-drawing
      ask airs [ pu ]
      ask new-subject [
        watch-me
        pd
      ]
    ]
  ]
end

to view-station-data
  if mouse-down? or not is-boolean? mouse-was-down? [
    set mouse-was-down? mouse-down?
  ]
  if not mouse-down? and mouse-was-down? [
    let target min-one-of stations with [ distancexy mouse-xcor mouse-ycor < 1 ] [ distancexy mouse-xcor mouse-ycor ]
    ifelse is-station? target [
      ; Want to see if it is actually the breed set and rather than a normal agentset of all stations
      if (word visible-stations) = (word stations) [ set visible-stations no-turtles ]
      ifelse member? target visible-stations [
        set-visible-stations visible-stations with [ self != target ]
      ] [
        set-visible-stations (turtle-set visible-stations target)
      ]
    ] [
      set-visible-stations stations
    ]
    set mouse-was-down? false
  ]
end

to set-visible-stations [ new-visible-stations ]
  if not any? new-visible-stations [ set new-visible-stations stations ]
  if (word visible-stations) != (word new-visible-stations) [
    ask selection-circles [ die ]
    set visible-stations new-visible-stations
    set-current-plot "Temperature"
    let temp-y-max plot-y-max
    let temp-y-min plot-y-min
    set-current-plot "Moisture"
    let moist-y plot-y-max

    clear-all-plots
    set-current-plot "Temperature"
    set-plot-y-range temp-y-min temp-y-max
    set-current-plot "Moisture"
    set-plot-y-range 0 moist-y ; Moisture plot always has min y of 0
    ask visible-stations [
      (foreach range (1 + floor ticks) temps moistures [ [x t m] ->
        set-current-plot "Temperature"
        plot-value "temp" x t
        set-current-plot "Moisture"
        plot-value "moisture" x m
      ])
      if (word visible-stations) != (word stations) [
        hatch-selection-circles 1 [
          set color black + 3
          set size 1.5
          ;__set-line-thickness 0.1
        ]
      ]
    ]
    update-plots
    safe-display
  ]
end

to reset-view
  reset-perspective
  ask turtles [ pu ]
  reset-drawing
end

to update-convergence
  let rate timestep * 0.05
  let d density
  set convergence (1 - rate) * convergence + rate * (d - last-density)
  set last-density d
end

to-report density
  ;let nearby airs at-points nearby-points ;(turtle-set airs-here airs-on neighbors)
  ;let r 2
  ;report sum [ 1 - (distance myself) / r  ] of other nearby
;  let r 2.9
;  let nearby (turtle-set other airs-here airs-on neighbors)
;  report sum [ 1 - (distance myself) / r ] of other nearby
  report sum [ count airs-here ] of neighbors / 2 + count airs-here
end

to update-visual
  let mt 50
  let t temp
  if t > mt [ set t mt ]
  if t < 0 [ set t 0 ]

  set color (list (255 * (t / mt)) 0 (255 * (1 - t / mt)))
  let m vapor-pressure
  if m < 0 [ set m 0 ]
  set size 0.1 + sqrt (m / 20)
end

to-report interpolate [ agents reporter ]
  report (runresult interpolation-fn agents reporter)
end

to-report nearest-neighbors [ agents reporter ]
  if not any? agents [ report 0 ]
  report [ runresult reporter ] of min-one-of agents [ distance myself ]
end

to-report sat-vapor-pressure [ t ]
  report 6.11 * 10 ^ (7.5 * t / (237.3 + t))
end

to-report dew-point [ vp ]
  report 238.88 * ln (vp / 6.1121) / (17.368 - ln (vp / 6.1121))
end

to-report vel-x
  report interpolate stations [-> wind-x]
end

to-report vel-y
  report interpolate stations [-> wind-y]
end

to-report init-data
  report [
    [45.7 -92.4 10 330 -3 -9] ;utqiagvik
    [44.6 -94.4 10 300 -5.6 -13.3] ;point lay
    [42.8 -93.8 10 320 5.6 -2.8] ;noorvik
    [42.9 -90.7 10 330 -7.8 -12.2] ;bettles
    [41.6 -95.1 10 325 -0.6 -8.9] ;nome
    [41.7 -92.4 10 290 2.2 -8.9] ;galena
    [41.7 -89.7 10 218 -0.6 -8.9] ;fairbanks
    [40.4 -94.3 10 290 -0.6 -8.9] ;st mary
    [39.7 -93.8 10 240 -0.6 -8.9] ;bethel
    [38.8 -93.9 10 195 -0.6 -8.9] ;cape newenham



  ]
end

to-report safe-mean [ nums ]
  report ifelse-value empty? nums [ 0 ] [ mean nums ]
end

to plot-value [ name x val ]
  let pen-name (word name "-" who)
  if not plot-pen-exists? pen-name [
    create-temporary-plot-pen pen-name
    set-plot-pen-color color
  ]
  set-current-plot-pen pen-name
  plotxy x val
end

to update-measurements
  let nearby airs in-radius 3
  ifelse any? nearby [
    set temps lput mean [ temp ] of nearby temps
    set moistures lput vp-to-mr mean [ vapor-pressure ] of nearby moistures
  ] [
    ifelse empty? temps or empty? moistures [
      set temps [0]
      set moistures [0]
    ] [
      set temps lput last temps temps
      set moistures lput last moistures moistures
    ]
  ]
end

to move
  let last-x xcor
  let last-y ycor
  let vx pwind-x;vel-x
  let vy pwind-y;vel-y
  set heading atan vx vy
  fd timestep * sqrt (vx ^ 2 + vy ^ 2)
  if xcor = last-x and ycor = last-y [
    die
  ]
end

to-report interpolate-idw [ agents reporter ]
  if not any? agents [
    report 0
  ]
  let on-top agents with [ distance myself = 0 ]
  ifelse any? on-top [
    report [ runresult reporter ] of one-of on-top
  ] [
    report sum [ runresult reporter / ((distance myself) ^ 2) ] of agents / sum [ 1 / ((distance myself) ^ 2) ] of agents
  ]
end

to rain
  ; T > 23ºC: (bouyancy)
  ; temp - 8: a dewpoint of greater than `temp - 8` means that h_lcl < 1000m. From `h_lcl ~= 125 * (temp - dew-point)`
  ; convergence > 0: airs are coming together
  let temp-at-1km temp - 8
  if vapor-pressure > sat-vapor-pressure temp-at-1km and convergence > 0 and temp > 15 and not on-border? [
    let amount timestep * convergence * (vapor-pressure - (sat-vapor-pressure temp-at-1km))
    set vapor-pressure vapor-pressure - amount
    if not any? raindrops-here [
      ask patch-here [
        sprout-raindrops 1 [
          set size 0
          set shape "circle"
          set color [0 128 0 128]
        ]
      ]
    ]
    ask raindrops-here [
      set size size + sqrt amount
    ]
  ]
end

to-report on-border?
  report pxcor = max-pxcor or pxcor = min-pxcor or pycor = max-pycor or pycor = min-pycor
end
@#$#@#$#@
GRAPHICS-WINDOW
370
80
794
505
-1
-1
13.0
1
10
1
1
1
0
0
0
1
0
31
0
31
1
1
1
hours
30.0

BUTTON
5
10
98
43
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
11
419
74
452
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
0

SWITCH
7
262
102
295
trails?
trails?
0
1
-1000

BUTTON
7
297
119
330
NIL
follow-air
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
122
297
212
330
NIL
reset-view
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
370
10
795
43
N-incoming-temp
N-incoming-temp
-20
30
2.0
1
1
ºC
HORIZONTAL

SLIDER
370
45
795
78
N-incoming-moisture
N-incoming-moisture
0
10
6.0
1
1
NIL
HORIZONTAL

SLIDER
300
80
333
505
W-incoming-temp
W-incoming-temp
-20
30
2.0
1
1
ºC
VERTICAL

SLIDER
335
80
368
505
W-incoming-moisture
W-incoming-moisture
0
10
6.0
1
1
NIL
VERTICAL

SLIDER
370
505
795
538
S-incoming-temp
S-incoming-temp
-20
30
16.0
1
1
ºC
HORIZONTAL

SLIDER
370
540
795
573
S-incoming-moisture
S-incoming-moisture
1
10
9.0
1
1
NIL
HORIZONTAL

SLIDER
795
80
828
505
E-incoming-temp
E-incoming-temp
-20
30
4.0
1
1
ºC
VERTICAL

SLIDER
830
80
863
505
E-incoming-moisture
E-incoming-moisture
0
10
2.0
1
1
NIL
VERTICAL

CHOOSER
5
167
240
212
interpolation-method
interpolation-method
"nearest-neighbor" "weighted-average"
1

MONITOR
71
84
143
129
longitude
xcor-to-lon mouse-xcor ycor-to-lat mouse-ycor + 17
1
1
11

MONITOR
7
83
64
128
latitude
ycor-to-lat mouse-ycor
1
1
11

TEXTBOX
7
59
157
97
Under mouse:
16
0.0
1

TEXTBOX
7
147
157
167
Data:
16
0.0
1

TEXTBOX
7
242
157
262
Visualization:
16
0.0
1

INPUTBOX
85
408
190
468
timestep
0.5
1
0
Number

TEXTBOX
9
372
159
392
Run Model:
16
0.0
1

@#$#@#$#@
Map generated with https://maps.googleapis.com/maps/api/staticmap?center=42,-91.5&zoom=6&format=png&sensor=false&size=416x416&maptype=roadmap&style=feature:road|visibility:off

https://maps.googleapis.com/maps/api/staticmap?center=42,-91.5&zoom=6&format=png&size=500x500&maptype=roadmap&style=feature:road|visibility:off

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

cloud
false
0
Circle -7500403 true true 13 118 94
Circle -7500403 true true 86 101 127
Circle -7500403 true true 51 51 108
Circle -7500403 true true 118 43 95
Circle -7500403 true true 158 68 134

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

selection-circle
true
0
Circle -7500403 false true 0 0 300

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
NetLogo 6.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
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
@#$#@#$#@
0
@#$#@#$#@
