module WatcherFactory
  def self.create(config, default_config)
    watcher_class = config[:name]
    require "bender/watchers/#{watcher_class}"
    watcher_class.classify.constantize.new(default_config)
  end
end

class Watcher

  def name
    @name ||= "#{Bender::Client.queue_prefix}-#{self.class.to_s.underscore}"
  end

  def initialize(options)
    @options = options
    load_queue
  end

  def start
    subscribe
  end

  def load_queue
    @queue ||= Bender::Client.sqs.queues.create(
      self.name,
      @options[:create_options]
    )
  rescue Exception => ex
    Bender.logger.error("#{self.class}: #{ex.message}#{ex.backtrace.join("\n")}")
  end

  def subscribe
    while Bender::Client.keep_running? do
      Bender.logger.info("Polling #{@queue.arn} for #{self.class.to_s}")
      @queue.poll(@options[:poll_options]) do |received_message|
        safe_perform(received_message.body)
      end
    end
  rescue Exception => ex
    Bender.logger.error("#{self.class}: #{ex.message}#{ex.backtrace.join("\n")}")
  end

  def publish(message, ack = nil)
    unless message.is_a?(Hash)
      message = JSON.parse(message)
    end

    message.merge!(ack) if ack

    @queue.send_message(message.to_json)
  rescue Exception => ex
    Bender.logger.error("#{self.class}: #{ex.message}#{ex.backtrace.join("\n")}")
  end

  private

  def safe_perform(json)
    message = JSON.parse(json, :symbolize_names => true) rescue :invalid
    if message == :invalid
      Bender.logger.error("#{self.class}: Unable to parse message: #{json}")
    else
      # requires an ack ?
      ack = message.delete(:ack_queue_name)
      self.perform(message)
      if ack
        Bender.logger.info("#{self.class}: Ack'ing on #{ack}")
        Bender::Client.sqs.queues.named(ack).send_message({:ack => true}.to_json)
      end
    end
  rescue Exception => ex
    Bender.logger.error("#{self.class}: Perform : #{ex.message}#{ex.backtrace.join("\n")}")
  end

end
