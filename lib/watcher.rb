module WatcherFactory
  def self.create(config)
    watcher_class = config[:perform].to_s
    require_relative "watchers/#{watcher_class}"
    watcher_class.classify.constantize.new(config[:queue])
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
      @options[:name],
      @options[:create_options]
    )
  rescue Exception => e
    Roy.logger.info(e.message)
  end

  def subscribe
    Roy.logger.info("Polling #{@queue.arn} for #{self.class.to_s}")
    while Roy.keep_running? do
      @queue.poll(@options[:poll_options]) do |received_message|
        message = JSON.parse(received_message.body)
        self.perform(message)
      end
    end
  rescue Exception => e
    Roy.logger.info(e.message)
  end

  def publish(message)
    @queue.send_message(message.to_json)
  rescue Exception => e
    Roy.logger.info(e.message)
  end

end
