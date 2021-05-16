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
        fps: 24,
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
      screen: :battle,
      seed_rng: seed_rng,
      paused: false,
      stars: new_stars(star_seed: seed_rng.gen_seed),
      credits: 0,
      high_score: 20000,
      player: new_player,
      enemy_fleet: new_enemy_fleet,
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

    return state if state.paused

    update_stars(state.stars, input)

    case state.screen
    when :battle
      update_collisions state
      update_player state.player, input
      update_enemy_fleet state.enemy_fleet, input
    end

    state
  end

  def update_collisions(state)
    state.enemy_fleet.enemies.each do |enemy|
      enemy.collisions.clear
    end
    state.player.collisions.clear

    state.player.missiles.each do |missile|
      state.enemy_fleet.enemies.each do |enemy|
        if point_in_rect(missile.pos, enemy.hit_box)
          # HIT!
          enemy.collisions << missile
          missile.collisions << enemy
          state.player.score += 80
        end
      end
    end

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

  def draw(state, output, res)
    output.graphics << Draw::Scale.new(Scale) do |g|
      draw_stars g, state.stars

      case state.screen
      when :home_bonuses
        draw_start_info g
        draw_bonuses g
      when :battle
        draw_player g, state.player

        draw_enemy_fleet g, state.enemy_fleet
      end

      draw_hud g, state
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

  def draw_hud(g, state)
    player = state.player
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
end
