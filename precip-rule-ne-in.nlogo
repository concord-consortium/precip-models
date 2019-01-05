;;  Precipitation Rule Model (Lesson 3), v. 3
;;  Precipitating Change Project
;;  jdomyancich (design) and nkimball (implementation)
;;  December 2018

globals
[
  is-NE?                       ;set true, map and data of NE is loaded; set false, AK data and map loaded
  x-grid-count                 ;horizontal number of grid squares
  y-grid-count                 ;vertical number of squares
  grid-size                    ;number of patches per square
  nearest-neighbor-data        ;holds the active nearest neighbor data set, established on setup
  linear-data                  ;holds the active linear data set
  weighted-average-data        ;holds the active weighted average data set
  nearest-neighbor-data-NE     ;data used when is-NE? set true
  linear-data-NE
  weighted-average-data-NE
  nearest-neighbor-data-AK     ;data used when is-NE? set false
  linear-data-AK
  weighted-average-data-AK
  interpolation-dataset        ;holds pointer to the presently set dataset
  test-square-list             ;holds list of grid square numbers that have a NW square
  max-temp-slider              ;depends on C or F
  presently-set-temp-unit      ;C or F
]

to startup
  set-constant-globals
  reset-drawing               ;workaround: in netlogo web, import-drawing is asynchronous, so we need to seperate loading the map from drawing the grid
  ;setup
end

to set-constant-globals
  set is-NE? true
  set x-grid-count 7
  set y-grid-count 7
  set grid-size 10            ;number of patchs of width and height of a grid square
  ; stored interpolation data for NE, list of lists, for each grid square the [lat, lon, F temp, C temp, Air Moisture]
  set test-square-list [1 2 3 4 5 6 8 9 10 11 12 13 15 16 17 18 19 20 22 23 24 25 26 27 29 30 31 32 33 34 36 37 38 39 40 41]
  set nearest-neighbor-data-NE [[40 -77 63 17.2 9] [40 -76 63 17.2 9] [40 -75 63 17.2 9] [40 -74 63 17.2 9] [40 -73 63 17.2 9] [40 -72 63 17.2 9] [40 -71 63 17.2 9] [41 -77 46 7.8 5] [41 -76 46 7.8 5] [41 -75 54 12.2 7] [41 -74 63 17.2 9] [41 -73 63 17.2 9] [41 -72 63 17.2 9] [41 -71 62 16.7 9] [42 -77 46 7.8 5] [42 -76 46 7.8 5] [42 -75 48 8.9 5] [42 -74 54 12.2 7] [42 -73 54 12.2 7] [42 -72 62 16.7 9] [42 -71 62 16.7 9] [43 -77 46 7.8 5] [43 -76 46 7.8 5] [43 -75 48 8.9 5] [43 -74 54 12.2 7] [43 -73 54 12.2 7] [43 -72 62 16.7 9] [43 -71 62 16.7 9] [44 -77 46 7.8 5] [44 -76 46 7.8 5] [44 -75 48 8.9 5] [44 -74 48 8.9 5] [44 -73 54 12.2 7] [44 -72 62 16.7 9] [44 -71 62 16.7 9] [45 -77 46 7.8 5] [45 -76 46 7.8 5] [45 -75 48 8.9 5] [45 -74 48 8.9 5] [45 -73 48 8.9 5] [45 -72 62 16.7 9] [45 -71 62 16.7 9] [46 -77 46 7.8 5] [46 -76 46 7.8 5] [46 -75 48 8.9 5] [46 -74 48 8.9 5] [46 -73 48 8.9 5] [46 -72 62 16.7 9] [46 -71 62 16.7 9]]
  set linear-data-NE [[40 -77 57 13.9 8] [40 -76 57 13.9 9] [40 -75 59 15 9] [40 -74 63 17.2 9] [40 -73 66 18.9 10] [40 -72 64 17.8 10] [40 -71 68 20 10] [41 -77 53 11.7 7] [41 -76 54 12.2 8] [41 -75 57 13.9 8] [41 -74 59 15 8] [41 -73 62 16.7 9] [41 -72 63 17.2 9] [41 -71 64 17.8 10] [42 -77 49 9.4 6] [42 -76 51 10.6 6] [42 -75 53 11.7 7] [42 -74 54 12.2 7] [42 -73 58 14.4 8] [42 -72 62 16.7 9] [42 -71 66 18.9 10] [43 -77 44 6.7 5] [43 -76 46 7.8 5] [43 -75 48 8.9 5] [43 -74 53 11.7 6] [43 -73 56 13.3 7] [43 -72 61 16.1 8] [43 -71 62 16.7 9] [44 -77 39 3.9 3] [44 -76 42 5.6 3] [44 -75 47 8.3 5] [44 -74 50 10 6] [44 -73 54 12.2 6] [44 -72 57 13.9 7] [44 -71 60 15.6 8] [45 -77 38 3.3 3] [45 -76 42 5.6 4] [45 -75 46 7.8 5] [45 -74 48 8.9 5] [45 -73 50 10 6] [45 -72 52 11.1 6] [45 -71 54 12.2 7] [46 -77 37 2.8 3] [46 -76 44 6.7 4] [46 -75 45 7.2 4] [46 -74 46 7.8 4] [46 -73 46 7.8 5] [46 -72 47 8.3 5] [46 -71 50 10 6]]
  set weighted-average-data-NE [[40 -77 54 12.2 7] [40 -76 58 14.4 8] [40 -75 61 16.1 8] [40 -74 63 17.2 9] [40 -73 63 17.2 9] [40 -72 63 17.2 9] [40 -71 63 17.2 9] [41 -77 53 11.7 7] [41 -76 54 12.2 7] [41 -75 57 13.9 7] [41 -74 59 15 8] [41 -73 62 16.7 9] [41 -72 63 17.2 9] [41 -71 63 17.2 9] [42 -77 49 9.4 6] [42 -76 48 8.9 7] [42 -75 50 10 7] [42 -74 54 12.2 7] [42 -73 59 15 8] [42 -72 61 16.1 9] [42 -71 62 16.7 9] [43 -77 48 8.9 5] [43 -76 46 7.8 5] [43 -75 48 8.9 5] [43 -74 51 10.6 7] [43 -73 58 14.4 8] [43 -72 61 16.1 8] [43 -71 62 16.7 9] [44 -77 46 7.8 5] [44 -76 46 7.8 5] [44 -75 47 8.3 5] [44 -74 52 11.1 6] [44 -73 56 13.3 7] [44 -72 57 13.9 8] [44 -71 60 15.6 9] [45 -77 46 7.8 5] [45 -76 46 7.8 5] [45 -75 46 7.8 5] [45 -74 47 8.3 6] [45 -73 51 10.6 6] [45 -72 52 11.1 6] [45 -71 54 12.2 7] [46 -77 46 7.8 5] [46 -76 46 7.8 5] [46 -75 46 7.8 5] [46 -74 48 8.9 5] [46 -73 50 10 6] [46 -72 52 11.1 6] [46 -71 55 12.8 6]]
  ;; stored interpolation data for AK
  set nearest-neighbor-data-AK [[40 -77 56 13.3 7] [40 -76 56 13.3 7] [40 -75 56 13.3 7] [40 -74 56 13.3 7] [40 -73 56 13.3 7] [40 -72 58 14.4 8] [40 -71 58 14.4 8] [41 -77 56 13.3 7] [41 -76 56 13.3 7] [41 -75 56 13.3 7] [41 -74 56 13.3 7] [41 -73 58 14.4 8] [41 -72 58 14.4 8] [41 -71 58 14.4 8] [42 -77 46 7.8 5] [42 -76 46 7.8 5] [42 -75 56 13.3 7] [42 -74 56 13.3 7] [42 -73 58 14.4 8] [42 -72 58 14.4 8] [42 -71 58 14.4 8] [43 -77 46 7.8 5] [43 -76 46 7.8 5] [43 -75 46 7.8 5] [43 -74 58 14.4 8] [43 -73 58 14.4 8] [43 -72 58 14.4 8] [43 -71 52 11.1 6] [44 -77 46 7.8 5] [44 -76 46 7.8 5] [44 -75 46 7.8 5] [44 -74 58 14.4 8] [44 -73 58 14.4 8] [44 -72 52 11.1 6] [44 -71 52 11.1 6] [45 -77 46 7.8 5] [45 -76 46 7.8 5] [45 -75 46 7.8 5] [45 -74 46 7.8 5] [45 -73 52 11.1 6] [45 -72 52 11.1 6] [45 -71 52 11.1 6] [46 -77 46 7.8 5] [46 -76 46 7.8 5] [46 -75 46 7.8 5] [46 -74 46 7.8 5] [46 -73 52 11.1 6] [46 -72 52 11.1 6] [46 -71 52 11.1 6]]
  set linear-data-AK [[40 -77 51 10.6 7] [40 -76 55 12.8 8] [40 -75 59 15 8] [40 -74 63 17.2 9] [40 -73 64 17.8 9] [40 -72 66 18.9 10] [40 -71 69 20.6 10] [41 -77 48 8.9 5] [41 -76 52 11.1 6] [41 -75 56 13.3 7] [41 -74 60 15.6 9] [41 -73 64 17.8 9] [41 -72 65 18.3 10] [41 -71 67 19.4 10] [42 -77 45 7.2 5] [42 -76 49 9.4 6] [42 -75 53 11.7 7] [42 -74 57 13.9 8] [42 -73 61 16.1 9] [42 -72 63 17.2 10] [42 -71 65 18.3 10] [43 -77 42 5.6 4] [43 -76 46 7.8 5] [43 -75 50 10 6] [43 -74 54 12.2 7] [43 -73 58 14.4 8] [43 -72 61 16.1 9] [43 -71 63 17.2 9] [44 -77 40 4.4 5] [44 -76 44 6.7 5] [44 -75 48 8.9 6] [44 -74 51 10.6 6] [44 -73 54 12.2 7] [44 -72 57 13.9 7] [44 -71 60 15.6 8] [45 -77 38 3.3 4] [45 -76 42 5.6 5] [45 -75 46 7.8 5] [45 -74 48 8.9 5] [45 -73 50 10 6] [45 -72 52 11.1 6] [45 -71 54 12.2 6] [46 -77 36 2.2 4] [46 -76 41 5 4] [46 -75 44 6.7 4] [46 -74 45 7.2 5] [46 -73 46 7.8 5] [46 -72 47 8.3 5] [46 -71 48 8.9 5]]
  set weighted-average-data-AK  [[40 -77 53 11.7 7] [40 -76 56 13.3 8] [40 -75 58 14.4 8] [40 -74 60 15.6 8] [40 -73 64 17.8 9] [40 -72 65 18.3 10] [40 -71 67 19.4 10] [41 -77 51 10.6 7] [41 -76 53 11.7 7] [41 -75 55 12.8 7] [41 -74 59 15 8] [41 -73 63 17.2 9] [41 -72 65 18.3 10] [41 -71 67 19.4 10] [42 -77 48 8.9 6] [42 -76 50 10 6] [42 -75 54 12.2 7] [42 -74 59 15 8] [42 -73 61 16.1 9] [42 -72 63 17.2 9] [42 -71 66 18.9 10] [43 -77 45 7.2 5] [43 -76 46 7.8 5] [43 -75 48 8.9 6] [43 -74 55 12.8 7] [43 -73 58 14.4 8] [43 -72 58 14.4 8] [43 -71 61 16.1 9] [44 -77 44 6.7 5] [44 -76 45 7.2 5] [44 -75 47 8.3 6] [44 -74 51 10.6 7] [44 -73 53 11.7 7] [44 -72 54 12.2 7] [44 -71 57 13.9 8] [45 -77 43 6.1 4] [45 -76 45 7.2 5] [45 -75 46 7.8 5] [45 -74 48 8.9 6] [45 -73 52 11.1 6] [45 -72 52 11.1 6] [45 -71 52 11.1 6] [46 -77 43 6.1 4] [46 -76 45 7.2 5] [46 -75 46 7.8 5] [46 -74 49 9.4 6] [46 -73 52 11.1 6] [46 -72 52 11.1 6] [46 -71 52 11.1 6]]
  ifelse (is-NE?) [
    set nearest-neighbor-data nearest-neighbor-data-NE
    set linear-data linear-data-NE
    set weighted-average-data weighted-average-data-NE
  ]
  [
    set nearest-neighbor-data nearest-neighbor-data-AK
    set linear-data linear-data-AK
    set weighted-average-data weighted-average-data-AK
  ]
  set presently-set-temp-unit temperature-unit
  set max-temp-slider set-max-temp-slider
  set-interpolation-dataset
end

to setup
  ask turtles [die]      ;like ct to clear turtles but without erasing the drawing
  set-constant-globals
  draw-grid
end


to reset-drawing
  cd
  ifelse is-NE?
  [
    import-drawing "./ne-base-map.png"
  ]
  [ ;; else it's AK...
    import-drawing "./ak-base-map.png"
  ]
end


to draw-grid
  let xi min-pxcor
  let yi min-pycor
  let pencil 0          ;holds pointer to a turtle that draws the grid
  create-turtles 1 [set pencil self set color blue ]

  while [ xi <= max-pxcor ]   ;draw verticles
  [
    ask pencil
    [
      set heading 0
      setxy xi min-pycor
      pd
      fd world-height
      pu
    ]
    set xi xi + grid-size
  ]
  while [ yi <= max-pycor ]   ;draw horizonals
  [
    ask pencil
    [
      set heading 90
      setxy min-pxcor yi
      pd
      fd world-width
      pu
    ]
    set yi yi + grid-size
  ]
  ask pencil [die]
end

;to-report import-interpolation-data [fname ] ;this procedure used only when data is on disk; web version all data is contained in the program
;  let one-list-item []
;  let lvar []
;  file-open fname
;  let x file-read-line ;read and discard the header line
;  while [not file-at-end?]
;  [
;    set one-list-item (list file-read file-read file-read file-read file-read)
;    set lvar lput one-list-item lvar
;    ;print one-list-item
;    set one-list-item []
;  ]
;  print lvar
;  file-close
;  report lvar
;end

to-report grid-number [ px py ]   ;given a patch coordinate, report the grid it is in
  let gn 0
  let col-num floor ((floor px) / grid-size)
  let row-num floor ((floor py) / grid-size)
  set gn (row-num * x-grid-count) + col-num
;  print (word "col-num: " col-num " row-num: " row-num " grid-number: " gn)
  report gn
end

to-report grid-coordinates [ grid-num ]  ;given the number of a grid square, report the patch coordinates in a list
  let row-num floor (grid-num / x-grid-count)
  let col-num  grid-num - row-num * x-grid-count
  report (list (col-num * grid-size) (row-num * grid-size))
end

to-report read-data [ grid-num variable-string ]
  let grid-data item grid-num interpolation-dataset
  if (variable-string = "Air Moisture")
    [ report item 4 grid-data ]
  ifelse temperature-unit = "Fahrenheit"
    [ report item 2 grid-data ]
    [ report item 3 grid-data ]
end

to-report color-from-temperature [ T ]
  if (temperature-unit = "Celsius") [ set T ( T * 9 / 5) + 32 ]  ;within this procedure, all temperatures are in Fahenheit
  if (T <= 19) [report violet]
  if (T > 19 and T <= 29) [report blue]
  if (T > 29 and T <= 39) [report green]
  if (T > 39 and T <= 49) [report yellow]
  if (T > 49 and T <= 59) [report orange]
  if (T > 59) [report magenta] ; [report red] magenta seems to look better than red
end

to-report color-from-moisture [ M ]
  report 93.0 + (0.8 * (10 - M))             ;my own "sky" color range
end

to clear-and-show-data
  setup
  show-data
end

to show-data  ;handles both temperature and moisture variables depending on the setting
  let i 0
  let shape-str ifelse-value (variable-to-show = "Temperature")["thermometer"]["triangle 3"]
  let padding ifelse-value (variable-to-show = "Temperature")["      "]["        "]
  let offset grid-size / 2
  while [i < (x-grid-count * y-grid-count) ]
  [
    let pair grid-coordinates i
    let d read-data i variable-to-show
    let c ifelse-value (variable-to-show = "Temperature")[color-from-temperature d][color-from-moisture d]

    create-turtles 1 [
      set shape shape-str
      set size 3
      set color c
      set label (word  d padding )
      set label-color black
      let x first pair + offset
      let y last pair + offset
      ;print (word "grid-num: " i " x: " x " y: " y)
      setxy x y
    ]
    set i i + 1
  ]
end

to execute-rules
  let critical-temp-delta ifelse-value (temperature-unit = "Fahrenheit") [5][2.5] ;technically the Celsius critical temp for 5 F is 2.77, but we use 2.5 b/c the slider moves in 0.5 increments
  let NW-square-offset x-grid-count - 1      ;the northwest square will alway be the row above and one to the left
  let cnt length test-square-list
  setup
  let i 0
  while [i < cnt]
  [
    let idx item i test-square-list
    let test-squ1-temp read-data idx "Temperature"
    let test-squ1-moist read-data idx "Air Moisture"
    let test-squ2-temp read-data (idx + NW-square-offset) "Temperature"
    let deltaT test-squ1-temp - test-squ2-temp ;so test-squ2 should be smaller than test-squ1-temp so the deltaT is positive
    ;print (word "square: " idx " test-squ1-temp: " test-squ1-temp " test-squ1-moist: " test-squ1-moist " deltaT: " deltaT)
    if ( (square-to-NW-is-colder-by <= deltaT) and (test-squ1-moist >= air-moisture-is-at-least ))
    [
      ifelse (test-squ1-moist = light-rain-if-air-moisture-is)
        [show-light-rain idx]
        [ ifelse (test-squ1-moist = moderate-rain-if-air-moisture-is)
           [show-moderate-rain idx]
           [ if (test-squ1-moist = heavy-rain-if-air-moisture-is)
             [show-heavy-rain idx]
           ]
        ]
    ]
    set i i + 1
  ]
end

to show-light-rain [square-index ]
  let x-offset grid-size / 2
  let y-offset grid-size / 2
    create-turtles 1 [
      set shape "raindrop small"
      set size 4
      set color blue
      let pair grid-coordinates square-index
      setxy (first pair + x-offset) (last pair + y-offset)
    ]
end

to show-moderate-rain [square-index ]
  let x-offset grid-size / 2
  let y-offset grid-size / 2
    create-turtles 1 [
      set shape "raindrop small"
      set size 4
      set color blue
      let pair grid-coordinates square-index
      setxy (first pair + x-offset - 0.6) (last pair + y-offset)
    ]
    create-turtles 1 [
      set shape "raindrop small"
      set size 4
      set color blue
      let pair grid-coordinates square-index
      setxy (first pair + x-offset + 0.6) (last pair + y-offset - 0.6)
    ]
end

to show-heavy-rain [square-index ]
  let x-offset grid-size / 2
  let y-offset grid-size / 2
    create-turtles 1 [
      set shape "raindrop small"
      set size 4
      set color blue
      let pair grid-coordinates square-index
      setxy (first pair + x-offset) (last pair + y-offset)
    ]
      create-turtles 1 [
      set shape "raindrop small"
      set size 4
      set color blue
      let pair grid-coordinates square-index
      setxy (first pair + x-offset + 1.2) (last pair + y-offset - 0.6 )
    ]
      create-turtles 1 [
      set shape "raindrop small"
      set size 4
      set color blue
      let pair grid-coordinates square-index
      setxy (first pair + x-offset - 1.0) (last pair + y-offset - 1.2)
    ]
end


to set-interpolation-dataset
  if interpolation-method = "Nearest Neighbor" [set interpolation-dataset nearest-neighbor-data]
  if interpolation-method = "Linear" [set interpolation-dataset linear-data ]
  if interpolation-method = "Weighted Average" [set interpolation-dataset weighted-average-data]
end

;to import-data-from-files  ;used only in disk based version
;  ifelse (is-NE?) [
;    set nearest-neighbor-data import-interpolation-data "Lesson 3 (Precip Rule) Netlogo Data - Nearest Neighbor.tsv"
;    set linear-data import-interpolation-data  "Lesson 3 (Precip Rule) Netlogo Data - Linear.tsv"
;    set weighted-average-data import-interpolation-data  "Lesson 3 (Precip Rule) Netlogo Data - Weighted Average.tsv"
;  ]
;  [
;    set nearest-neighbor-data import-interpolation-data "Alaska Lesson 3 (Precip Rule) Netlogo Data - Nearest Neighbor.tsv"
;    set linear-data import-interpolation-data  "Alaska Lesson 3 (Precip Rule) Netlogo Data - Linear.tsv"
;    set weighted-average-data import-interpolation-data  "Alaska Lesson 3 (Precip Rule) Netlogo Data - Weighted Average.tsv"
;  ]
;end

to-report set-max-temp-slider
  report ifelse-value (temperature-unit = "Fahrenheit")[10][5]
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
786
587
-1
-1
8.0
1
12
1
1
1
0
0
0
1
0
70
0
70
0
0
0
ticks
30.0

BUTTON
7
70
71
103
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

CHOOSER
17
133
169
178
interpolation-method
interpolation-method
"Nearest Neighbor" "Weighted Average" "Linear"
0

CHOOSER
15
14
169
59
temperature-unit
temperature-unit
"Fahrenheit" "Celsius"
0

CHOOSER
17
187
168
232
variable-to-show
variable-to-show
"Temperature" "Air Moisture"
0

BUTTON
8
588
118
621
Execute Rules
execute-rules
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
9
110
159
128
------Data Setup------
12
0.0
1

TEXTBOX
11
288
145
318
------Rule Design------\nIF the...
12
0.0
1

BUTTON
10
246
102
279
Show Data
clear-and-show-data
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
18
319
199
352
square-to-NW-is-colder-by
square-to-NW-is-colder-by
0
max-temp-slider
2.0
ifelse-value (temperature-unit = "Fahrenheit")[1][0.5]
1
NIL
HORIZONTAL

TEXTBOX
10
369
94
394
AND IF the...
12
0.0
1

TEXTBOX
160
355
202
373
degrees
11
0.0
1

SLIDER
19
388
198
421
air-moisture-is-at-least
air-moisture-is-at-least
0
10
5.0
1
1
NIL
HORIZONTAL

TEXTBOX
9
425
123
470
IT RAINS.\nIF IT RAINS then...
12
0.0
1

SLIDER
19
457
199
490
light-rain-if-air-moisture-is
light-rain-if-air-moisture-is
0
10
1.0
1
1
NIL
HORIZONTAL

SLIDER
20
500
198
533
moderate-rain-if-air-moisture-is
moderate-rain-if-air-moisture-is
0
10
5.0
1
1
NIL
HORIZONTAL

SLIDER
19
542
199
575
heavy-rain-if-air-moisture-is
heavy-rain-if-air-moisture-is
0
10
8.0
1
1
NIL
HORIZONTAL

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

raindrop small
false
0
Circle -7500403 true true 109 162 84
Polygon -7500403 true true 137 135 144 113 149 91 152 76 152 171 112 196 129 156
Polygon -7500403 true true 166 138 159 116 154 94 151 79 151 174 191 199 174 159

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

thermometer
false
0
Rectangle -16777216 true false 120 15 180 270
Circle -16777216 true false 95 186 108
Circle -7500403 true true 108 198 85
Rectangle -7500403 true true 135 30 165 225

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 3
false
0
Polygon -16777216 true false 150 30 15 255 285 255
Polygon -7500403 true true 150 60 255 240 45 240

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
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
