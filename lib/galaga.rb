module Galaga
  extend self
  include Cedar
  extend Cedar::Helpers

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
  FooterHeight = 16

  StarSpeed = 60
  FighterSpeed = 120
  FighterCruiseAccel = 120
  FighterHeight = 16
  MissileSpeed = 350
  MissileFireLimit = 2

  FontWidth = 8.5 # "retrogame" fixed with font char width
  FontHeight = 10 # "retrogame" fixed with font char height

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
require "hud"
require "collisions"

module Galaga
  Cedar::Sound.on = false

  def resource_config
    [
      {
        type: "image_sprite",
        name: "fighter",
        image: "fighter_01.png",
      },
      {
        type: "image_sprite",
        name: "missile",
        image: "missile_01.png",
        center_x: 0.5,
        center_y: 0,
      },
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
      credits: 0,
      stage: 0,
      high_score: 20000,

      seed_rng: seed_rng,
      stars: new_stars(star_seed: seed_rng.gen_seed),
      player: new_player,
      enemy_fleet: new_enemy_fleet,
      hud: new_hud,

      paused: false,
    })
    state
  end

  def update(state, input, res)
    update_dev_controls state, input

    return state if state.paused

    case state.screen
    when :instruction
    when :demo
    when :high_scores
    when :start
      update_stars(state.stars, StarSpeed, input)
    when :fanfare
    when :stage_open
    when :battle
      update_collisions state
      update_player state.player, input
      update_enemy_fleet state.enemy_fleet, input
      update_stars(state.stars, state.player.cruising.speed, input)
    when :death
    when :game_over
    when :new_high_score
    end

    update_hud(state, input)

    state
  end

  def update_dev_controls(state, input)
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
  end

  def draw(state, output, res)
    output.graphics << Draw::Scale.new(Scale) do |g|
      draw_stars g, state.stars

      case state.screen
      when :instruction
      when :demo
      when :high_scores
      when :start
        draw_start_info g
        draw_bonuses g
        draw_hud_scores g, state.hud
        draw_hud_credits g, state.hud
      when :fanfare
      when :stage_open
      when :battle
        draw_player g, state.player
        draw_enemy_fleet g, state.enemy_fleet
        draw_hud_scores g, state.hud
        draw_hud_ships g, state.hud
        draw_hud_stages g, state.hud
      when :death
      when :game_over
      when :new_high_score
      end
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

  def draw_bonuses(g)
    g << Draw::Label.new(text: "1ST BONUS FOR 20000 PTS", x: 25, y: 130, z: Layer.text, color: Gosu::Color::YELLOW, font: "retrogame")
    g << Draw::Label.new(text: "2ND BONUS FOR 70000 PTS", x: 25, y: 150, z: Layer.text, color: Gosu::Color::YELLOW, font: "retrogame")
    g << Draw::Label.new(text: "AND FOR EVERY 70000 PTS", x: 25, y: 170, z: Layer.text, color: Gosu::Color::YELLOW, font: "retrogame")

    g << Draw::Sprite.new(name: "fighter", x: 5, y: 125, z: Layer.text)
    g << Draw::Sprite.new(name: "fighter", x: 5, y: 145, z: Layer.text)
    g << Draw::Sprite.new(name: "fighter", x: 5, y: 165, z: Layer.text)

    g << Draw::Label.new(text: "\u00A9 1981 NAMCO LTD.", x: 40, y: 210, z: Layer.text, color: Gosu::Color::WHITE, font: "retrogame")
  end
end
