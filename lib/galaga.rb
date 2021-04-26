module Galaga
  include Cedar
  extend Cedar::Helpers
end

module Galaga
  extend self

  def new_state
    state = open_struct()
    state
  end

  def update(state, input, res)
    state
  end

  def draw(state, output, res)
    output.graphics << Draw::Label.new(text: "  1UP       HIGH SCORE", x: 0, y: 0, color: Gosu::Color::RED)
    output.graphics << Draw::Label.new(text: " 17330         20000  ", x: 0, y: 20, color: Gosu::Color::WHITE)

    output.graphics << Draw::Label.new(text: "FINISH HIM!", x: 50, y: 100, color: Gosu::Color::RED)
  end
end
