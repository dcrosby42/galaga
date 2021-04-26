require "./config/environment"

require "galaga"

Cedar::Game.new(
  root_module: Galaga,
  fullscreen: false,
  width: Galaga::Width * Galaga::Scale,
  height: Galaga::Height * Galaga::Scale,
).start!
