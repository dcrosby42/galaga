module Dev
  extend self
  include Cedar
  extend Cedar::Helpers

  # Game dimensions
  Scale = 3
  Width = 224
  Height = 288

  Cedar::Sound.on = false
  Cedar::Sound.debug = false

  def resource_config
    # [
    #   "ui.json",
    #   "player.json",
    #   "enemies/enemies.json",
    # ]
    [
      {
        type: "grid_sheet_sprite",
        name: "fly_ship",
        image: "enemies/enemy_ships.png",
        tile_grid: {
          x: 32,
          y: 96,
          w: 32,
          h: 32,
          count: 24,
        },
      },
      #  {
      #   type: "sprite_animation",
      #   name: "fly_ship_anim",
      #   sprite: "fly_ship",
      # },
      {
        "type": "font",
        "name": "retrogame",
        "font": "narpassword.ttf",
        "size": 10,
      },
      {
        "type": "font",
        "name": "default",
        "size": 10,
      },
      {
        "type": "font",
        "name": "default",
        "size": 20,
      },
    ]
  end

  def new_state
    open_struct({ 
      scale: Scale,
      frame: 1,
    })
  end

  def update(state, input, res)
    # Change zoom?
    if input.keyboard.pressed?(Gosu::KB_EQUALS)
      state.scale += 1
      state.scale = 8 if state.scale > 8
    elsif input.keyboard.pressed?(Gosu::KB_MINUS)
      state.scale -= 1
      state.scale = 1 if state.scale < 1
    elsif input.keyboard.pressed?(Gosu::KB_0)
      state.scale = 1
    end

    # Change frame?
    if input.keyboard.pressed?(Gosu::KB_LEFT)
      state.frame -= 1
      state.frame = 0 if state.frame < 0
    elsif input.keyboard.pressed?(Gosu::KB_RIGHT)
      state.frame += 1
      # state.frame = 0 if state.frame < 0
    # elsif input.keyboard.pressed?(Gosu::KB_0)
    #   state.scale = 1
    end

    state
  end

  def draw(state, output, res)
    output.graphics << Draw::Scale.new(state.scale) do |g|
      g << Draw::RectOutline.new(x: x, y: y, w: 32, h: 32, z: 0, color: White)
      frame = state.frame
      g << Draw::Sprite.new(name: "fly_ship", frame: frame, x: 0, y: 0, z: 1)
    end
    x = 0
    y = 0
    output.graphics << Draw::Label.new(text: "Fr: #{state.frame}", x: x, y: y, z: Layer.text, color: White, font: "default")
  end

  Blue = Gosu::Color::BLUE
  Green = Gosu::Color::GREEN
  White = Gosu::Color::WHITE
  Cyan = Gosu::Color::CYAN

  FontWidth = 8.5 # "retrogame" fixed with font char width
  FontHeight = 10 # "retrogame" fixed with font char height

  Layer = open_struct(
    stars: 0,
    enemy: 100,
    enemy_debug: 101,
    text: 150,
  )

  def text(txt, charx, chary, color)
    x = charx * FontWidth
    y = chary * FontHeight
    z = Layer.text
    Draw::Label.new(text: txt, x: x, y: y, z: z, color: color, font: "retrogame")
  end
end
