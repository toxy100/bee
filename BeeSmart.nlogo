breed [sites site]
breed [scouts scout]

sites-own [quality discovered? scouts-on-site]
scouts-own [

  my-home
  next-task 
  beetimer                  ; specify how long a bee executes a task or how long it waits before excuting a task  
  target                    ; target hive 
  interest                  ; how interested a bee is in a hive   
  trips                     ; how many times a bee has visited a hive  
  
  initial-scout?                  ; true if it is an initial scout
  no-discovery?             ; true if it is an initial scout and didn't discover any hive on its initial trip
  on-site?                  ; true if it's inspecting a hive 
  piping?                   ; true if observed more bees on a hive than the quorum or observed other bees piping
  
  ;dance related variables
  dist-to-hive              ; the distance between the swarm and the hive that this bee is exploring 
  circle-switch             ; determines whether to make a left or a right semicircle after waggling 
  temp-x-dance              ; initial position for a dance
  temp-y-dance  
  
]

globals [
  color-list                ; colors for the hives, which keep hive colors, plot pens colors, and committed bees' colors consistent
  quality-list              ; quality of hives
  quorum
  
  ; visualization
  show-dance-path?
  scouts-visible?
]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;setup;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to setup
  clear-all
  setup-hives
  setup-bees
  set quorum 33    ; 33 is a sweet spot of accuracy-efficiency tread-off in this model, yielded from trial-and-error. 
                   ; After students have a basic understanding of the mechanism, a slider cound be added for students to explore the effects of this number on bees' decision making.
  set show-dance-path? true
  set scouts-visible? true
  reset-ticks
end

to setup-hives
  set color-list [97.9 94.5 57.5 63.8 17.6 14.9 27.5 25.1 117.9 114.4] 
  set quality-list [100 75 50 1 54 48 40 32 24 16]
  ask n-of hive-number patches with [distancexy 0 0 > 16 and abs pxcor < (max-pxcor - 2) and abs pycor < (max-pycor - 2)][
    sprout-sites 1 [set shape "box" set size 2 set color gray set discovered? false] 
  ]
  let i 0   ;assign quality and plot pens to hives
  repeat count sites [
    ask site i [set quality item i quality-list set label quality] 
    set-current-plot "on-site"  
    create-temporary-plot-pen word "site" i
    set-plot-pen-color item i color-list
    set-current-plot "committed"
    create-temporary-plot-pen word "target" i
    set-plot-pen-color item i color-list
    set i i + 1
  ]
end

to setup-bees
  create-scouts 100 [
    fd random-float 4     ;let bees spread out
    set my-home patch-here
    set shape "bee" 
    set color gray 
    set initial-scout? false 
    set target nobody 
    set circle-switch 1 
    set no-discovery? false 
    set on-site? false 
    set piping? false 
    set next-task "watch-dance"
    ]
  ask n-of (initial-percentage) scouts[set initial-scout? true set beetimer random 100]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;run-time;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to go
  if all? scouts [on-site?] and length remove-duplicates [target] of scouts = 1 [stop]; if all scouts are on site, and they all have the same target hive, stop.
  ask scouts [run next-task]
  plot-on-site-scouts
  tick
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;watch-dance;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to watch-dance
  if count scouts with [piping?] in-radius 3 > 0 [
    set target [target] of one-of scouts with [piping?] 
    set color [color] of target 
    set next-task "pipe"
    set beetimer 20 
    set piping? true
  ]
  move-around
  if no-discovery? [set initial-scout? false]
  if initial-scout? and beetimer < 0 [set next-task "discover" set beetimer initial-explore-time set initial-scout? false]
  if not initial-scout? [
    if beetimer < 0 [
      if count other scouts in-cone 3 60 > 0 [
        let observed one-of scouts in-cone 3 60
        if [next-task] of observed = "dance" [
          if random ((1 / [interest] of observed) * 1000) < 1 [
            set target [target] of observed 
            set color white 
            set next-task "re-inspect"
          ]
        ]
      ]
    ]
  ]
  set beetimer beetimer - 1
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;discover;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to discover
  ifelse beetimer < 0 [
    set next-task "go-home" set no-discovery? true
  ][
  ifelse count sites in-radius 3 > 0 [
    let temp-target one-of sites in-radius 3 
    ifelse not [discovered?] of temp-target [
      set target temp-target 
      ask target [set discovered? true set color item who color-list] 
      set interest [quality] of target 
      set color [color] of target 
      set next-task "discovery-inspect"
      set beetimer 100
    ][
    rt (random 60 - random 60) proceed set beetimer beetimer - 1
    ]
  ][
  rt (random 60 - random 60) proceed] set beetimer beetimer - 1
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;discovery-inspect;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to discovery-inspect
  ifelse beetimer < 0 [
    set next-task "go-home" set on-site? false set trips trips + 1
  ][
    if distance target > 2 [face target fd 1] 
    set on-site? true 
    if count scouts with [on-site? and target = [target] of myself] in-radius 3 > quorum [set next-task "go-home" set on-site? false set piping? true] 
    ifelse random 3 = 0 [hide-turtle][show-turtle] 
    set dist-to-hive distancexy 0 0 
    set beetimer beetimer - 1
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;go-home;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to go-home
  ifelse distance my-home < 1 [
    ifelse no-discovery? [
      set next-task "watch-dance" set no-discovery? false
    ][
      ifelse piping? [
        set next-task "pipe" set beetimer 20
      ][
      set next-task "dance" set beetimer 0
      ]
    ]
  ][
  face my-home proceed
  ]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;dance;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to dance
  ifelse count scouts with [piping?] in-radius 3 > 0 [
    pu set next-task "pipe" set beetimer 20 set target [target] of one-of scouts with [piping?] set color [color] of target set piping? true 
  ][
    if beetimer > interest - (trips - 1) * (15 + random 5) and interest > 0 [
      set next-task "re-inspect"
      pen-up 
      set interest interest - (15 + random 5) 
      set beetimer 25
    ]
    if beetimer > interest - (trips - 1) * (15 + random 5) and interest <= 0 [
      set next-task "watch-dance"
      set target nobody 
      set interest 0 
      set trips 0 
      set color gray 
      set beetimer 50
    ]
    if beetimer <=  interest - (trips - 1) * (15 + random 5)[
      ifelse interest <= 50 and random 100 < 43 [
        set next-task "re-inspect"
        set interest interest - (15 + random 5) 
        set beetimer 10
      ][
      ifelse show-dance-path? [pen-down][pen-up]
      repeat 2 [
        waggle
        make-semicircle]
        ]  
    ]
  set beetimer beetimer + 1 
  ]
end  

to make-semicircle
  let num-of-turns 1 / interest * 2600;calculate the size of the semicircle. 2600 and 5 (in pi / 5) are numbers selected by trial and error to make the dance path look good 
  let angle-per-turn 180 / num-of-turns
  let semicircle 0.5 * dist-to-hive * pi / 5
  if circle-switch = 1 [
    face target lt 90
    repeat num-of-turns [
      lt angle-per-turn fd (semicircle / 180 * angle-per-turn)
    ]
  ]
  if circle-switch = -1 [
    face target rt 90 
    repeat num-of-turns [
      rt angle-per-turn fd (semicircle / 180 * angle-per-turn)
    ]
  ]
  
  set circle-switch circle-switch * -1
  setxy temp-x-dance temp-y-dance 
end
    
to waggle
  face target 
  set temp-x-dance xcor set temp-y-dance ycor
  let waggle-switch 1;switch toggles between 1 and -1, which makes a bee dance a zigzag line by turning left and right
  lt 60 fd .4
  repeat (dist-to-hive - 2) / 2 [
    if waggle-switch = 1 [rt 120 fd .8]
    if waggle-switch = -1 [lt 120 fd .8]
    set waggle-switch waggle-switch * -1
  ]
  ifelse waggle-switch = -1 [lt 120 fd .4][rt 120 fd .4]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;re-inspect;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to re-inspect
  ifelse beetimer > 0 [
    set beetimer beetimer - 1
  ][
    pu
    ifelse distance target < 1 [
      if interest = 0 [set interest [quality] of target set color [color] of target] 
      set next-task "discovery-inspect"
      set beetimer 50
    ][
      proceed
      face target
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;pipe;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to pipe
  move-around
  if count scouts with [piping?] in-radius 5 = count scouts in-radius 5 [set beetimer beetimer - 1] 
  if beetimer < 0 [set next-task "take-off"] 
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;take-off;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to take-off
  ifelse distance target > 1 [face target fd 1][set on-site? true]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;utilities;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to proceed
  rt (random 20 - random 20)
  if not can-move? 1 [ rt 180 ]
  fd 1
end

to move-around
  rt (random 60 - random 60) fd random-float .1
  if distancexy 0 0 > 4 [facexy 0 0 fd 1]
end

to plot-on-site-scouts
  let i 0
  repeat count sites [
    set-current-plot "on-site"
    set-current-plot-pen word "site" i 
    plot count scouts with [on-site? and target = site i]

    set-current-plot "committed"
    set-current-plot-pen word "target" i 
    plot count scouts with [target = site i]
    
    set i i + 1
  ]
end

to show-hide-dance-path
  if show-dance-path? [
    clear-drawing
  ]
  set show-dance-path? not show-dance-path?
end

to show-hide-scouts
  ifelse scouts-visible? [
    ask scouts [ht]
  ]
  [
    ask scouts [st]
  ]
  set scouts-visible? not scouts-visible?
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
935
580
32
24
11.0
1
10
1
1
1
0
0
0
1
-32
32
-24
24
0
0
1
ticks
24.0

BUTTON
5
145
201
185
SETUP
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
5
200
200
240
GO
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
5
10
201
43
hive-number
hive-number
4
10
10
1
1
NIL
HORIZONTAL

SLIDER
5
55
201
88
initial-percentage
initial-percentage
5
25
12
1
1
NIL
HORIZONTAL

PLOT
5
415
201
579
piping-scouts
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count scouts with [piping?]"

PLOT
942
222
1252
426
on-site
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS

PLOT
942
426
1252
579
working v.s. watching
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"watching bees" 1.0 0 -1398087 true "" "plot count scouts with [next-task = \"watch-dance\"]"
"dancing bees" 1.0 0 -7025278 true "" "plot count scouts with [next-task = \"dance\"]"

PLOT
942
10
1252
222
committed
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS

SLIDER
5
100
201
133
initial-explore-time
initial-explore-time
100
300
200
10
1
NIL
HORIZONTAL

BUTTON
5
255
200
295
Show/Hide Dance Path
show-hide-dance-path
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
5
305
200
345
Show/Hide Scouts
show-hide-scouts
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

This model shows the swarm intelligence of honeybees during their hive-finding process: A swarm of tens of thousands of honeybees can accurately choose the best new hive site available among dozens of potential choices. The consequence of this decision is a life-or-death matter for the bees, and the way in which the bees reach an agreement is through a “democratic debate” among thousands of scout bees. 

The mechanism of this model is based on the book Honeybee Democracy (Seeley, 2010) with some modification and simplifications. Notably, this model shows only the scout bees instead of all the bees in a swarm. Other non-scout bees do not directly participate in the decision-making. They simply follow the scouts to the new hive when a decision is made. The number of scouts is usually 3% to 5% of the swarm's population. Leaving out the non-scouts reduces the computational load and makes this model visually clearer.


## HOW IT WORKS

Unlike human beings, individual honeybees have very limited sensory and cognitive abilities. It is not possible for them to shop around, compare, and pick the best site. Even if it is, it’s still hard to know whose opinion to follow, given that there are thousands of them. Instead, several complex systems mechanisms are at work during this self-organizing process, including positive feedback and negative feedback:

Some of the scouts have to individually explore the surrounding environment and present their initial findings to the swarm through waggle dances. Then the swarm needs to aggregate these findings by amplify good choices and eliminate bad ones. For example, scouts dance longer and more enthusiastically for hive sites with higher quality—spacious, facing south, having a small entrance, and so forth, which increases the swarm’s likelihood of survival from predators and weather. These dances are more likely to be seen and followed by other scouts, who would in turn dance for these sites if they also find the sites desirable after exploring them. Such relay forms a positive feedback loop, which keeps amplifying more desirable sites until all advocators converge on dancing for the single site with the highest quality. 


## HOW TO USE IT

Adjust the sliders to choose how many hive sites and how many scout bees to put into the model. You will also need to specify what percentage of the scouts are pioneer scouts, who would fly out from the swarm and discover potential hive sites. 

Click SETUP and then GO to run the model. When bees are dancing, you can choose to show or to hide the waggle dance paths by toggling the show-dance-path? switch. You can also hide the bees if they block your view of the dance paths.

Set a Quorum--the number of advocates required for a certain site to win.

## THINGS TO NOTICE

Observe how information about multiple sites is brought to the swarm at the center and how preference of the swarm changes over time. Notice whether the timing of discovering the best hive site affects the swarm’s decision. 

## THINGS TO TRY

Right click any scout and choose “Watch” from the right-click menu. A halo would appear around the scout to help you keep track of its movement.

Set initial-percentage and/or initial-explore-time to different values. Observe how they affect the dynamic of the process.

Use the speed slider at the top of the model to slow down the model and observe the waggle dances. 

Use "Control +" or "Command +" to zoom in and see the colors of the bees.

## EXTENDING THE MODEL

This model shows the honeybees’ hive-finding phenomenon as a continuous process. However, in reality, this process may last through a few days. Bees do rest over night. Weather conditions may also affect this process. Adding these factors to the model can make it more accurately represent the phenomenon in the real world.

Site qualities cannot be controlled from the interface. Some input interface elements can be added to enable users to specify the quality of each hive. 

## NETLOGO FEATURES

This model is essentially a state machine. Bees behave differently at different states. Command tasks are heavily used in this model to simplify the shifts between states. 

The pens in the plots are dynamically generated temporary plot pens, which match the number of hive sites that are determined by users. 

The dance patterns (when show-dance-path? is set to true) are dynamically generated, which show the direction, distance, and quality of the hive advertised.

## RELATED MODELS
Wilensky, U. (1997). NetLogo Ants model. http://ccl.northwestern.edu/netlogo/models/Ants. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL. 


BEEHAVE NetLogo model simulates the development of a honeybee colony and agent-based foraging of nectar and pollen in a realistic landscape. BEEHAVE is developed by Professor Juliet Osborne and colleagues, and can be downloaded at http://beehave-model.net

## CREDITS AND REFERENCES
Seeley, T. D. 2010. Honeybee democracy. Princeton, NJ: Princeton University Press.

Wilensky, U. 1999. NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University. Evanston, IL.
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

bee
true
0
Polygon -1184463 true false 152 149 77 163 67 195 67 211 74 234 85 252 100 264 116 276 134 286 151 300 167 285 182 278 206 260 220 242 226 218 226 195 222 166
Polygon -16777216 true false 150 149 128 151 114 151 98 145 80 122 80 103 81 83 95 67 117 58 141 54 151 53 177 55 195 66 207 82 211 94 211 116 204 139 189 149 171 152
Polygon -7500403 true true 151 54 119 59 96 60 81 50 78 39 87 25 103 18 115 23 121 13 150 1 180 14 189 23 197 17 210 19 222 30 222 44 212 57 192 58
Polygon -16777216 true false 70 185 74 171 223 172 224 186
Polygon -16777216 true false 67 211 71 226 224 226 225 211 67 211
Polygon -16777216 true false 91 257 106 269 195 269 211 255
Line -1 false 144 100 70 87
Line -1 false 70 87 45 87
Line -1 false 45 86 26 97
Line -1 false 26 96 22 115
Line -1 false 22 115 25 130
Line -1 false 26 131 37 141
Line -1 false 37 141 55 144
Line -1 false 55 143 143 101
Line -1 false 141 100 227 138
Line -1 false 227 138 241 137
Line -1 false 241 137 249 129
Line -1 false 249 129 254 110
Line -1 false 253 108 248 97
Line -1 false 249 95 235 82
Line -1 false 235 82 144 100

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
NetLogo 5.1.0
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
1
@#$#@#$#@
