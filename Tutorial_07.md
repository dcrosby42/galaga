Building a Galaga Clone - Step 07

Lifecycle of the game

1. Insert Coin
2. Ready Player One
3. Song / intro / ramp-in
4. Fight
5. Defeat enemy wave? next stage
6. Lose all lives? Game over!

ISSUES

- Enemy missiles need sound? (Do they have sound irl?)
- Enemy is able to kill reviving player by firing missile at death position at just the right moment before revival

STILL TO COME

- More types of enemy ships
- Enemy maneuvers - opening attack run, formation, sorties
- Stage markers, transition animation

OBSERVATIONS

Code is starting to become a little challenging to come back to.  (Took a couple months' break and it took an unsavory minute to get back to the point where I understood how to add the stage_opening behavior.) LOTS of nil-crashes and unexpected values.

Why? Let's dwell on some of the pain and time wasting that went on here.

- More than one place thought it was responsible for initializing stage_opening.line1.  Probably because line1 isn't a very worthy bit of state... it's half presentation.  It was being initialized immediately on transition, and also within the timing cases under :stage_opening, causing a visible blip because the transition-time initiazation was setting line1 as a string.
- Coupling: to keep the stars scrolling and the ship responsive in :stage_open screen, in update() under :stage_open you gotta remember to include calls to the relevant update funcs.
- Had to contrive a name and structure (state.stage_opening), repeat some timer logic, manage the display line text.  
- Coupling: the mirrored :stage_open clause in draw()
- Timing coupling: again, when deciding to tranition from one state to another (within the big switch block in update()), I first decided to try to "tidy" by having the stage_opening struct initialized-at-need within the :stage_open block. There's a continued temptation to do this.  Perhaps because I like the idea of the :stage_opening switch clause being a little box within which that state's lifecycle is largely handled. BUT! If one state transitions to the next state, the draw() function will immediately thereafter try to read the pertinent state... which won't be set because we haven't been back.  
  - The mistake here is trying to equate the case statement in update() to the flow chart.  (That was the intent, after all.)  But the reality is we've "split it vertically" by implementing the same case statement in draw(), and we shouldn't forget that because those draw() clauses all have DIRECT dependency on state set in update().

I actually solved this over two evenings... the first I got immediately frustrated and bummed that, for the one millionth time, I'd turned my back on a piece of simple game code for a few weeks and lost the ability to jump in quickly and keep moving forward.  This has always been the whole point, since 2001, of my game programming experiments.
BUT... I let my frustration obscure the fact that the galaga code is being written DELIBERATELY in a new ad-hoc way, growing organically on a few simple guidelines (on top of the newly-contrived but reasonably-boundaried Cedar framework, using only the "Elm modules" and resource loader)... the point is to find the point at which purely imperative, convenient coding becomes a problem and WHY.  


In short, I'm starting to actually achieve the point of the mision: Hit a wall.  (Can probably go further, but since I got genuinely irritated, I figured now's the time to write.)

While doing dishes I pondered whether or not a translation to ECS would in any way clear things up.

In some ways, at the actor level, surely: 
- Player and Enemy and EnemyFleet already begin to suffer from ad-hoc reinvention of update/draw functionality and duplicate important ideas like timers, presence checking, and esp. removal of "entities" from the world.
- Since all my types are currently ad-hoc, all the draw code is an ad-hoc match based on symbolic state and screen... when small, this is easy to create and maintain.  But it gets harder as time goes on, on a curve I think.

But I'm gonna wait until we solve some properly interesting bits like attack runs and enemy formations.  One of the walls I always hit early in ECS programming is the level ABOVE the individual entities: coherent groups.  Right now I can do `state.enemy_fleet.enemies.empty?` to discover if a fleet is defeated, and set `state.enemy_fleet.defeated = true`.  There exists a meta-entity called "fleet" and creating and using it is no harder than any other type of object.  It neatly encapsulates the relationship between the fleet and its ships, and provides a clear place to learn about it, update it etc.  (It also bears the downside of being a novelty, and so any update/draw system must know of it and integrate with it.  We have no abstraction around this currently, we simply sprinkle the calls to `update_enemy_fleet` and `draw_enemy_fleet` into the right places, which so far has worked ok.  One COULD abstract this by making an actual EnemyFleet class with #update and #draw instance methods on it.)

**AS OF THIS STEP_07, WE'VE REACHED AN INFLECTION POINT.** Or nearly so.

Soon we should declare the imperative approach unwieldy and fork off in two directions

1. A "Classical" approach, har har, in which we'll try to provide OO abstractions, and have things like Player class and Enemy class and EnemyFleet.  (And Timer, and Sprite etc.?)
2. An ECS approach

Not sure which to do first, I'm kinda itching to apply Cedar's neonascent ECS support.


--

Add credit 
PUSH START BUTTON
  (bonuses)
Start (1)
  Intro music
  1UP blinking
  title: PLAYER 1
  title: STAGE 1
  title: PLAYER 1\nSTAGE 1"
    ship appears, controllable, NO firing
  titles vanish, first wave dives in



GAME OVER (no sound/music)
  enemies still floating


#
```
    # instructions -> gameover
    # gameover -> highscores
    # highscores -> demo
    # (insert coint) -> start
    # (start button) -> fanfare
    # fanfare -> stage
    # stage:
    #   stagename
    #   battle
    #   boom
    #   ready
    #   win
    #   lose
    #

    # The Galactic Heroes
    #   5s

    # Galaga
    #   Score
    #     Figth
    #   Copy
    # Fanfare
    #   Music
    #   PLAYER 1
    #   (repl w) STAGE 1
    #   (above ^) PLAYER 1
    #     Ship appears, can strafe but not fire
    #       2-3 seconds
    #
    # Other stage beginnings:
    #   STAGE 2
    #   Stage badge counter increment
    #   (ship can move and fire)
    #   2ish seconds
    #   title vanishes
    #   First wave arrives

    # Game Over
    #   GAME OVER for a few seconds
    #   Results:  Shots fired, number of hits, hit-miss ratio %
```