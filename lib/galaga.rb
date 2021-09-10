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
  DebugPhaseToggle = Gosu::KB_F4
  PauseToggle = Gosu::KB_P
  SoundToggle = Gosu::KB_M

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
  EnemyMissileSpeed = 200
  EnemyFireLimit = 3

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
  Cedar::Sound.debug = false
  SkipFanfare = true
  PlayerGodMode = true

  def resource_config
    [
      "ui.json",
      "player.json",
      "enemies/enemies.json",
    ]
  end

  def new_state
    seed_rng = Cedar::Prng.new(1122334455)
    state = open_struct({
      phase: nil,
      screen: nil,
      screen_countdown: nil,
      credits: 0,
      stage: 0,
      high_score: 20000,

      seed_rng: seed_rng,
      stars: new_stars(star_seed: seed_rng.gen_seed),
      hud: new_hud,
      player: new_player,
      enemy_fleet: nil,

      scale: Scale,
      paused: false,
      debug_phase: false,
    })
    state
  end

  def update(state, input, res)
    update_dev_controls state, input

    state.phase ||= :title

    return state if state.paused

    case state.phase
    when :title
      # The 'title' phase encapsulates the intro, titles, scores and start screens.

      state.screen ||= :instructions

      # Always jump to start screen when there are credits
      if state.credits > 0
        state.screen = :start
      end

      # insert coin:
      if input.keyboard.pressed?(Gosu::KB_5)
        state.credits += 1
        state.credits_sound = { t: 0.6 }
      end

      # Star bg scrolls for all title screens
      update_stars(state.stars, StarSpeed, input)

      case state.screen
      when :instructions
        # Stand-in: count down til next screen...
        state.screen_countdown ||= 2
        state.screen_countdown -= input.time.dt
        if state.screen_countdown < 0
          state.screen_countdown = nil
          state.screen = :demo
        end
      when :demo
        # Stand-in: count down til next screen...
        state.screen_countdown ||= 5
        state.screen_countdown -= input.time.dt
        if state.screen_countdown < 0
          state.screen_countdown = nil
          state.screen = :high_scores
        end
      when :high_scores
        # Stand-in: count down til next screen...
        state.screen_countdown ||= 2
        state.screen_countdown -= input.time.dt
        if state.screen_countdown < 0
          state.screen_countdown = nil
          state.screen = :instructions
        end
      when :start
        # Wait for P1 start button:
        if input.keyboard.pressed?(Gosu::KB_1)
          state.credits -= 1
          state.player = new_player
          state.stage = 1
          state.enemy_fleet = new_enemy_fleet
          state.phase = :gameplay
          if SkipFanfare
            state.screen = :battle
          else
            state.screen = :fanfare
          end
        end
      end
    when :gameplay
      # The gameplay phase encapsulates battle, stage transitions,
      case state.screen
      when :fanfare
        # init fanfare state on first pass
        state.fanfare ||= open_struct(
          theme_song: true,
          t: 0,
          line1: nil,
          line2: nil,
          fighter_visible: false,
        )

        # title progression during theme song
        ff = state.fanfare
        case ff.t
        when 0..4
          ff.line1 = "PLAYER #{state.player.num}"
          ff.line2 = nil
          update_stars(state.stars, 0, input)
        when 4..6.5
          ff.line1 = "PLAYER #{state.player.num}"
          ff.line2 = "STAGE #{state.stage}"
          ff.fighter_visible = true
          update_player(state.player, input)
          update_stars(state.stars, state.player.cruising.speed, input)
          state.player.weapons_hot = false
        when 6.5..7
          state.fanfare = nil
          state.screen = :battle
        end
        ff.t += input.time.dt
      when :stage_open
        update_stars(state.stars, state.player.cruising.speed, input)
        update_player state.player, input
        stage_opening = state.stage_opening
        case stage_opening.t
        when 0..(1.5)
          stage_opening.line1 = ""
        when (1.5)..(3.5)
          state.stage = stage_opening.next_stage
          stage_opening.line1 = "STAGE #{state.stage}"
        else
          stage_opening.line1 = ""
          state.stage_opening = nil
          state.enemy_fleet = new_enemy_fleet
          state.screen = :battle
        end
        stage_opening.t += input.time.dt
      when :battle
        state.player.weapons_hot = true
        update_collisions state
        update_player state.player, input
        update_enemy_fleet state.enemy_fleet, input
        update_stars(state.stars, state.player.cruising.speed, input)
        if state.player.mode == :explode
          state.screen = :death
        elsif state.enemy_fleet.defeated
          puts "Fleet defeated"
          state.stage_opening ||= open_struct(
            t: 0,
            # line1: "STAGE #{state.stage}",
            next_stage: state.stage + 1,
          )
          state.screen = :stage_open
        end
      when :death
        update_player state.player, input
        update_enemy_fleet state.enemy_fleet, input
        update_stars(state.stars, state.player.cruising.speed, input)

        state.death_stranding ||= 0
        case state.death_stranding
        when 0..3
        when 3..4
          state.death_stranding = nil
          if state.player.total_ships > 0
            state.screen = :battle
            revive_player state.player
          else
            state.phase = :epilogue
            state.screen = nil
          end
        end
        state.death_stranding += input.time.dt if state.death_stranding
      end
    when :epilogue
      state.screen ||= :game_over
      # The epilogue phase is post-gameplay: gameover, stats, maybe entering a new high score.
      case state.screen
      when :game_over
        state.game_over_timer ||= 0
        case state.game_over_timer
        when 0..5
        when 5..6
          state.game_over_timer = nil
          state.phase = nil
          state.screen = nil
          # state.death_stranding = nil
          # if state.player.total_ships > 0
          #   state.screen = :battle
          #   revive_player state.player
          # else
          #   state.phase = :epilogue
          #   state.screen = nil
          # end
        end
        state.game_over_timer += input.time.dt if state.game_over_timer
      when :new_high_score
      end
    end

    update_hud(state, input)

    if state.credits_sound
      state.credits_sound[:t] -= input.time.dt
      state.credits_sound = nil if state.credits_sound[:t] <= 0
    end

    state
  end

  def update_dev_controls(state, input)
    if input.keyboard.pressed?(SoundToggle)
      Cedar::Sound.on = !Cedar::Sound.on
      puts "Cedar::Sound.on = #{Cedar::Sound.on}"
    end
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
    if input.keyboard.pressed?(DebugPhaseToggle)
      state.debug_phase = !state.debug_phase
    end

    if input.keyboard.pressed?(Gosu::KB_EQUALS)
      state.scale += 1
    end
    if input.keyboard.pressed?(Gosu::KB_MINUS)
      state.scale -= 1
      state.scale = 1 if state.scale < 1
    end
  end

  def draw(state, output, res)
    output.graphics << Draw::Scale.new(state.scale) do |g|
      draw_stars g, state.stars

      if state.debug_phase
        g << text(state.phase, 16, 27, Blue)
        g << text(state.screen, 16, 28, Green)
      end

      case state.phase
      when :title
        placeholder = lambda do |words|
          g << text(words, 0, 4, Blue)
          g << text("#{(state.screen_countdown || 0).round(1)}", 24, 4, White)
        end
        case state.screen
        when :instructions
          draw_hud_scores g, state.hud
          draw_hud_credits g, state.hud
          placeholder["Instructions"]
        when :demo
          draw_hud_scores g, state.hud
          draw_hud_credits g, state.hud
          placeholder["Demo"]
        when :high_scores
          draw_hud_scores g, state.hud
          draw_hud_credits g, state.hud
          placeholder["High Scores"]
        when :start
          draw_start_info g
          draw_bonuses g
          draw_hud_scores g, state.hud
          draw_hud_credits g, state.hud
        end
        if state.credits_sound
          g << Sound::Effect.new(name: "credit_added", id: state.credits)
        end
      when :gameplay
        case state.screen
        when :fanfare
          ff = state.fanfare
          if ff
            g << Sound::Effect.new(name: "theme_song") if ff.theme_song
            g << text(ff.line1, 8.2, 11, Cyan) if ff.line1
            g << text(ff.line2, 8, 12.5, Cyan) if ff.line2
            if ff.fighter_visible
              draw_player g, state.player
              draw_hud_ships g, state.hud
            else
              draw_hud_credits g, state.hud
            end
          else
            draw_hud_credits g, state.hud
          end
          draw_hud_scores g, state.hud
        when :stage_open
          draw_player g, state.player
          draw_enemy_fleet g, state.enemy_fleet
          draw_hud_scores g, state.hud
          draw_hud_ships g, state.hud
          draw_hud_stages g, state.hud

          so = state.stage_opening
          g << text(so.line1, 8.2, 11, Cyan) if so.line1
        when :battle, :death
          draw_player g, state.player
          draw_enemy_fleet g, state.enemy_fleet
          draw_hud_scores g, state.hud
          draw_hud_ships g, state.hud
          draw_hud_stages g, state.hud
        end
      when :epilogue
        case state.screen
        when :game_over
          draw_hud_scores g, state.hud
          draw_hud_credits g, state.hud
          g << text("GAME OVER", 8.2, 11, Red)
        when :new_high_score
        end
      end
    end
  end

  Red = Gosu::Color::RED
  Blue = Gosu::Color::BLUE
  Green = Gosu::Color::GREEN
  White = Gosu::Color::WHITE
  Cyan = Gosu::Color::CYAN

  def text(txt, charx, chary, color)
    x = charx * FontWidth
    y = chary * FontHeight
    z = Layer.text
    Draw::Label.new(text: txt, x: x, y: y, z: z, color: color, font: "retrogame")
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
