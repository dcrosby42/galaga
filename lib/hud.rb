module Galaga
  def new_hud
    {
      player_blink_state: true,
      player_name: "",
      player_score: 0,
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
    if state.screen == :battle
      hud.player_blink_state = (2 * input.time.t).floor.even?
    else
      hud.player_blink_state = true
    end
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
end
