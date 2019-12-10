;;  Precipitation Rule Model (Lesson 3), v.5
;;  Precipitating Change Project
;;  jdomyancich (initial design) and nkimball (revised and implemented)
;;  started December 2018, post- initial field-test version v2, May 2019 (to be used in Alaska 2020)

;; version 4 - brings in data from 4 hour intervals so that the rule can be tested against different data sets
;; version 5 - work on UI so that updates are automatic and hopefully a bit more intuitive (Dec 2019)

breed [temp-icons temp-icon]              ;uses thermometer, but not visible in this version, only the label for displaying temp data
breed [temp-checks temp-check]            ;check mark for showing temp data meets the temperature delta from the square to the NW of the one you are on
breed [moisture-icons moisture-icon]      ;uses triangle, but not visible in this version, only the label for displaying moisture data
breed [moisture-checks moisture-check]    ;uses check mark for showing that the moisture meets the moisture threshold
breed [recorded-rains recorded-rain]
breed [rain-drops rain-drop]


temp-checks-own [ temp-diff sq-num ]
moisture-checks-own [ moist-val sq-num rain-amount]

globals
[
  is-NE?                       ;set true, map and data of NE is loaded; set false, AK data and map loaded
  x-grid-count                 ;horizontal number of grid squares
  y-grid-count                 ;vertical number of squares
  temperature-unit             ;for Alaska, it is now a constant, "Fahrenheit"
  grid-size                    ;number of patches per square
  variable-to-show             ;used to be defined as an interface variable but is constant now
  interpolation-method         ;this used to be defined as an interface variable but it is a constant now
  nearest-neighbor-data        ;holds the active nearest neighbor data set, established on setup
  linear-data                  ;holds the active linear data set
  weighted-average-data        ;holds the active weighted average data set
  nearest-neighbor-data-NE     ;data used when is-NE? set true
  linear-data-NE
  weighted-average-data-NE
  EP-7am-data-AK               ;data used when is-NE? set false
  EP-11am-data-AK
  EP-3pm-data-AK
  EP-7pm-data-AK
  EP-11pm-data-AK
  EP-7pm-data-NE               ;data used when is-NE? set true
  nearest-neighbor-data-AK
  linear-data-AK
  weighted-average-data-AK
  interpolation-dataset        ;holds pointer to the presently set dataset
  test-square-list             ;holds list of grid square numbers that have a NW square
  max-temp-slider              ;depends on C or F
  presently-set-temp-unit      ;C or F
  presently-set-data-time      ;One of the text string values from the time-of-data-set dropdown.
  max-air-moisture
  light-rain-if-air-moisture-is      ;value set in execute-rules (v2 of this program, only)
  moderate-rain-if-air-moisture-is   ;value set in execute-rules
  heavy-rain-if-air-moisture-is      ;value set in execute-rules
  temp-slider-tick
  t-check                      ;agent set of squares to test for temp diff
  m-check                      ;agent set of squares to test for moisture
  t-true                       ;agent set of squares that meet the temperature rule
  m-true                       ;agent set of squares that meet the moisture rule
  present-t-val                ;for detecting slider change
  present-m-val                ;for detecting slider change
  is running?                  ;flag for getting the display right
  data-cleared?                ;another flag for getting the dispaly right
  is-running?                  ;controlled by go procedure
]

to startup
  ct
  set show-results-of-rules? false
  set-constant-globals
  reset-drawing               ;workaround: in netlogo web, import-drawing is asynchronous, so we need to seperate loading the map from drawing the grid
  set is-running? false
  set data-cleared? true
  set presently-set-temp-unit "Celsius"  ;this is set to trigger the conversion to Fahrenheit
end

to set-constant-globals
  set is-NE? false
  set x-grid-count 7
  set y-grid-count 7
  set grid-size 10            ;number of patchs of width and height of a grid square
  set max-air-moisture 10     ;based on visual scan of the data
  set variable-to-show "Both"
  set-default-shape temp-checks "check"
  set-default-shape moisture-checks "check"
  set-default-shape rain-drops "raindrop small"
  set-default-shape recorded-rains "raindrop small"
  set t-check no-turtles
  set m-check no-turtles
  set interpolation-method "Weighted Average" ;defined as a constant now, EP data is always the same.
  ;import-data-from-files     ;the data imported has now be transferred into this program, so this procedure is not used
  ;data format for each square: lat lon TempF TempC moisture rain (rain: 0=no rain, 1, 2, 3 = light, moderate, heavy rain)
  set EP-7am-data-AK [[40 -77 58 14.4 8 0] [40 -76 59 15 8 0] [40 -75 61 16.1 9 0] [40 -74 63 17.2 9 0] [40 -73 63 17.2 9 0] [40 -72 63 17.2 9 0] [40 -71 63 17.2 9 0] [41 -77 57 13.9 8 0] [41 -76 58 14.4 8 0] [41 -75 59 15 8 0] [41 -74 61 16.1 8 0] [41 -73 63 17.2 9 0] [41 -72 61 16.1 9 0] [41 -71 62 16.7 9 0] [42 -77 57 13.9 8 0] [42 -76 57 13.9 8 0] [42 -75 57 13.9 8 0] [42 -74 59 15 8 0] [42 -73 61 16.1 9 0] [42 -72 61 16.1 9 0] [42 -71 63 17.2 9 0] [43 -77 58 14.4 8 0] [43 -76 57 13.9 8 2] [43 -75 57 13.9 8 2] [43 -74 58 14.4 8 0] [43 -73 59 15 8 0] [43 -72 60 15.5 9 0] [43 -71 61 16.1 9 0] [44 -77 51 10.5 6 0] [44 -76 52 11.1 7 1] [44 -75 56 13.3 8 2] [44 -74 57 13.9 8 0] [44 -73 58 14.4 8 0] [44 -72 57 13.9 8 0] [44 -71 57 13.9 8 0] [45 -77 49 9.4 6 0] [45 -76 51 10.5 6 0] [45 -75 56 13.3 6 0] [45 -74 57 13.9 8 2] [45 -73 58 14.4 8 2] [45 -72 57 13.9 8 0] [45 -71 56 13.3 8 0] [46 -77 46 7.8 5 0] [46 -76 48 8.9 6 0] [46 -75 52 11.1 6 0] [46 -74 53 11.7 7 0] [46 -73 58 14.4 8 0] [46 -72 58 14.4 8 0] [46 -71 56 13.3 8 0]]
  set EP-11am-data-AK [[40 -77 59 15 8 0] [40 -76 60 16 9 0] [40 -75 62 17 9 0] [40 -74 64 18 9 3] [40 -73 64 18 9 0] [40 -72 64 18 10 0] [40 -71 65 18 10 0] [41 -77 57 14 8 2] [41 -76 58 14 8 2] [41 -75 59 15 8 0] [41 -74 61 16 8 2] [41 -73 63 17 9 0] [41 -72 63 18 9 0] [41 -71 64 18 9 0] [42 -77 53 12 7 0] [42 -76 55 13 7 1] [42 -75 56 13 8 0] [42 -74 59 15 8 2] [42 -73 61 16 9 3] [42 -72 62 17 9 0] [42 -71 65 18 9 0] [43 -77 50 10 6 0] [43 -76 52 11 6 0] [43 -75 54 12 7 0] [43 -74 56 13 8 2] [43 -73 58 15 8 0] [43 -72 61 16 9 0] [43 -71 63 17 9 1] [44 -77 48 9 5 0] [44 -76 50 10 6 0] [44 -75 52 11 6 0] [44 -74 54 12 7 0] [44 -73 57 14 8 0] [44 -72 57 14 8 0] [44 -71 58 15 8 0] [45 -77 46 8 5 0] [45 -76 49 9 6 0] [45 -75 51 10 6 0] [45 -74 53 12 7 1] [45 -73 56 14 8 2] [45 -72 56 14 8 0] [45 -71 56 13 8 0] [46 -77 42 6 4 0] [46 -76 44 7 4 0] [46 -75 46 8 5 0] [46 -74 49 9 5 0] [46 -73 54 13 7 0] [46 -72 55 13 7 0] [46 -71 55 13 7 0]]
  set EP-3pm-data-AK [[40 -77 58 14.4 8 2] [40 -76 59 15 8 2] [40 -75 62 16.7 9 3] [40 -74 63 17.2 9 3] [40 -73 64 17.8 9 0] [40 -72 64 17.8 10 0] [40 -71 65 18.3 10 0] [41 -77 53 11.7 7 0] [41 -76 54 12.2 7 1] [41 -75 56 13.3 7 1] [41 -74 59 15 8 2] [41 -73 64 17.8 9 3] [41 -72 63 17.2 9 0] [41 -71 64 17.8 9 0] [42 -77 48 8.9 5 0] [42 -76 49 9.4 6 0] [42 -75 51 10.5 6 0] [42 -74 54 12.2 7 1] [42 -73 60 15.5 9 3] [42 -72 62 16.7 9 0] [42 -71 65 18.3 10 0] [43 -77 46 7.8 5 0] [43 -76 46 7.8 5 0] [43 -75 48 8.9 5 0] [43 -74 51 10.5 6 0] [43 -73 58 14.4 8 2] [43 -72 61 16.1 8 2] [43 -71 62 16.7 9 3] [44 -77 45 7.2 4 0] [44 -76 46 7.8 5 0] [44 -75 47 8.3 5 0] [44 -74 49 9.4 6 0] [44 -73 53 11.7 7 1] [44 -72 54 12.2 7 0] [44 -71 55 12.8 7 0] [45 -77 43 6.1 4 0] [45 -76 45 7.2 4 0] [45 -75 46 7.8 5 0] [45 -74 48 8.9 5 0] [45 -73 51 10.5 6 0] [45 -72 52 11.1 6 0] [45 -71 52 11.1 6 0] [46 -77 39 3.9 3 0] [46 -76 41 5 3 0] [46 -75 43 6.1 3 0] [46 -74 45 7.2 4 0] [46 -73 49 9.4 5 0] [46 -72 49 9.4 6 0] [46 -71 50 10 6 0]]
  set EP-7pm-data-AK [[40 -77 52 11.1 6 0] [40 -76 53 11.6 7 1] [40 -75 55 12.7 7 1] [40 -74 59 14.9 8 2] [40 -73 62 16.6 9 3] [40 -72 63 17.2 9 0] [40 -71 64 17.7 9 0] [41 -77 47 8.3 5 0] [41 -76 47 8.3 5 0] [41 -75 48 8.8 6 0] [41 -74 51 10.5 6 0] [41 -73 60 15.5 9 3] [41 -72 61 16 9 3] [41 -71 62 16.6 9 0] [42 -77 44 6.6 4 0] [42 -76 43 6.1 5 0] [42 -75 44 6.6 5 0] [42 -74 47 8.3 5 0] [42 -73 54 12.2 7 1] [42 -72 58 14.4 8 2] [42 -71 62 16.6 9 3] [43 -77 43 6.1 4 0] [43 -76 42 5.5 4 0] [43 -75 42 5.5 4 0] [43 -74 45 7.2 5 0] [43 -73 51 10.5 6 0] [43 -72 54 12.2 7 1] [43 -71 58 14.4 8 2] [44 -77 41 4.9 3 0] [44 -76 41 4.9 4 0] [44 -75 40 4.4 4 0] [44 -74 41 4.9 4 0] [44 -73 45 7.2 5 0] [44 -72 46 7.7 5 0] [44 -71 47 8.3 7 1] [45 -77 38 3.3 3 0] [45 -76 39 3.8 3 0] [45 -75 39 3.8 3 0] [45 -74 40 4.4 3 0] [45 -73 42 5.5 4 0] [45 -72 42 5.5 4 0] [45 -71 42 5.5 4 0] [46 -77 35 1.6 2 0] [46 -76 35 1.6 2 0] [46 -75 36 2.2 2 0] [46 -74 38 3.3 3 0] [46 -73 40 4.4 3 0] [46 -72 40 4.4 4 0] [46 -71 40 4.4 4 0]]
  set EP-11pm-data-AK [[40 -77 45 7.2 4 0] [40 -76 45 7.2 4 0] [40 -75 45 7.2 4 0] [40 -74 48 8.9 5 0] [40 -73 55 12.8 7 1] [40 -72 58 14.4 7 1] [40 -71 60 15.5 8 2] [41 -77 41 5 4 0] [41 -76 41 5 4 0] [41 -75 41 5 4 0] [41 -74 43 6.1 4 0] [41 -73 50 10 6 0] [41 -72 55 12.8 7 1] [41 -71 58 14.4 7 1] [42 -77 39 3.9 3 0] [42 -76 38 3.3 3 0] [42 -75 38 3.3 4 0] [42 -74 40 4.4 4 0] [42 -73 46 7.8 5 0] [42 -72 49 9.4 5 0] [42 -71 53 11.7 7 1] [43 -77 40 4.4 3 0] [43 -76 38 3.3 3 0] [43 -75 37 2.8 3 0] [43 -74 38 3.3 4 0] [43 -73 42 5.6 4 0] [43 -72 45 7.2 4 0] [43 -71 49 9.4 5 0] [44 -77 37 2.8 2 0] [44 -76 37 2.8 3 0] [44 -75 35 1.7 3 0] [44 -74 35 1.7 3 0] [44 -73 38 3.3 4 0] [44 -72 38 3.3 4 0] [44 -71 39 3.9 4 0] [45 -77 34 1.1 2 0] [45 -76 35 1.7 2 0] [45 -75 35 1.7 2 0] [45 -74 35 1.7 2 0] [45 -73 37 2.8 3 0] [45 -72 36 2.2 3 0] [45 -71 36 2.2 3 0] [46 -77 31 -0.6 2 0] [46 -76 31 -0.6 2 0] [46 -75 32 0 2 0] [46 -74 33 0.6 2 0] [46 -73 37 2.8 2 0] [46 -72 36 2.2 3 0] [46 -71 35 1.7 3 0]]
  set EP-7pm-data-NE [[40 -77 52 11.1 6 0] [40 -76 53 11.6 7 1] [40 -75 55 12.7 7 1] [40 -74 59 14.9 8 2] [40 -73 62 16.6 9 3] [40 -72 63 17.2 9 0] [40 -71 64 17.7 9 0] [41 -77 47 8.3 5 0] [41 -76 47 8.3 5 0] [41 -75 48 8.8 6 0] [41 -74 51 10.5 6 0] [41 -73 60 15.5 9 3] [41 -72 61 16 9 3] [41 -71 62 16.6 9 0] [42 -77 44 6.6 4 0] [42 -76 43 6.1 5 0] [42 -75 44 6.6 5 0] [42 -74 47 8.3 5 0] [42 -73 54 12.2 7 1] [42 -72 58 14.4 8 2] [42 -71 62 16.6 9 3] [43 -77 43 6.1 4 0] [43 -76 42 5.5 4 0] [43 -75 42 5.5 4 0] [43 -74 45 7.2 5 0] [43 -73 51 10.5 6 0] [43 -72 54 12.2 7 1] [43 -71 58 14.4 8 2] [44 -77 41 4.9 3 0] [44 -76 41 4.9 4 0] [44 -75 40 4.4 4 0] [44 -74 41 4.9 4 0] [44 -73 45 7.2 5 0] [44 -72 46 7.7 5 0] [44 -71 47 8.3 7 1] [45 -77 38 3.3 3 0] [45 -76 39 3.8 3 0] [45 -75 39 3.8 3 0] [45 -74 40 4.4 3 0] [45 -73 42 5.5 4 0] [45 -72 42 5.5 4 0] [45 -71 42 5.5 4 0] [46 -77 35 1.6 2 0] [46 -76 35 1.6 2 0] [46 -75 36 2.2 2 0] [46 -74 38 3.3 3 0] [46 -73 40 4.4 3 0] [46 -72 40 4.4 4 0] [46 -71 40 4.4 4 0]]
  ; stored interpolation data for NE, list of lists, for each grid square the [lat, lon, F temp, C temp, Air Moisture precip-level]

  set test-square-list [1 2 3 4 5 6 8 9 10 11 12 13 15 16 17 18 19 20 22 23 24 25 26 27 29 30 31 32 33 34 36 37 38 39 40 41]
  set nearest-neighbor-data-NE [[40 -77 63 17.2 9] [40 -76 63 17.2 9] [40 -75 63 17.2 9] [40 -74 63 17.2 9] [40 -73 63 17.2 9] [40 -72 63 17.2 9] [40 -71 63 17.2 9] [41 -77 46 7.8 5] [41 -76 46 7.8 5] [41 -75 54 12.2 7] [41 -74 63 17.2 9] [41 -73 63 17.2 9] [41 -72 63 17.2 9] [41 -71 62 16.7 9] [42 -77 46 7.8 5] [42 -76 46 7.8 5] [42 -75 48 8.9 5] [42 -74 54 12.2 7] [42 -73 54 12.2 7] [42 -72 62 16.7 9] [42 -71 62 16.7 9] [43 -77 46 7.8 5] [43 -76 46 7.8 5] [43 -75 48 8.9 5] [43 -74 54 12.2 7] [43 -73 54 12.2 7] [43 -72 62 16.7 9] [43 -71 62 16.7 9] [44 -77 46 7.8 5] [44 -76 46 7.8 5] [44 -75 48 8.9 5] [44 -74 48 8.9 5] [44 -73 54 12.2 7] [44 -72 62 16.7 9] [44 -71 62 16.7 9] [45 -77 46 7.8 5] [45 -76 46 7.8 5] [45 -75 48 8.9 5] [45 -74 48 8.9 5] [45 -73 48 8.9 5] [45 -72 62 16.7 9] [45 -71 62 16.7 9] [46 -77 46 7.8 5] [46 -76 46 7.8 5] [46 -75 48 8.9 5] [46 -74 48 8.9 5] [46 -73 48 8.9 5] [46 -72 62 16.7 9] [46 -71 62 16.7 9]]
  set linear-data-NE [[40 -77 57 13.9 8] [40 -76 57 13.9 9] [40 -75 59 15 9] [40 -74 63 17.2 9] [40 -73 66 18.9 10] [40 -72 64 17.8 10] [40 -71 68 20 10] [41 -77 53 11.7 7] [41 -76 54 12.2 8] [41 -75 57 13.9 8] [41 -74 59 15 8] [41 -73 62 16.7 9] [41 -72 63 17.2 9] [41 -71 64 17.8 10] [42 -77 49 9.4 6] [42 -76 51 10.6 6] [42 -75 53 11.7 7] [42 -74 54 12.2 7] [42 -73 58 14.4 8] [42 -72 62 16.7 9] [42 -71 66 18.9 10] [43 -77 44 6.7 5] [43 -76 46 7.8 5] [43 -75 48 8.9 5] [43 -74 53 11.7 6] [43 -73 56 13.3 7] [43 -72 61 16.1 8] [43 -71 62 16.7 9] [44 -77 39 3.9 3] [44 -76 42 5.6 3] [44 -75 47 8.3 5] [44 -74 50 10 6] [44 -73 54 12.2 6] [44 -72 57 13.9 7] [44 -71 60 15.6 8] [45 -77 38 3.3 3] [45 -76 42 5.6 4] [45 -75 46 7.8 5] [45 -74 48 8.9 5] [45 -73 50 10 6] [45 -72 52 11.1 6] [45 -71 54 12.2 7] [46 -77 37 2.8 3] [46 -76 44 6.7 4] [46 -75 45 7.2 4] [46 -74 46 7.8 4] [46 -73 46 7.8 5] [46 -72 47 8.3 5] [46 -71 50 10 6]]
  set weighted-average-data-NE [[40 -77 54 12.2 7] [40 -76 58 14.4 8] [40 -75 61 16.1 8] [40 -74 63 17.2 9] [40 -73 63 17.2 9] [40 -72 63 17.2 9] [40 -71 63 17.2 9] [41 -77 53 11.7 7] [41 -76 54 12.2 7] [41 -75 57 13.9 7] [41 -74 59 15 8] [41 -73 62 16.7 9] [41 -72 63 17.2 9] [41 -71 63 17.2 9] [42 -77 49 9.4 6] [42 -76 48 8.9 7] [42 -75 50 10 7] [42 -74 54 12.2 7] [42 -73 59 15 8] [42 -72 61 16.1 9] [42 -71 62 16.7 9] [43 -77 48 8.9 5] [43 -76 46 7.8 5] [43 -75 48 8.9 5] [43 -74 51 10.6 7] [43 -73 58 14.4 8] [43 -72 61 16.1 8] [43 -71 62 16.7 9] [44 -77 46 7.8 5] [44 -76 46 7.8 5] [44 -75 47 8.3 5] [44 -74 52 11.1 6] [44 -73 56 13.3 7] [44 -72 57 13.9 8] [44 -71 60 15.6 9] [45 -77 46 7.8 5] [45 -76 46 7.8 5] [45 -75 46 7.8 5] [45 -74 47 8.3 6] [45 -73 51 10.6 6] [45 -72 52 11.1 6] [45 -71 54 12.2 7] [46 -77 46 7.8 5] [46 -76 46 7.8 5] [46 -75 46 7.8 5] [46 -74 48 8.9 5] [46 -73 50 10 6] [46 -72 52 11.1 6] [46 -71 55 12.8 6]]

  set nearest-neighbor-data-AK [[40 -77 56 13.3 7] [40 -76 56 13.3 7] [40 -75 56 13.3 7] [40 -74 56 13.3 7] [40 -73 56 13.3 7] [40 -72 58 14.4 8] [40 -71 58 14.4 8] [41 -77 56 13.3 7] [41 -76 56 13.3 7] [41 -75 56 13.3 7] [41 -74 56 13.3 7] [41 -73 58 14.4 8] [41 -72 58 14.4 8] [41 -71 58 14.4 8] [42 -77 46 7.8 5] [42 -76 46 7.8 5] [42 -75 56 13.3 7] [42 -74 56 13.3 7] [42 -73 58 14.4 8] [42 -72 58 14.4 8] [42 -71 58 14.4 8] [43 -77 46 7.8 5] [43 -76 46 7.8 5] [43 -75 46 7.8 5] [43 -74 58 14.4 8] [43 -73 58 14.4 8] [43 -72 58 14.4 8] [43 -71 52 11.1 6] [44 -77 46 7.8 5] [44 -76 46 7.8 5] [44 -75 46 7.8 5] [44 -74 58 14.4 8] [44 -73 58 14.4 8] [44 -72 52 11.1 6] [44 -71 52 11.1 6] [45 -77 46 7.8 5] [45 -76 46 7.8 5] [45 -75 46 7.8 5] [45 -74 46 7.8 5] [45 -73 52 11.1 6] [45 -72 52 11.1 6] [45 -71 52 11.1 6] [46 -77 46 7.8 5] [46 -76 46 7.8 5] [46 -75 46 7.8 5] [46 -74 46 7.8 5] [46 -73 52 11.1 6] [46 -72 52 11.1 6] [46 -71 52 11.1 6]]
  set linear-data-AK [[40 -77 51 10.6 7] [40 -76 55 12.8 8] [40 -75 59 15 8] [40 -74 63 17.2 9] [40 -73 64 17.8 9] [40 -72 66 18.9 10] [40 -71 69 20.6 10] [41 -77 48 8.9 5] [41 -76 52 11.1 6] [41 -75 56 13.3 7] [41 -74 60 15.6 9] [41 -73 64 17.8 9] [41 -72 65 18.3 10] [41 -71 67 19.4 10] [42 -77 45 7.2 5] [42 -76 49 9.4 6] [42 -75 53 11.7 7] [42 -74 57 13.9 8] [42 -73 61 16.1 9] [42 -72 63 17.2 10] [42 -71 65 18.3 10] [43 -77 42 5.6 4] [43 -76 46 7.8 5] [43 -75 50 10 6] [43 -74 54 12.2 7] [43 -73 58 14.4 8] [43 -72 61 16.1 9] [43 -71 63 17.2 9] [44 -77 40 4.4 5] [44 -76 44 6.7 5] [44 -75 48 8.9 6] [44 -74 51 10.6 6] [44 -73 54 12.2 7] [44 -72 57 13.9 7] [44 -71 60 15.6 8] [45 -77 38 3.3 4] [45 -76 42 5.6 5] [45 -75 46 7.8 5] [45 -74 48 8.9 5] [45 -73 50 10 6] [45 -72 52 11.1 6] [45 -71 54 12.2 6] [46 -77 36 2.2 4] [46 -76 41 5 4] [46 -75 44 6.7 4] [46 -74 45 7.2 5] [46 -73 46 7.8 5] [46 -72 47 8.3 5] [46 -71 48 8.9 5]]
  set weighted-average-data-AK  [[40 -77 53 11.7 7] [40 -76 56 13.3 8] [40 -75 58 14.4 8] [40 -74 60 15.6 8] [40 -73 64 17.8 9] [40 -72 65 18.3 10] [40 -71 67 19.4 10] [41 -77 51 10.6 7] [41 -76 53 11.7 7] [41 -75 55 12.8 7] [41 -74 59 15 8] [41 -73 63 17.2 9] [41 -72 65 18.3 10] [41 -71 67 19.4 10] [42 -77 48 8.9 6] [42 -76 50 10 6] [42 -75 54 12.2 7] [42 -74 59 15 8] [42 -73 61 16.1 9] [42 -72 63 17.2 9] [42 -71 66 18.9 10] [43 -77 45 7.2 5] [43 -76 46 7.8 5] [43 -75 48 8.9 6] [43 -74 55 12.8 7] [43 -73 58 14.4 8] [43 -72 58 14.4 8] [43 -71 61 16.1 9] [44 -77 44 6.7 5] [44 -76 45 7.2 5] [44 -75 47 8.3 6] [44 -74 51 10.6 7] [44 -73 53 11.7 7] [44 -72 54 12.2 7] [44 -71 57 13.9 8] [45 -77 43 6.1 4] [45 -76 45 7.2 5] [45 -75 46 7.8 5] [45 -74 48 8.9 6] [45 -73 52 11.1 6] [45 -72 52 11.1 6] [45 -71 52 11.1 6] [46 -77 43 6.1 4] [46 -76 45 7.2 5] [46 -75 46 7.8 5] [46 -74 49 9.4 6] [46 -73 52 11.1 6] [46 -72 52 11.1 6] [46 -71 52 11.1 6]]
  ifelse (is-NE?) [
    set weighted-average-data set-time-dataset      ;formally EP-7pm-data-NE
;  set nearest-neighbor-data nearest-neighbor-data-NE
;  set linear-data linear-data-NE
;  set weighted-average-data weighted-average-data-NE
  ]
  [
    set weighted-average-data set-time-dataset      ;formally EP-7pm-data-NE
;  set nearest-neighbor-data nearest-neighbor-data-AK
;  set linear-data linear-data-AK
;  set weighted-average-data weighted-average-data-AK
  ]
  set temperature-unit "Fahrenheit"
  set presently-set-data-time time-of-data-set  ;by setting the two previous variables as the are, the unit is set to "Fahrenheit"
  set-temp-slider-unit-change
  set-interpolation-dataset
  set data-cleared? true
end

to setup
  ; reset-drawing
  ask turtles [die]      ;acts like ct to clear turtles but without erasing the drawing (map)
  set-constant-globals
  draw-grid
  set present-t-val is-colder-by-at-least
  set present-m-val air-moisture-is-at-least
end

to-report set-time-dataset
  if time-of-data-set = "7 am"   [report EP-7am-data-AK]
  if time-of-data-set = "11 am"  [report EP-11am-data-AK]
  if time-of-data-set = "3 pm"   [report EP-3pm-data-AK]
  if time-of-data-set = "7 pm"   [report EP-7pm-data-AK]
  if time-of-data-set = "11 pm"  [report EP-11pm-data-AK]
end

to go
  if  data-cleared? and is-running? [set is-running? false stop ]
  if (time-of-data-set != presently-set-data-time) or data-cleared?
    [
      set presently-set-data-time time-of-data-set
      clear-and-show-data
      set data-cleared? false
    ]

  if is-colder-by-at-least != present-t-val or air-moisture-is-at-least != present-m-val ;slider change detecter
  [
    ask rain-drops [die]
    set present-t-val is-colder-by-at-least
    set present-m-val air-moisture-is-at-least
  ]

  calculate-results-of-rules
  show-hide-results-of-rules
  set is-running? true
end

to reset-drawing
  cd
  import-drawing  "./ak-w-cities.png"
  ;ifelse netlogo-web?
  ;  [ import-drawing "https://models-resources.concord.org/precip-models/ak-w-cities.png"]
  ; [ import-drawing  "./ak-w-cities.png" ]
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
;  print x
;  while [not file-at-end?]
;  [
;    set one-list-item (list file-read file-read file-read file-read file-read file-read)
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

to-report read-data [ grid-num variable-string ]  ;unpacks a list of lists, i.e., the data for each grid square is held in a list that is in a list of all grids
  let grid-data item grid-num interpolation-dataset
  if (variable-string = "Rain")
    [report item 5 grid-data]
  if (variable-string = "Air Moisture")
    [ report item 4 grid-data ]
  ifelse temperature-unit = "Fahrenheit"
    [ report item 2 grid-data ]
    [ report item 3 grid-data ]   ;Celsius data
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
  show-recorded-rain-data
end

;originaally there was a interface variable called varible-to-show that appeared in a drop-down that could have the values:
; "Temperature"
; "Air Moisture"
; "Both"
;We only use "Both" now

to show-data  ;handles both temperature and moisture variables depending on the setting
  ifelse variable-to-show != "Both"
  [
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
  ]
  [ ;if "Both"
    let i 0
    let t-shape-str "thermometer"
    let m-shape-str "triangle 3"
    let t-padding ifelse-value (temperature-unit = "Fahrenheit") [" ºF" ][" ºC" ]
    let m-padding " "
    let offset grid-size / 2
    let t-x-offset ifelse-value (temperature-unit = "Fahrenheit") [ 0.1 ][ 1.4 ]
    let m-x-offset 4.2
    let t-y-offset -3.8   ;-1.75
    let m-y-offset 3.4    ;1.75
    while [i < (x-grid-count * y-grid-count) ]
    [
      let pair grid-coordinates i
      let t read-data i "Temperature"
      let t-c color-from-temperature t

      create-turtles 1 [                     ;each data turtle has an associated "check" breed that shows the check when it meets the rule criteria
        set shape t-shape-str
        set size 0  ;2.5                     ;the shape of this turtle is never displayed, only the label
        set color t-c
        set label (word  t t-padding )
        set label-color black
        let x first pair + offset + t-x-offset
        let y last pair + offset + t-y-offset
        ;print (word "grid-num: " i " x: " x " y: " y)
        setxy x y
        if (member? i test-square-list)
        [
        hatch-temp-checks 1 [               ;check breed for the temperature difference
          set shape "check"
          set color orange
          set size 2.5
          set hidden? true
          set label ""
          set sq-num i
          set temp-diff NE-grid-temp-diff i
          set xcor xcor + 2
          set ycor ycor + 0.5
          ]
        ]
      ]

      let m read-data i "Air Moisture"
      let m-c color-from-moisture m

      create-turtles 1 [
        set shape m-shape-str
        set size 0  ;2.5                  ;the shape of this turtle is never displayed, only the label
        set color m-c
        set label (word  m m-padding )
        set label-color black
        let x first pair + offset + m-x-offset
        let y last pair + offset + m-y-offset
        ;print (word "grid-num: " i " x: " x " y: " y)
        setxy x y
        if (member? i test-square-list)
        [
        hatch-moisture-checks 1 [      ;check breed for the moisture value
          set shape "check"
          set color green
          set size 2.5
          set hidden? true
          set label ""
          set sq-num i
          set moist-val grid-moisture i
          set xcor xcor - 3
        ]
        ]
      ]

      set i i + 1
    ]
  ]
  set t-check temp-checks with [ member? sq-num test-square-list]
  set m-check moisture-checks with [ member? sq-num test-square-list ]
end

to-report NE-grid-temp-diff [ grid-num ]
  if not member? grid-num test-square-list ;error check, should never occur once debugged
    [
      user-message (word "NE-grid-temp-diff: Grid number is not valid input " grid-num)
      report -1
    ]
  let NW-square-offset x-grid-count - 1      ;the northwest square will alway be the row above and one to the left
  let test-squ1-temp read-data grid-num "Temperature"
  let test-squ2-temp read-data (grid-num + NW-square-offset) "Temperature"
  let deltaT test-squ1-temp - test-squ2-temp ;so test-squ2 should be smaller than test-squ1-temp so the deltaT is positive, although it is not required to be
  report deltaT
end

to-report grid-moisture [ grid-num ]
    if not member? grid-num test-square-list ;error check, should never occur once debugged
    [
      user-message (word "grid-moisture: Grid number is not valid input " grid-num)
      report -1
    ]
  let moist read-data grid-num "Air Moisture"
  report moist
end

to show-recorded-rain-data
  let i 0
  while [i < (x-grid-count * y-grid-count) ]
  [
    let pair grid-coordinates i
    let d read-data i "Rain"
    if (d = 1 or d = 2 or d = 3)
      [ show-recorded-rain i ]
    set i i + 1
  ]
end

to calculate-results-of-rules
  set weighted-average-data set-time-dataset      ;formally EP-7pm-data-NE
  if is-colder-by-at-least != present-t-val or air-moisture-is-at-least != present-m-val ;slider change detecter
  [
    ask rain-drops [die]
    set present-t-val is-colder-by-at-least
    set present-m-val air-moisture-is-at-least
  ]
  set t-true t-check with [ temp-diff >= is-colder-by-at-least ]
;  ask t-check [
;    ifelse (temp-diff >= is-colder-by-at-least)
;      [set hidden? false][set hidden? true]
;  ]
  set m-true m-check with [ moist-val >= air-moisture-is-at-least ]
;  ask m-check [
;    ifelse (moist-val >= air-moisture-is-at-least)
;      [set hidden? false][set hidden? true]
;  ]
end

to show-hide-results-of-rules
  ifelse show-results-of-rules?
  [
    ask t-check [
      ifelse (temp-diff >= is-colder-by-at-least)
      [set hidden? false][set hidden? true]
    ]
    ask m-check [
      ifelse (moist-val >= air-moisture-is-at-least)
      [set hidden? false][set hidden? true]
    ]
  ]
  [
    ask t-check [set hidden? true]
    ask m-check [set hidden? true]
  ]
end

to execute-rules
  let t-true-sq-list [ sq-num ] of t-true      ;make a list of the sq-nums in the temp true agents
  let m-true-sq-list [ sq-num ] of m-true      ;make a list of the sq-nums in the moisture true agents
  ;show (word "Len temp: " length t-true-sq-list " Len moisture: " length m-true-sq-list)
  let rain-list []
  let cnt 0
  while [cnt < length t-true-sq-list][  ;find the overlap (intersection) of rules that meet both the temp and moisture criteria
    let x (item cnt t-true-sq-list)
    if member? x m-true-sq-list
      [set rain-list lput x rain-list]  ; and create a list of those squares
    set cnt cnt + 1
  ]
  ;print (word "rain-list: " rain-list)
  let rain-squares m-true with [ member? sq-num rain-list]  ;make a list of the moistures breed that support rain
  ;show (word "rain squares: " rain-squares)
  if any? rain-squares [
    let min-moist [moist-val] of min-one-of rain-squares [moist-val]  ;for figuring out level of rain, light, moderate, heavy
    let max-moist [moist-val] of max-one-of rain-squares [moist-val]
    let moisture-span max-moist - min-moist

    let moisture-step moisture-span / 3    ;divide by 3 because there are 3 levels of rain intensity
                                           ;print (word "moisture step: " moisture-step)
    set light-rain-if-air-moisture-is min-moist
    set moderate-rain-if-air-moisture-is light-rain-if-air-moisture-is + moisture-step          ;moderate rain threshold is 1/3 of the way from the initial threshold to the max moisture
    set heavy-rain-if-air-moisture-is moderate-rain-if-air-moisture-is + ((max-air-moisture - moderate-rain-if-air-moisture-is) / 2)  ;heavy rain threshold is half of what is left
    ask m-check [set rain-amount 0]
    ask rain-drops [ die ]
    ask rain-squares [set rain-amount 3 show-heavy-rain sq-num] ;if any rain, show 3 rain drops in the square
  ]
;  ask rain-squares [
;    ifelse ( (moist-val >= light-rain-if-air-moisture-is) and (moist-val < moderate-rain-if-air-moisture-is ))
;    [
;      set rain-amount 1
;      show-light-rain sq-num
;    ]
;    [ ifelse (moist-val >= moderate-rain-if-air-moisture-is and moist-val < heavy-rain-if-air-moisture-is)
;      [
;        set rain-amount 2
;        show-moderate-rain sq-num
;      ]
;      [
;        set rain-amount 3
;        show-heavy-rain sq-num
;      ]
;    ]
;  ]
end

to show-light-rain [square-index ]
  let x-offset grid-size / 2
  let y-offset grid-size / 2
    hatch-rain-drops 1 [
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
    hatch-rain-drops 1 [
      set shape "raindrop small"
      set size 4
      set color blue
      let pair grid-coordinates square-index
      setxy (first pair + x-offset - 0.6) (last pair + y-offset)
    ]
    hatch-rain-drops 1 [
      set shape "raindrop small"
      set size 4
      set color blue
      let pair grid-coordinates square-index
      setxy (first pair + x-offset + 0.6) (last pair + y-offset - 0.6)
    ]
end

to show-heavy-rain [square-index ]
  let x-offset grid-size / 2
  let y-offset (grid-size / 2) + 0.5
    hatch-rain-drops 1 [
      set size 4
      set color blue
      set hidden? false
      let pair grid-coordinates square-index
      setxy (first pair + x-offset) (last pair + y-offset)
    ]
      hatch-rain-drops 1 [
      set size 4
      set color blue
      set hidden? false
      let pair grid-coordinates square-index
      setxy (first pair + x-offset + 1.2) (last pair + y-offset - 0.6 )
    ]
      hatch-rain-drops 1 [
      set size 4
      set color blue
      set hidden? false
      let pair grid-coordinates square-index
      setxy (first pair + x-offset - 1.0) (last pair + y-offset - 1.2)
    ]
end

to show-recorded-rain [square-index ]
  let x-offset (grid-size / 2) - 0.4
  let y-offset (grid-size / 2) + 0.5
  let c cyan + 1
    create-recorded-rains 1 [
      set size 4
      set color c
      let pair grid-coordinates square-index
      setxy (first pair + x-offset) (last pair + y-offset)
    ]
      create-recorded-rains 1 [
      set size 4
      set color c
      let pair grid-coordinates square-index
      setxy (first pair + x-offset + 1.2) (last pair + y-offset - 0.6 )
    ]
      create-recorded-rains 1 [
      set size 4
      set color c
      let pair grid-coordinates square-index
      setxy (first pair + x-offset - 1.0) (last pair + y-offset - 1.2)
    ]
end

to set-interpolation-dataset
  if interpolation-method = "Nearest Neighbor" [set interpolation-dataset nearest-neighbor-data]
  ;NOTE: "Linear" has been removed from the drop-down options for the v2 version based on field-test results -NK
  if interpolation-method = "Linear" [set interpolation-dataset linear-data ]
  if interpolation-method = "Weighted Average" [set interpolation-dataset weighted-average-data]
end

;to import-data-from-files  ;used only in disk based version
;  ;set EP-7pm-data-AK import-interpolation-data "AK_EP2_7pm.tsv"
;  set EP-7am-data-AK import-interpolation-data "AK_EP2_7am.tsv"
;  set EP-11am-data-AK import-interpolation-data "AK_EP2_11am.tsv"
;  set EP-3pm-data-AK import-interpolation-data "AK_EP2_3pm.tsv"
;  set EP-11pm-data-AK import-interpolation-data "AK_EP2_11pm.tsv"
  ;set EP-7pm-data-NE import-interpolation-data "NE_EP2_7pm.tsv"
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

to set-temp-slider-unit-change
  if presently-set-temp-unit != temperature-unit
  [
  set max-temp-slider ifelse-value (temperature-unit = "Fahrenheit")[10][5]
  set temp-slider-tick ifelse-value (temperature-unit = "Fahrenheit")[1][0.5]
  ifelse presently-set-temp-unit = "Fahrenheit"
    [
      set is-colder-by-at-least precision (is-colder-by-at-least * 0.5) 1
    ]
    [
      set is-colder-by-at-least round (is-colder-by-at-least * 1.8)
    ]
  set presently-set-temp-unit temperature-unit
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
246
10
786
551
-1
-1
7.5
1
14
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
10
24
107
57
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
12
422
198
455
Show Rain with These Rules
calculate-results-of-rules\nexecute-rules
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
14
240
225
261
IF the square to the northwest...
12
0.0
1

SLIDER
10
267
223
300
is-colder-by-at-least
is-colder-by-at-least
0
max-temp-slider
2.0
temp-slider-tick
1
NIL
HORIZONTAL

TEXTBOX
14
321
112
339
AND IF the...
12
0.0
1

TEXTBOX
166
307
221
327
degrees F
11
0.0
1

SLIDER
12
347
223
380
air-moisture-is-at-least
air-moisture-is-at-least
0
10
2.0
1
1
NIL
HORIZONTAL

TEXTBOX
13
395
110
414
THEN IT RAINS.
12
0.0
1

TEXTBOX
21
216
178
234
------Rule Design------\n
11
0.0
1

CHOOSER
10
109
148
154
time-of-data-set
time-of-data-set
"7 am" "11 am" "3 pm" "7 pm" "11 pm"
0

BUTTON
11
65
74
98
Run
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
9
164
188
197
show-results-of-rules?
show-results-of-rules?
1
1
-1000

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

check
false
0
Polygon -7500403 true true 105 270 120 300 285 45 270 0
Polygon -7500403 true true 30 150 75 135 135 255 120 300

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
