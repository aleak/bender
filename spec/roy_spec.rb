require 'spec_helper'

describe "Roy" do

  it "reads a config file" do
    config = {
      :watchers => [{
        :perform => :watcher_life_cycle_hook,
        :queue => {
          :name => "#{ENV['QUEUE_PREFIX']}-test",
          :create_options => {
            :visibility_timeout => 90,
            :maximum_message_size => 262144
          },
          :poll_options => {
            :wait_time_seconds => 10,
            :idle_timeout => 5
          },
        }
      }]
    }
    roy = Roy.new(config)

    expect(roy.config).to eq(config)
    expect(roy.watchers.count).to eq(config[:watchers].count)

    watchers = roy.watchers.collect(&:class)
    config[:watchers].each do |watcher|
      expect(watchers).to include(watcher[:perform].to_s.classify.constantize)
    end

    roy.start_watchers
  end

end
