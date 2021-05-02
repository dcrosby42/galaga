Building a Galaga Clone - Step 04

New stuff:
- A ship you can control! 
- Fire missiles! 
- With pew pew sounds!
- Draw the score, credits etc. using actual game state 

## Changes

- New game state like `credits`, `high_score`, `player`, `screen`
- Updates to `draw_hud` to use new game state
- `update` and `draw` now branch on `state.screen` being either `:battle` or `:home_bonuses` (currently defaulted to :battle)
- New `update_player`, `draw_player` methods to handle fighter motion and missile fire control
- Introduced first `Cedar::Sound::Effect` "drawing" object to play missile firing sounds.

New game state:
```ruby
credits: 0,
high_score: 20000,
player: 0,
players: [open_struct(
  score: 0,
)],
```


TODO:
  - screenshot / animated gif
