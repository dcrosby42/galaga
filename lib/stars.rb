module Galaga
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

  def new_stars(star_seed:)
    {
      bounds: { left: 0, top: HeaderHeight, right: Width, bottom: Height - FooterHeight },
      t: 0,
      loc: 0,
      speed: -60,
      star_seed: star_seed,
      sparse: 2, # star sparsity (every n lines should be drawn)
      blink_rate: 1.5,
      blink_chance: 0.4,
      debug: false,
    }
  end

  def update_stars(stars, speed, input)
    stars.t += input.time.dt
    stars.loc -= speed * input.time.dt
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
      (page_height / stars.sparse.to_f).to_i.times do |i|
        y = page_start + (stars.sparse * i)
        x = rng.int(stars.bounds.left, stars.bounds.right)
        color = rng.choose(StarColors)
        if rng.chance(stars.blink_chance)
          if (rng.float + (stars.t * stars.blink_rate)).to_i.even?
            color = nil
          end
        end

        # For the sake of our procedural stars, we must always calc them all per page.
        # But we need to clip them (avoid drawing out-of-bounds stars,
        # preserving the score header and status footer):
        if y > stars.bounds.top and y < stars.bounds.bottom
          g << star(x, y, color) if color
        end
      end

      if stars.debug
        # Draw box around this page and label it:
        x = stars.bounds.left + 1
        y = page_start
        w = stars.bounds.right - x - 1
        h = page_height
        color = Gosu::Color::WHITE
        g << Draw::RectOutline.new(x: x, y: y, w: w, h: h, color: color)
        g << Draw::Label.new(x: x, y: page_start, text: "pg #{pg}, rng: #{seed}", color: color)
      end
    end
    if stars.debug
      g << Draw::Label.new(x: 0, y: 20, text: "stars @ #{stars.loc}")
    end
  end

  def star(x, y, color)
    Draw::Rect.new(x: x, y: y, w: 1, h: 1, color: color, z: Layer.stars)
  end
end
