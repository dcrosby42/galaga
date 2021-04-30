module Galaga
  include Cedar
  extend Cedar::Helpers
end

module Galaga
  extend self

  Scale = 2
  Width = 224
  Height = 288

  StarColors = [
    Gosu::Color::GRAY,
    Gosu::Color::WHITE,
    Gosu::Color::AQUA,
    Gosu::Color::RED,
    Gosu::Color::GREEN,
    Gosu::Color::BLUE,
    Gosu::Color::YELLOW,
    Gosu::Color::FUCHSIA,
    Gosu::Color::CYAN,
  ]

  def resource_config
    [
      {
        type: "font",
        name: "retrogame",
        font: "narpassword.ttf",
        size: 10,
      },
      {
        type: "font",
        name: "default",
        size: 10,
      },
    ]
  end

  def new_state
    seed_rng = Cedar::Prng.new(1122334455)
    state = open_struct({
      seed_rng: seed_rng,
      stars: {
        bounds: { left: 0, top: 20, right: Width, bottom: Height - 15 },
        loc: 0,
        speed: -40,
        star_seed: seed_rng.gen_seed,
        sparse: 2, # star sparsity (every n lines should be drawn)
        blink_rate: 1.5,
        blink_chance: 0.16,
      },
    })
    state
  end

  def update(state, input, res)
    update_stars(state.stars, input)
    state
  end

  def update_stars(stars, input)
    stars.loc += stars.speed * input.time.dt
    stars.t = input.time.t
  end

  def draw(state, output, res)
    output.graphics << Draw::Scale.new(Scale) do |g|
      draw_stars g, state.stars
      draw_start_info g
      draw_bonuses g
      draw_hud g
    end
  end

  def draw_stars(g, stars)
    page_height = stars.bounds.bottom - stars.bounds.top
    # The "infinite scrolling stars" are conceptually chunked into "pages", each page
    # is 1 screen tall.  Based on the current stars.loc value, the view intersects
    # (at most) two of these pages.  Let's compute those page numbers:

    # If stars.log is retreating (negative speed, moving up) the stars scroll DOWN.
    # The only two pages we could possibly see would be the "previous" page pn0, then
    # the "current" page pn1.
    pn0 = (1.0 * (stars.loc - page_height) / page_height).to_i
    pn1 = (1.0 * stars.loc / page_height).to_i

    # For each page, we need to draw its stars:
    (pn0..pn1).each do |pg|
      # every star page has a deterministic RNG that we use to compute x locations, colors
      # and blink delay on a per-star basis.
      # First, get ahold of the rng for the current page:
      #puts((pg % 5) + 1)
      seed, _ = Cedar::Prng.gen_seed(stars.star_seed, (pg % 5) + 1)
      rng = Cedar::Prng.new(seed)
      # Iterate downward, drawing the stars:
      page_start = stars.bounds.top + (pg * page_height) - stars.loc # y pos of the top of this star page
      (page_height / stars.sparse).times do |i|
        y = page_start + (stars.sparse * i)
        x = rng.int(stars.bounds.left, stars.bounds.right)
        color = rng.choose(StarColors)
        if rng.chance(stars.blink_chance)
          if (rng.float + (stars.t * stars.blink_rate)).to_i.even?
            color = nil
          end
        end

        # For the sake of our procedural stars, we must always calc them all per page.
        # But we need to clip them (avoid drawing out-of-bounds stars):
        if y > stars.bounds.top and y < stars.bounds.bottom
          g << star(x, y, color) if color
        end
      end
    end
  end

  def star(x, y, color)
    Draw::Rect.new(x: x, y: y, w: 1, h: 1, color: color)
  end

  def draw_start_info(g)
    g << Draw::Label.new(
      text: "PUSH START BUTTON",
      x: 40, y: 100, z: 100,
      color: Gosu::Color.new(0, 228, 202),
      font: "retrogame",
    )
  end

  def draw_hud(g)
    g << Draw::Label.new(text: "  1UP     HIGH SCORE", x: 0, y: 0, z: 100, color: Gosu::Color::RED, font: "retrogame")
    g << Draw::Label.new(text: "  4010      20000   ", x: 0, y: 10, z: 100, color: Gosu::Color::WHITE, font: "retrogame")

    g << Draw::Label.new(text: " CREDITS 1", x: 0, y: 280, color: Gosu::Color::WHITE, font: "retrogame")
  end

  def draw_bonuses(g)
    g << Draw::Label.new(text: "1ST BONUS FOR 20000 PTS", x: 25, y: 130, z: 100, color: Gosu::Color::YELLOW, font: "retrogame")
    g << Draw::Label.new(text: "2ND BONUS FOR 70000 PTS", x: 25, y: 150, z: 100, color: Gosu::Color::YELLOW, font: "retrogame")
    g << Draw::Label.new(text: "AND FOR EVERY 70000 PTS", x: 25, y: 170, z: 100, color: Gosu::Color::YELLOW, font: "retrogame")

    g << Draw::Label.new(text: "\u00A9 1981 NAMCO LTD.", x: 40, y: 210, z: 100, color: Gosu::Color::WHITE, font: "retrogame")

    g << Draw::Image.new(path: "fighter_01.png", x: 5, y: 125)
    g << Draw::Image.new(path: "fighter_01.png", x: 5, y: 145)
    g << Draw::Image.new(path: "fighter_01.png", x: 5, y: 165)
  end
end
