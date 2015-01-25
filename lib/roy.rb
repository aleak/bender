lib_dir = File.dirname(__FILE__)

require 'aws-sdk-v1'
require 'thwait'
require 'dotenv'
require 'active_support/inflector'
require File.join(lib_dir, 'watcher')

Dotenv.load

class Roy

  def self.keep_running?
    @@keep_running
  end

  def initialize(config)
    @@keep_running = true
    @config = config
    initialize_watchers
    trap_signals
    start_watchers
  end

  def trap_signals
    %w{INT TERM}.each do |signal|
      Signal.trap(signal) {
        stop_watchers
        exit
      }
    end
  end

  def start_watchers
    puts "Press Ctrl+C to stop watchers"
    puts "Starting Watchers..."
    @threads = []
    @watchers.each do |watcher|
      @threads << Thread.new do
        watcher.start
      end
    end
    ThreadsWait.all_waits(*@threads)
  end

  def stop_watchers
    puts "Stopping watchers..."
    @@keep_running = false
    ThreadsWait.all_waits(*@threads)
  end

  def config
    @config
  end

  def watchers
    @watchers
  end

  private

  def initialize_watchers
    @watchers = @config[:watchers].collect do |watcher_config|
      puts "Loading #{watcher_config[:perform]}"
      WatcherFactory.create(watcher_config)
    end
  end

end
