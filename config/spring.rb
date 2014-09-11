Spring.after_fork do
  context = Rails.application.domain_context
  context.event_store.dispatcher.restart if context
end