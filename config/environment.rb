$PROJECT_ROOT = File.expand_path(__FILE__ + "/../..")
$LOAD_PATH << $PROJECT_ROOT + "/lib"

require "ostruct"
require "pry"

require "cedar"
require "cedar/ecs"

AutoReload.verbose = true
AutoReload.path_prefix = $PROJECT_ROOT
