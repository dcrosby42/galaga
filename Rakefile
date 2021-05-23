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

desc "Render diagrams"
task :diagrams do
  type = ENV["TYPE"] || "svg"
  Dir["*.dot"].each do |fname|
    %x{cat #{fname} | docker run --rm -i nshine/dot dot -T#{type} > #{File.basename(fname,".dot")}.#{type}}
  end
end

RSpec::Core::RakeTask.new(:spec)
task test: :spec
