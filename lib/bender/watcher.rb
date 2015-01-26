module WatcherFactory
  def self.create(config, default_config)
    watcher_class = config[:name]
    require "bender/watchers/#{watcher_class}"
    watcher_class.classify.constantize.new(default_config)
  end
end

class Watcher
  def self.sqs
    @@sqs ||= AWS::SQS.new({
      :access_key_id => ENV['AWS_ACCESS_KEY'],
      :secret_access_key => ENV['AWS_SECRET_ACCESS'],
      :region => ENV['AWS_REGION']
    })
  end

  def initialize(options)
    @options = options
    load_queue
  end

  def start
    subscribe
  end

  def load_queue
    @queue ||= Watcher.sqs.queues.create(
      "#{Bender::Client.queue_prefix}-#{@options[:name]}",
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

  def publish(message)
    message = message.to_json if message.is_a? Hash
    @queue.send_message(message)
  rescue Exception => ex
    Bender.logger.error("#{self.class}: #{ex.message}#{ex.backtrace.join("\n")}")
  end

  private

  def safe_perform(json)
    message = JSON.parse(json, :symbolize_names => true) rescue :invalid
    if message == :invalid
      Bender.logger.error("#{self.class}: Unable to parse message: #{json}")
    else
      self.perform(message)
    end
  rescue Exception => ex
    Bender.logger.error("#{self.class}: Perform : #{ex.message}#{ex.backtrace.join("\n")}")
  end

end
