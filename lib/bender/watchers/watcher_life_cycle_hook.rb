class WatcherLifeCycleHook < Watcher

  def perform(message)
    Bender.logger.info("Got message #{message}")
  end

end
