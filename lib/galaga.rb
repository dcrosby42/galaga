require "geom"

module Galaga
  extend self
  include Cedar
  extend Cedar::Helpers
  include Geom
  extend Geom

  Fire1Button = Gosu::KB_Q
  LeftButton = Gosu::KB_LEFT
  RightButton = Gosu::KB_RIGHT

  DebugStarsToggle = Gosu::KB_F1
  DebugPlayerToggle = Gosu::KB_F2
  DebugEnemyToggle = Gosu::KB_F3
  PauseToggle = Gosu::KB_P

  # Game dimensions
  Scale = 3
  Width = 224
  Height = 288

  HeaderHeight = 20
  FooterHeight = 15

  StarSpeed = 60
  FighterSpeed = 120
  FighterCruiseAccel = 120
  MissileSpeed = 350
  MissileFireLimit = 2

  FontWidth = 8.5 # "retrogame" font
  FontHeight = 10 # "retrogame" font

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
end

require "player"
require "enemies"
require "stars"

module Galaga
  Cedar::Sound.on = false

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
        center_x: 0.5,
        center_y: 0.5,
      },
      {
        type: "grid_sheet_sprite",
        name: "player_splode",
        image: "fighter_boom.png",
        grid: {
          w: 32, h: 32,
          count: 4,
        },
        center_x: 0.5,
        center_y: 0.5,
      },
      {
        type: "sprite_animation",
        name: "enemy_splode",
        sprite: "enemy_splode",
        fps: 24,
      },
      {
        type: "sprite_animation",
        name: "player_splode",
        sprite: "player_splode",
        fps: 5,
      },
      {
        type: "sound",
        name: "pew",
        sound: "fire.wav",
        volume: 0.5,
      },
      {
        type: "sound",
        name: "boom",
        sound: "boom.wav",
        volume: 0.5,
      },
      {
        type: "sound",
        name: "waka",
        sound: "enemy_hit_01.wav",
        volume: 0.5,
      },
    ]
  end

  def new_state
    seed_rng = Cedar::Prng.new(1122334455)
    state = open_struct({
      screen: :start,
      seed_rng: seed_rng,
      paused: false,
      stars: new_stars(star_seed: seed_rng.gen_seed),
      credits: 0,
      high_score: 20000,
      player: new_player,
      enemy_fleet: new_enemy_fleet,
      hud: {
        player_blink_state: true,
        player_name: "",
        player_score: 0,
        high_score: 0,
        credits: 0,
        show_credits: true,
      },
    })
    state
  end

  def update(state, input, res)
    if input.keyboard.pressed?(PauseToggle)
      state.paused = !state.paused
    end
    if input.keyboard.pressed?(DebugPlayerToggle)
      state.player.debug = !state.player.debug
    end
    if input.keyboard.pressed?(DebugStarsToggle)
      state.stars.debug = !state.stars.debug
    end
    if input.keyboard.pressed?(DebugEnemyToggle)
      state.enemy_fleet.debug = !state.enemy_fleet.debug
    end
    if input.keyboard.pressed?(Gosu::KB_5)
      state.screen = :start
    end
    if input.keyboard.pressed?(Gosu::KB_1)
      state.screen = :battle
    end

    return state if state.paused

    case state.screen
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

    when :start
      update_stars(state.stars, StarSpeed, input)
    when :battle
      update_collisions state
      update_player state.player, input
      update_enemy_fleet state.enemy_fleet, input
      update_stars(state.stars, state.player.cruising.speed, input)
    end

    update_hud(state, input)

    state
  end

  def update_collisions(state)
    state.enemy_fleet.enemies.each do |enemy|
      enemy.collisions.clear
    end
    state.player.collisions.clear

    # Player missiles v enemies
    state.player.missiles.each do |missile|
      state.enemy_fleet.enemies.each do |enemy|
        if enemy.mode == :active and point_in_rect(missile.pos, enemy.hit_box)
          # HIT!
          enemy.collisions << missile
          missile.collisions << enemy
          state.player.score += 80
        end
      end
    end

    # Enemies v player
    state.enemy_fleet.enemies.each do |enemy|
      if enemy.mode == :active
        if rect_overlap(enemy.hit_box, state.player.hit_box)
          if enemy.collisions.length == 0 && state.player.collisions.length == 0
            enemy.collisions << state.player
            state.player.collisions << enemy
          end
        end
      end
    end
  end

  def update_hud(state, input)
    hud = state.hud
    hud.player_name = "#{state.player.num}UP"
    hud.player_score = state.player.score
    hud.high_score = state.high_score
    hud.credits = state.credits
    if state.screen == :battle
      hud.player_blink_state = (2 * input.time.t).floor.even?
    else
      hud.player_blink_state = true
    end
  end

  def draw(state, output, res)
    output.graphics << Draw::Scale.new(Scale) do |g|
      draw_stars g, state.stars

      case state.screen
      when :start
        draw_start_info g
        draw_bonuses g
      when :battle
        draw_player g, state.player

        draw_enemy_fleet g, state.enemy_fleet
      end

      draw_hud g, state.hud
    end
  end

  def draw_start_info(g)
    g << Draw::Label.new(
      text: "PUSH START BUTTON",
      x: 40, y: 100, z: Layer.text,
      color: Gosu::Color.new(0, 228, 202),
      font: "retrogame",
    )
  end

  Red = Gosu::Color::RED
  White = Gosu::Color::WHITE

  def draw_hud(g, hud)

    # (helper)
    x = 0
    y = 0
    z = Layer.text
    color = Red
    draw_text = lambda do |text|
      g << Draw::Label.new(text: text, x: x, y: y, z: z, color: color, font: "retrogame")
    end

    # player score
    x = 2 * FontWidth
    y = 0
    color = Red
    draw_text["#{hud.player_name}"] if hud.player_blink_state
    y = FontHeight
    color = White
    draw_text[hud.player_score.to_s.ljust(10, " ")]

    # High Score
    x = 10 * FontWidth
    y = 0
    color = Red
    draw_text["HIGH SCORE"]
    y = FontHeight
    x += 2 * FontWidth
    color = White
    draw_text["#{hud.high_score}"]

    # Credits
    y = 28 * FontHeight
    x = FontWidth
    draw_text["CREDITS #{hud.credits}"]
  end

  def draw_bonuses(g)
    g << Draw::Label.new(text: "1ST BONUS FOR 20000 PTS", x: 25, y: 130, z: Layer.text, color: Gosu::Color::YELLOW, font: "retrogame")
    g << Draw::Label.new(text: "2ND BONUS FOR 70000 PTS", x: 25, y: 150, z: Layer.text, color: Gosu::Color::YELLOW, font: "retrogame")
    g << Draw::Label.new(text: "AND FOR EVERY 70000 PTS", x: 25, y: 170, z: Layer.text, color: Gosu::Color::YELLOW, font: "retrogame")

    g << Draw::Image.new(path: "fighter_01.png", x: 5, y: 125, z: Layer.text)
    g << Draw::Image.new(path: "fighter_01.png", x: 5, y: 145, z: Layer.text)
    g << Draw::Image.new(path: "fighter_01.png", x: 5, y: 165, z: Layer.text)

    g << Draw::Label.new(text: "\u00A9 1981 NAMCO LTD.", x: 40, y: 210, z: Layer.text, color: Gosu::Color::WHITE, font: "retrogame")
  end
end
