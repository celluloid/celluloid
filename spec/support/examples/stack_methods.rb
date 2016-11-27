def create_async_blocking_actor(task_klass)
  actor_klass = Class.new(StackBlocker) do
    task_class task_klass
  end

  actor = actor_system.within do
    actor_klass.new(threads)
  end

  actor.async.blocking
end

def create_thread_with_role(threads, role)
  resume = Queue.new
  thread = actor_system.get_thread do
    resume.pop # to avoid race for 'thread' variable
    thread.role = role
    threads << thread
    StackWaiter.forever
  end
  resume << nil # to avoid race for 'thread' variable
  thread
end
