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
      screen: :battle,
      seed_rng: seed_rng,
      stars: {
        bounds: { left: 0, top: 20, right: Width, bottom: Height - 15 },
        loc: 0,
        speed: -40,
        star_seed: seed_rng.gen_seed,
        sparse: 2, # star sparsity (every n lines should be drawn)
        blink_rate: 1.5,
        blink_chance: 0.16,
        debug: false,
      },
      credits: 0,
      high_score: 20000,
      player: 0,
      players: [open_struct(
        num: 1,
        score: 0,
        pos: { x: 100, y: Height - 30 },
      )],
    })
    state
  end

  def update(state, input, res)
    update_stars(state.stars, input)

    case state.screen
    when :battle
      update_player(state.players[state.player], input)
    end

    state
  end

  def update_stars(stars, input)
    if input.keyboard.pressed?(Gosu::KB_1)
      stars.debug = !stars.debug
    end
    stars.loc += stars.speed * input.time.dt
    stars.t = input.time.t
  end

  def update_player(player, input)
    if input.keyboard.down?(Gosu::KB_LEFT)
      player.pos.x -= 2
    elsif input.keyboard.down?(Gosu::KB_RIGHT)
      player.pos.x += 2
    end
  end

  def draw(state, output, res)
    output.graphics << Draw::Scale.new(Scale) do |g|
      draw_stars g, state.stars

      case state.screen
      when :home_bonuses
        draw_start_info g
        draw_bonuses g
      when :battle
        draw_player g, state.players[state.player]
      end

      draw_hud g, state
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
    Draw::Rect.new(x: x, y: y, w: 1, h: 1, color: color, z: 0)
  end

  def draw_start_info(g)
    g << Draw::Label.new(
      text: "PUSH START BUTTON",
      x: 40, y: 100, z: 100,
      color: Gosu::Color.new(0, 228, 202),
      font: "retrogame",
    )
  end

  def draw_hud(g, state)
    player = state.players[state.player]
    g << Draw::Label.new(text: "  #{player.num}UP     HIGH SCORE", x: 0, y: 0, z: 100, color: Gosu::Color::RED, font: "retrogame")
    g << Draw::Label.new(text: "  #{player.score.to_s.ljust(10, " ")}#{state.high_score}   ", x: 0, y: 10, z: 100, color: Gosu::Color::WHITE, font: "retrogame")

    g << Draw::Label.new(text: " CREDITS #{state.credits}", x: 0, y: 280, color: Gosu::Color::WHITE, font: "retrogame")
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

  def draw_player(g, player)
    g << Draw::Image.new(path: "fighter_01.png", x: player.pos.x, y: player.pos.y, z: 50)
  end
end
