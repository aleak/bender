require 'aws-sdk-v1'
require 'thwait'
require 'dotenv'
require 'active_support/inflector'
require 'bender/watcher'
require 'securerandom'

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

      def sqs
        @@sqs ||= AWS::SQS.new({
          :access_key_id => ENV['AWS_ACCESS_KEY'],
          :secret_access_key => ENV['AWS_SECRET_ACCESS'],
          :region => ENV['AWS_REGION']
        })
      end
    end

    def initialize(hostname, config = {})
      @config = config
      @queue_name = "#{self.queue_prefix}-#{hostname}"

      @config[:create_options] ||= {
        :visibility_timeout => 90,
        :maximum_message_size => 262144
      }

      @config[:poll_options] ||= {
        :wait_time_seconds => 10,
        :idle_timeout => 5
      }
      initialize_watchers if @config[:watchers]
    end

    def queue_prefix
      @queue_prefix ||= self.config[:queue_prefix] || "#{ENV['QUEUE_PREFIX']}"
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

    def publish(watcher, message, ack = false)
      @watchers.select{|w| w.class.to_s.underscore == watcher.to_s}.collect do |watcher|
        if ack
          with_confirmation do |cq|
            watcher.publish(message, cq)
          end
        else
          watcher.publish(message)
        end
        Bender.logger.info("Sent message to #{watcher.name}")
      end
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
        WatcherFactory.create(@queue_name, watcher_config, self.config)
      end
    end

    def with_confirmation
      name = "#{@queue_name}-ack-#{SecureRandom.uuid}"
      cq = Bender::Client.sqs.queues.create(name, self.config[:create_options])

      # send message
      yield({:ack_queue_name => name})

      Bender.logger.info("Polling #{cq.arn} for ack")

      idle_timeout = 15.seconds
      timeout = true
      cq.poll(:wait_time_seconds => 2, :idle_timeout => idle_timeout) do |received_message|
        # ack'd
        timeout = false
        break
      end

      Bender.logger.warn("Ack not received on #{cq.arn} after #{idle_timeout} seconds.") if timeout
    rescue Exception => ex
      Bender.logger.error("#{ex.message}#{ex.backtrace.join("\n")}")
    ensure
      cq.delete if cq
    end

  end
end
