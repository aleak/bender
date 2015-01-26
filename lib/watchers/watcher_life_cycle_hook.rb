class WatcherLifeCycleHook < Watcher

  def perform(message)
    Roy.logger.info("Got message #{message}")
  end

end
