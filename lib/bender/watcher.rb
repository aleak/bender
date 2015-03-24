module WatcherFactory
  def self.create(queue_name, config, default_config)
    watcher_class = config[:name].to_s
    require "bender/watchers/#{watcher_class}"
    watcher_class.classify.constantize.new(queue_name, default_config)
  end
end

class Watcher

  def name
    @name ||= safe_queue_name("#{@queue_name}-#{self.class.to_s.underscore}")
  end

  def initialize(queue_name, options)
    @queue_name = queue_name
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
    true
  rescue Exception => ex
    Bender.logger.error("#{self.class}: #{ex.message}#{ex.backtrace.join("\n")}")
    false
  end

  private

  def safe_queue_name(name)
    name[0..79]
  end

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
