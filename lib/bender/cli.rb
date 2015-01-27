require 'yaml'
require 'thor'
require 'active_support/core_ext/hash'
require 'bender/client'

module Bender
  class CLI < Thor
    class_option :config, :aliases => ["-c"], :type => :string, :required => true

    def initialize(args = [], opts = {}, config = {})
      super(args, opts, config)

      if !File.exists?(options[:config])
        puts "Cannot find #{options[:config]}."
        exit
      end

      config_options = YAML.load_file(options[:config]).deep_symbolize_keys
      @options = @options.symbolize_keys.merge(config_options)
    end

    desc "start", "Start processing watchers."
    option :hostname,      :aliases => ["-h"], :type => :string
    option :require,       :aliases => ["-r"], :type => :string
    option :pid_file,      :aliases => ["-p"], :type => :string
    option :interval,      :aliases => ["-i"], :type => :numeric
    option :daemon,        :aliases => ["-d"], :type => :boolean
    option :timeout,       :aliases => ["-t"], :type => :numeric
    option :graceful_term, :aliases => ["-g"], :type => :boolean

    def start
      load_enviroment(options[:require])
      opts = @options.symbolize_keys.slice(:timeout, :interval, :daemon, :pid_file)
      Bender::Client.new(options[:hostname] || Socket.gethostname, @options).start_watchers
    end

    desc "publish", "Publish a message."
    option :hostname, :aliases => ["-h"], :type => :string
    option :watcher,  :aliases => ["-w"], :type => :string, :required => true
    option :message,  :aliases => ["-m"], :type => :string, :required => true
    option :ack,      :aliases => ["-a"], :type => :boolean, :required => false, :default => false

    def publish
      load_enviroment(options[:require])
      opts = @options.symbolize_keys.slice(:timeout, :interval, :daemon, :pid_file)
      Bender::Client.new(options[:hostname] || Socket.gethostname, @options).publish(
        options[:watcher],
        options[:message],
        options[:ack]
      )
    end

    protected
      # Loads the environment from the given configuration file.
      # @api private
      def load_enviroment(file = nil)
        file ||= "."

        if File.directory?(file) && File.exists?(File.expand_path("#{file}/config/environment.rb"))
          require 'rails'
          require File.expand_path("#{file}/config/environment.rb")
          if defined?(::Rails) && ::Rails.respond_to?(:application)
            # Rails 3
            ::Rails.application.eager_load!
          elsif defined?(::Rails::Initializer)
            # Rails 2.3
            $rails_rake_task = false
            ::Rails::Initializer.run :load_application_classes
          end
        elsif File.file?(file)
          require File.expand_path(file)
        end
      end

  end
end
