require 'spec_helper'

describe "Bender" do

  it "reads a config file" do
    create_options = {:create_options => {
      :visibility_timeout => 90,
      :maximum_message_size => 262144
    }}

    poll_options = {:poll_options => {
      :wait_time_seconds => 10,
      :idle_timeout => 5
    }}

    config = {
      :watchers => [{
        :perform => :watcher_life_cycle_hook,
        :queue => {
          :name => "watcher_life_cycle_hook",
        }.merge(create_options).merge(poll_options)
      },
      {
        :perform => :god_unmonitor,
        :queue => {
          :name => "god_unmonitor",
        }.merge(create_options).merge(poll_options)
      }]
    }
    bender = Bender.new(config)

    expect(bender.config).to eq(config)
    expect(bender.watchers.count).to eq(config[:watchers].count)

    watchers = bender.watchers.collect(&:class)
    config[:watchers].each do |watcher|
      expect(watchers).to include(watcher[:perform].to_s.classify.constantize)
    end

    bender.start_watchers
  end

end
