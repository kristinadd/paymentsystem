# Configure Sidekiq-Cron recurring jobs
# Only load when Sidekiq is running (not during asset precompilation or tests)
if defined?(Sidekiq::CLI) || Rails.env.production?
  unless Rails.env.test?
    Sidekiq::Cron::Job.create(
      name: "Delete old transactions",
      cron: "0 * * * *",  # Every hour at minute 0
      class: "TransactionCleanupJob"
    )
  end
end
