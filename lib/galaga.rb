module Galaga
  include Cedar
  extend Cedar::Helpers
end

module Galaga
  extend self

  Scale = 2
  Width = 224
  Height = 288

  def resource_config
    [
      {
        type: "font",
        name: "default",
        font: "narpassword.ttf",
        size: 10,
      },
    ]
  end

  def new_state
    state = open_struct()
    state
  end

  def update(state, input, res)
    state
  end

  def draw(state, output, res)
    output.graphics << Draw::Scale.new(Scale) do |g|
      draw_start_info g
      draw_bonuses g
      draw_hud g
      draw_stars g, 0, 20, Width, Height - 12
    end
  end

  def draw_stars(g, minx, miny, maxx, maxy)
    r = Cedar::Prng.new(1234568)
    (miny..maxy).each do |y|
      x = r.int(0, maxx)
      color = r.choose(Colors)
      g << star(x, y, color)
    end
  end

  def star(x, y, color)
    Draw::Rect.new(x: x, y: y, w: 1, h: 1, color: color)
  end

  def draw_start_info(g)
    g << Draw::Label.new(text: "PUSH START BUTTON", x: 40, y: 100, color: Gosu::Color.new(0, 228, 202))
  end

  Colors = [
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

  def draw_hud(g)
    g << Draw::Label.new(text: "  1UP     HIGH SCORE", x: 0, y: 0, color: Gosu::Color::RED)
    g << Draw::Label.new(text: "  4010      20000   ", x: 0, y: 10, color: Gosu::Color::WHITE)

    g << Draw::Label.new(text: " CREDITS 1", x: 0, y: 280, color: Gosu::Color::WHITE)
  end

  def draw_bonuses(g)
    g << Draw::Label.new(text: "1ST BONUS FOR 20000 PTS", x: 25, y: 130, color: Gosu::Color::YELLOW)
    g << Draw::Label.new(text: "2ND BONUS FOR 70000 PTS", x: 25, y: 150, color: Gosu::Color::YELLOW)
    g << Draw::Label.new(text: "AND FOR EVERY 70000 PTS", x: 25, y: 170, color: Gosu::Color::YELLOW)

    g << Draw::Label.new(text: "\u00A9 1981 NAMCO LTD.", x: 40, y: 210, color: Gosu::Color::WHITE)

    g << Draw::Image.new(path: "fighter_01.png", x: 5, y: 125)
    g << Draw::Image.new(path: "fighter_01.png", x: 5, y: 145)
    g << Draw::Image.new(path: "fighter_01.png", x: 5, y: 165)
  end
end
