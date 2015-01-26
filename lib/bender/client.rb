require 'aws-sdk-v1'
require 'thwait'
require 'dotenv'
require 'active_support/inflector'
require 'bender/watcher'

Dotenv.load

module Bender

  def self.logger
    @@logger ||= Logger.new(STDOUT)
  end

  class Client

    class << self
      def keep_running?
        @@keep_running
      end

      def queue_prefix
        @@queue_prefix ||= "#{ENV['QUEUE_PREFIX']}-#{Socket.gethostname}"
      end
    end

    def initialize(config)
      @config = config
      initialize_watchers
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
      Bender.logger.info("Starting Watchers - Press Ctrl+C to stop watchers...")
      @@keep_running = true
      @threads = []
      @watchers.each do |watcher|
        @threads << Thread.new do
          watcher.start
        end
      end
      trap_signals
      ThreadsWait.all_waits(*@threads)
    end

    def stop_watchers
      puts "Stopping watchers..."
      @@keep_running = false
      ThreadsWait.all_waits(*@threads)
    end

    def publish(watcher, message)
      sent = @watchers.select{|w| w.class.to_s.underscore == watcher}.collect do |watcher|
        watcher.publish(message)
      end
      Bender.logger.info("Sent #{sent.size} message(s)")
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
        Bender.logger.info("Loading #{watcher_config[:name]}")
        WatcherFactory.create(watcher_config, self.config)
      end
    end

  end
end
