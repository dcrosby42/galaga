require "./config/environment"

require "dev"

Cedar::Game.new(
  root_module: Dev,
  fullscreen: false,
  width: Dev::Width * Dev::Scale,
  height: Dev::Height * Dev::Scale,
).start!
