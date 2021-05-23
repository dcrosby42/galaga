Building a Galaga Clone - Step 07

Lifecycle of the game

1. Insert Coin
2. Ready Player One
3. Song / intro / ramp-in
4. Fight
5. Win? next stage
6. Lose? Game over!

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