require 'open3'

class GodUnmonitor < Watcher

  # Expects a message in the following format
  #   :task_or_group_name => 'resque'
  def perform(message)
    task_or_group_name = message[:task_or_group_name]

    if task_or_group_name.nil?
      Roy.logger.warn("GodUnmonitor: task_or_group_name not defined - #{message}")
      return
    end

    Roy.logger.info("GodUnmonitor: #{task_or_group_name}")

    # TODO: sanitize input

    Open3.popen3("sudo god unmonitor #{task_or_group_name}") do |stdin, stdout, stderr, wait_thr|
      info = stdout.read
      error = stderr.read
      Roy.logger.info("GodUnmonitor: #{info.rstrip}") unless info.empty?
      Roy.logger.error("GodUnmonitor: #{error.rstrip}") unless error.empty?
    end

  end

end
