Building a Galaga Clone - Step 02

Before we get into input and interaction, let's iterate our splash screen a litte bit with some graphics, fonts and color.

- Updates [`Galaga` module](./lib/galaga.rb)
- `resource_config` for the new font
- `Cedar::Draw::Scale`
- Breakdown drawing method:
  - `draw_start`
  - `draw_bonuses`
  - `draw_hud`
  - `draw_stars`
- `Cedar::Prng` `int` `choose`
- `Cedar::Draw::Image`

TODO:

- Link to Resource config docs in Cedar
- Link to Prng config docs in Cedar
- screenshot