require "rake/testtask"
require "rspec/core/rake_task"

task default: "run"

desc "Run the game"
task :run do
  exec "bundle exec ruby main.rb"
end

desc "Console prompt"
task :console do
  exec "bundle exec ruby console.rb"
end

RSpec::Core::RakeTask.new(:spec)
task test: :spec
