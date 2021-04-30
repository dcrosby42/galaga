Building a Galaga Clone - Step 03

Procedural star field with infinite scroll and random blinking.

- Update `draw_starts` with the idea of "star pages"
- New star simulation state:
  - `bounds`, `loc`, `speed`
  - `star_seed` - used as in `Prng.gen_seed(star_seed, page_number)` to get a per-star-page RNG for randomizing star locations, colors, blink probability and blink timing offset.
  - params to control spacing and blinking

TODO:
  - screenshot / animated gif
