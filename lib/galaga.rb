module Galaga
  include Cedar
  extend Cedar::Helpers
end

module Galaga
  extend self

  Fire1Button = Gosu::KB_Q
  LeftButton = Gosu::KB_LEFT
  RightButton = Gosu::KB_RIGHT

  DebugStarsToggle = Gosu::KB_1
  DebugPlayerToggle = Gosu::KB_2
  DebugEnemyToggle = Gosu::KB_3
  PauseToggle = Gosu::KB_P

  # Game dimensions
  Scale = 3
  Width = 224
  Height = 288

  HeaderHeight = 20
  FooterHeight = 15

  FighterSpeed = 120
  MissileSpeed = 300
  MissileFireLimit = 2

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
  Layer = open_struct(
    stars: 0,
    enemy_fire: 99,
    enemy: 100,
    enemy_debug: 101,
    player_missiles: 109,
    player: 110,
    player_debug: 111,
    text: 150,
  )

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
      {
        type: "grid_sheet_sprite",
        name: "enemy1",
        image: "enemy_01.png",
        center_x: 0.5,
        center_y: 0.5,
        grid: {
          w: 16, h: 16,
          count: 8,
        },
      },
      {
        type: "grid_sheet_sprite",
        name: "enemy_splode",
        image: "enemy_splode.png",
        grid: {
          w: 32, h: 32,
          count: 5,
        },
      },
      {
        type: "sprite_animation",
        name: "enemy_splode",
        sprite: "enemy_splode",
        fps: 24,
      },
    ]
  end

  def new_state
    seed_rng = Cedar::Prng.new(1122334455)
    state = open_struct({
      screen: :battle,
      seed_rng: seed_rng,
      paused: false,
      stars: {
        bounds: { left: 0, top: HeaderHeight, right: Width, bottom: Height - FooterHeight },
        t: 0,
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
        missiles_fired: 0,
        missiles: [],
        debug: true,
      )],
      enemy_fleet: {
        t: 0.0,
        enemies: [
          open_struct(
            sprite: "enemy1",
            pos: { x: 50, y: HeaderHeight + 10 },
          ),
          open_struct(
            sprite: "enemy1",
            pos: { x: 66, y: HeaderHeight + 10 },
          ),
        ],
        debug: true,
      },
    })
    state
  end

  def update(state, input, res)
    if input.keyboard.pressed?(PauseToggle)
      state.paused = !state.paused
    end
    if input.keyboard.pressed?(DebugPlayerToggle)
      pl = state.players[state.player]
      pl.debug = !pl.debug
    end
    if input.keyboard.pressed?(DebugStarsToggle)
      state.stars.debug = !state.stars.debug
    end
    if input.keyboard.pressed?(DebugEnemyToggle)
      state.enemy_fleet.debug = !state.enemy_fleet.debug
    end

    return state if state.paused

    update_stars(state.stars, input)

    case state.screen
    when :battle
      update_player state.players[state.player], input
      update_enemy_fleet state.enemy_fleet, input
    end

    state
  end

  def update_stars(stars, input)
    stars.loc += stars.speed * input.time.dt
    stars.t += input.time.dt
  end

  def update_player(player, input)
    # Left/Right motion
    if input.keyboard.down?(LeftButton)
      player.pos.x -= FighterSpeed * input.time.dt
    elsif input.keyboard.down?(RightButton)
      player.pos.x += FighterSpeed * input.time.dt
    end
    # contrain motion:
    if player.pos.x > Width - 16
      player.pos.x = Width - 16
    elsif player.pos.x < 0
      player.pos.x = 0
    end

    if input.keyboard.pressed?(Fire1Button)
      if player.missiles.length < MissileFireLimit
        # Fire missile
        player.missiles_fired += 1
        missile = open_struct(
          id: player.missiles_fired,
          pos: { x: player.pos.x + 6, y: player.pos.y },
          vel: { x: 0, y: -MissileSpeed },
        )
        player.missiles << missile
      end
    end

    update_missiles(player.missiles, input)
  end

  def update_missiles(missiles, input)
    removals = nil
    missiles.each.with_index do |missile, i|
      missile.pos.y += missile.vel.y * input.time.dt
      missile.pos.x += missile.vel.x * input.time.dt
      if missile.pos.y < HeaderHeight || missile.pos.y > Height
        removals ||= []
        removals << i
      end
    end
    removals && removals.each do |i|
      missiles.delete_at i
    end
  end

  def update_enemy_fleet(fleet, input)
    fleet.t += input.time.dt

    fleet.enemies.each do |enemy|
      # enemy.t = fleet.t
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

        draw_enemy_fleet g, state.enemy_fleet
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
    Draw::Rect.new(x: x, y: y, w: 1, h: 1, color: color, z: Layer.stars)
  end

  def draw_start_info(g)
    g << Draw::Label.new(
      text: "PUSH START BUTTON",
      x: 40, y: 100, z: Layer.text,
      color: Gosu::Color.new(0, 228, 202),
      font: "retrogame",
    )
  end

  def draw_hud(g, state)
    player = state.players[state.player]
    g << Draw::Label.new(text: "  #{player.num}UP     HIGH SCORE", x: 0, y: 0, z: Layer.text, color: Gosu::Color::RED, font: "retrogame")
    g << Draw::Label.new(text: "  #{player.score.to_s.ljust(10, " ")}#{state.high_score}   ", x: 0, y: 10, z: Layer.text, color: Gosu::Color::WHITE, font: "retrogame")

    g << Draw::Label.new(text: " CREDITS #{state.credits}", x: 0, y: 280, color: Gosu::Color::WHITE, font: "retrogame")
  end

  def draw_bonuses(g)
    g << Draw::Label.new(text: "1ST BONUS FOR 20000 PTS", x: 25, y: 130, z: Layer.text, color: Gosu::Color::YELLOW, font: "retrogame")
    g << Draw::Label.new(text: "2ND BONUS FOR 70000 PTS", x: 25, y: 150, z: Layer.text, color: Gosu::Color::YELLOW, font: "retrogame")
    g << Draw::Label.new(text: "AND FOR EVERY 70000 PTS", x: 25, y: 170, z: Layer.text, color: Gosu::Color::YELLOW, font: "retrogame")

    g << Draw::Label.new(text: "\u00A9 1981 NAMCO LTD.", x: 40, y: 210, z: Layer.text, color: Gosu::Color::WHITE, font: "retrogame")

    g << Draw::Image.new(path: "fighter_01.png", x: 5, y: 125, z: Layer.text)
    g << Draw::Image.new(path: "fighter_01.png", x: 5, y: 145, z: Layer.text)
    g << Draw::Image.new(path: "fighter_01.png", x: 5, y: 165, z: Layer.text)
  end

  def draw_player(g, player)
    g << Draw::Image.new(path: "fighter_01.png", x: player.pos.x, y: player.pos.y, z: Layer.player)

    if player.debug
      x = player.pos.x
      y = player.pos.y
      z = Layer.player_debug
      c = Gosu::Color::YELLOW
      g << Draw::Rect.new(x: x, y: y, z: z, color: c)
      # g << Draw::RectOutline.new(x: x - 5, y: y - 5, w: 11, h: 10, z: z, color: c)
      g << Draw::RectOutline.new(x: x, y: y, w: 15, h: 15, z: z, color: c)
    end

    player.missiles.each do |missile|
      g << Draw::Image.new(
        path: "missile_01.png",
        x: missile.pos.x, y: missile.pos.y, z: Layer.player_missiles,
        center_x: 0.5, center_y: 0,
      )
      # g << Sound::Effect.new(path: "fire.wav", id: missile.id)
      if player.debug
        x = missile.pos.x
        y = missile.pos.y
        z = Layer.player_debug
        c = Gosu::Color::YELLOW
        # g << Draw::Rect.new(x: x - 0.5, y: y, z: z, w: 1, h: 2, color: c)
        g << Draw::RectOutline.new(x: x - 1, y: y, w: 3, h: 3, z: z, color: c)
      end
    end
  end

  def draw_enemy_fleet(g, fleet)
    fleet.enemies.each do |enemy|
      draw_enemy g, fleet, enemy
    end
    # DELETEME:
    g << Draw::Animation.new(name: "enemy_splode", t: fleet.t, x: 0, y: 0)
  end

  def draw_enemy(g, fleet, enemy)
    flap_rate = 1.0
    fr = 6 + ((fleet.t * flap_rate) % 2) # 6 is the first of two upright flap frames
    g << Draw::Sprite.new(name: enemy.sprite, x: enemy.pos.x, y: enemy.pos.y, z: Layer.enemy, frame: fr)

    if fleet.debug
      x = enemy.pos.x
      y = enemy.pos.y
      z = Layer.enemy_debug
      c = Gosu::Color::CYAN
      g << Draw::Rect.new(x: x, y: y, z: z, color: c)
      g << Draw::RectOutline.new(x: x - 5, y: y - 5, w: 11, h: 10, z: z, color: c)
    end
  end
end
