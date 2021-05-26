module Galaga
  def new_hud
    {
      player_blink_state: true,
      player_name: "",
      player_score: 0,
      player_reserve_ships: 0,
      stage: 0,
      high_score: 0,
      credits: 0,
      show_credits: true,
    }
  end

  def update_hud(state, input)
    hud = state.hud
    hud.player_name = "#{state.player.num}UP"
    hud.player_score = state.player.score
    hud.high_score = state.high_score
    hud.credits = state.credits
    hud.player_reserve_ships = state.player.total_ships - state.player.active_ships
    hud.stage = state.stage
    if state.screen == :battle
      hud.player_blink_state = (2 * input.time.t).floor.even?
    else
      hud.player_blink_state = true
    end
  end

  Red = Gosu::Color::RED
  White = Gosu::Color::WHITE

  def draw_hud_scores(g, hud)
    # Player Score
    draw_text(g, "#{hud.player_name}", 2, 0, Red) if hud.player_blink_state
    draw_text(g, hud.player_score.to_s.ljust(10, " "), 2, 1, White)

    # High Score
    draw_text(g, "HIGH SCORE", 10, 0, Red)
    draw_text(g, "#{hud.high_score}", 12, 1, White)
  end

  def draw_hud_credits(g, hud)
    draw_text(g, "CREDITS #{hud.credits}", 1, 28, White)
  end

  def draw_hud_ships(g, hud)
    hud.player_reserve_ships.times do |i|
      x = i * 15
      y = Height - FighterHeight
      g << Draw::Sprite.new(name: "fighter", x: x, y: y, z: Layer.player)
    end
  end

  def draw_hud_stages(g, hud)
  end

  def draw_text(g, text, charx, chary, color)
    x = charx * FontWidth
    y = chary * FontHeight
    z = Layer.text
    g << Draw::Label.new(text: text, x: x, y: y, z: z, color: color, font: "retrogame")
  end
end
