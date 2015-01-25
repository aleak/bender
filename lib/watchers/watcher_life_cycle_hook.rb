class WatcherLifeCycleHook < Watcher

  def perform(message)
    puts "Got message #{message}"
  end

end
