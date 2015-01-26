class GodUnmonitor < Watcher

  # Expects a message in the following format
  #   :task_or_group_name => 'resque'
  def perform(message)
    task_or_group_name = message[:task_or_group_name]

    if task_or_group_name.nil?
      Roy.logger.warn("GodUnmonitor: task_or_group_name not defined.")
      return
    end

    Roy.logger.info("GodUnmonitor: #{task_or_group_name}")

    # TODO: sanitize input
    result = %x{sudo god unmonitor #{task_or_group_name}}

    Roy.logger.info("GodUnmonitor: #{result}")
  end

end
