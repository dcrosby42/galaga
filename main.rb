require "./config/environment"

require "galaga"

Cedar::Game.new(
  root_module: Galaga,
  fullscreen: false,
).start!
