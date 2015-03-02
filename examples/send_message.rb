$:.unshift(File.join(File.dirname(File.dirname(__FILE__)), 'lib'))

require 'bender'

hostname = Socket.gethostname
message = {:hello => :you}

config = { :queue_prefix => 'my-custom-prefix-is-really-really-really-huge', :watchers => [{:name => :watcher_life_cycle_hook}] }

bender = Bender::Client.new(hostname, config)
bender.publish(:watcher_life_cycle_hook, message, true)
